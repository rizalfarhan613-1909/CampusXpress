import {
  FieldValue,
  type DocumentData,
  type Firestore,
} from 'firebase-admin/firestore';
import { BIDDING_ORDER_STATUSES } from './bids';
import { GatewayError } from './errors';
import {
  COD_MAX,
  MAX_ACTIVE_JOBS,
  computeCommission,
  prettyRupiah,
  toInteger,
} from './money';

export interface AcceptBidInput {
  consumerId: string;
  orderId: string;
  bidId: string;
}

export interface AcceptBidResult {
  ok: true;
  orderId: string;
  bidId: string;
  driverId: string;
  finalPrice: number;
  commission: number;
  balanceAfter: number;
  rejectedBids: number;
  alreadyAccepted: boolean;
}

/**
 * Fase 5 — `acceptBid`: konsumen menerima satu penawaran dalam satu transaksi
 * atomik.
 *
 * - Kunci order: `status = 'ACCEPTED'`, `final_price = finalPrice`,
 *   `driver_id = bid.driverId`, `total_price = finalPrice`.
 * - Potong saldo deposit driver sebesar `max(50, round(finalPrice × 0.005))`
 *   dan catat ledger `commission_<orderId>` (idempoten).
 * - Tandai bid terpilih `ACCEPTED` dan seluruh bid lain `REJECTED`.
 */
export async function acceptBidEngine(
  db: Firestore,
  input: AcceptBidInput,
): Promise<AcceptBidResult> {
  if (!input.consumerId || !input.orderId || !input.bidId) {
    throw new GatewayError(
      'INVALID_ARGUMENT',
      'consumerId, orderId, dan bidId wajib diisi.',
    );
  }

  return db.runTransaction(async (txn) => {
    const orderRef = db.collection('orders').doc(input.orderId);
    const bidsRef = orderRef.collection('bids');
    const targetBidRef = bidsRef.doc(input.bidId);

    // ---- SEMUA PEMBACAAN SEBELUM PENULISAN ----
    const orderSnap = await txn.get(orderRef);
    if (!orderSnap.exists) {
      throw new GatewayError('ORDER_NOT_FOUND', 'Order tidak ditemukan.');
    }
    const order = orderSnap.data() as DocumentData;

    if (String(order.consumer_id ?? '') !== input.consumerId) {
      throw new GatewayError(
        'ORDER_NOT_OWNER',
        'Hanya konsumen pemesan yang dapat menerima penawaran.',
      );
    }
    if (!BIDDING_ORDER_STATUSES.has(String(order.status ?? ''))) {
      throw new GatewayError(
        'ORDER_NOT_BIDDING',
        `Order berstatus ${String(order.status)} dan tidak sedang mencari penawaran.`,
      );
    }

    const bidsSnap = await txn.get(bidsRef);
    const targetDoc = bidsSnap.docs.find((doc) => doc.id === input.bidId);
    if (!targetDoc) {
      throw new GatewayError('BID_NOT_FOUND', 'Penawaran tidak ditemukan.');
    }

    const bid = targetDoc.data() as DocumentData;
    if (String(bid.status) !== 'PENDING') {
      throw new GatewayError(
        'ORDER_NOT_BIDDING',
        `Penawaran berstatus ${String(bid.status)} dan tidak dapat diterima.`,
      );
    }

    const finalPrice = toInteger(bid.offeredPrice) ?? toInteger(bid.offered_price);
    if (finalPrice === null || finalPrice <= 0) {
      throw new GatewayError(
        'BID_TOO_LOW',
        'Nominal penawaran tidak valid.',
      );
    }

    // Batas COD ditegakkan di server pada harga yang benar-benar dikunci,
    // bukan pada nilai yang dikirim klien.
    const paymentMethod =
      typeof order.payment_method === 'string'
        ? order.payment_method
        : order.payment && typeof order.payment === 'object'
          ? String((order.payment as Record<string, unknown>).method ?? '')
          : '';
    if (paymentMethod === 'COD' && finalPrice > COD_MAX) {
      throw new GatewayError(
        'COD_LIMIT_EXCEEDED',
        `Transaksi COD maksimal ${prettyRupiah(COD_MAX)}; penawaran ini melebihi batas.`,
        { finalPrice, max: COD_MAX },
      );
    }

    const driverId = String(bid.driverId ?? bid.driver_id ?? '');
    if (!driverId) {
      throw new GatewayError('BID_NOT_FOUND', 'Penawaran tanpa driver.');
    }

    const commission = computeCommission(finalPrice);

    const driverRef = db.collection('users').doc(driverId);
    const driverProfileRef = db.collection('driverProfiles').doc(driverId);
    const walletRef = db.collection('wallets').doc(driverId);
    const ledgerRef = db
      .collection('wallet_ledger')
      .doc(`commission_${input.orderId}`);

    const [driverSnap, profileSnap, walletSnap, ledgerSnap] = await Promise.all([
      txn.get(driverRef),
      txn.get(driverProfileRef),
      txn.get(walletRef),
      txn.get(ledgerRef),
    ]);

    const driver = driverSnap.exists
      ? (driverSnap.data() as DocumentData)
      : undefined;
    const profile = profileSnap.exists
      ? (profileSnap.data() as DocumentData)
      : undefined;
    const wallet = walletSnap.exists
      ? (walletSnap.data() as DocumentData)
      : undefined;

    const currentBalance =
      toInteger(driver?.wallet_balance) ?? toInteger(wallet?.balance);
    if (currentBalance === null) {
      throw new GatewayError(
        'WALLET_NOT_FOUND',
        'Dompet deposit driver tidak ditemukan.',
      );
    }

    const alreadySettled = ledgerSnap.exists;
    if (!alreadySettled && currentBalance < commission) {
      throw new GatewayError(
        'INSUFFICIENT_BALANCE',
        `Saldo driver tidak cukup untuk komisi ${prettyRupiah(commission)}.`,
        { balance: currentBalance, commission },
      );
    }

    const balanceAfter = alreadySettled
      ? currentBalance
      : currentBalance - commission;

    const activeJobs =
      toInteger(driver?.active_jobs) ?? toInteger(profile?.active_jobs) ?? 0;
    if (activeJobs >= MAX_ACTIVE_JOBS) {
      throw new GatewayError(
        'TOO_MANY_JOBS',
        `Driver sudah menangani ${MAX_ACTIVE_JOBS} order aktif.`,
        { activeJobs, max: MAX_ACTIVE_JOBS },
      );
    }
    const nextActiveJobs = activeJobs + 1;

    // ---- PENULISAN ATOMIK ----
    if (driverSnap.exists && toInteger(driver?.wallet_balance) !== null) {
      txn.update(driverRef, {
        wallet_balance: balanceAfter,
        active_jobs: nextActiveJobs,
        updated_at: FieldValue.serverTimestamp(),
      });
    } else if (walletSnap.exists) {
      txn.update(walletRef, {
        balance: balanceAfter,
        updated_at: FieldValue.serverTimestamp(),
      });
      if (driverSnap.exists) {
        txn.update(driverRef, {
          active_jobs: nextActiveJobs,
          updated_at: FieldValue.serverTimestamp(),
        });
      } else if (profileSnap.exists) {
        txn.update(driverProfileRef, { active_jobs: nextActiveJobs });
      }
    } else if (driverSnap.exists) {
      txn.update(driverRef, {
        active_jobs: nextActiveJobs,
        updated_at: FieldValue.serverTimestamp(),
      });
    } else if (profileSnap.exists) {
      txn.update(driverProfileRef, { active_jobs: nextActiveJobs });
    }

    if (!alreadySettled) {
      txn.set(ledgerRef, {
        id: ledgerRef.id,
        driver_id: driverId,
        order_id: input.orderId,
        type: 'COMMISSION_DEDUCTION',
        amount: -commission,
        balance_after: balanceAfter,
        description: `Komisi 0,5% bid disetujui untuk order ${input.orderId}`,
        idempotency_key: `commission:${input.orderId}`,
        created_at: FieldValue.serverTimestamp(),
      });
    }

    const driverName = String(
      bid.driverName ?? bid.driver_name ?? driver?.name ?? 'Driver',
    );

    txn.update(orderRef, {
      status: 'ACCEPTED',
      driver_id: driverId,
      driver_name: driverName,
      final_price: finalPrice,
      total_price: finalPrice,
      commission_fee: commission,
      accepted_bid_id: input.bidId,
      accepted_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });

    txn.update(targetBidRef, {
      status: 'ACCEPTED',
      accepted_at: FieldValue.serverTimestamp(),
    });

    let rejectedBids = 0;
    for (const doc of bidsSnap.docs) {
      if (doc.id === input.bidId) continue;
      if (String(doc.data().status) !== 'PENDING') continue;
      txn.update(doc.ref, {
        status: 'REJECTED',
        rejected_reason: 'BID_NOT_SELECTED',
        rejected_at: FieldValue.serverTimestamp(),
      });
      rejectedBids += 1;
    }

    txn.set(orderRef.collection('events').doc('bid_accepted'), {
      type: 'BID_ACCEPTED',
      from_status: String(order.status ?? ''),
      to_status: 'ACCEPTED',
      actor_id: input.consumerId,
      actor_role: 'consumer',
      at: FieldValue.serverTimestamp(),
      meta: {
        bidId: input.bidId,
        driverId,
        finalPrice,
        commission,
        rejectedBids,
      },
    });

    return {
      ok: true as const,
      orderId: input.orderId,
      bidId: input.bidId,
      driverId,
      finalPrice,
      commission,
      balanceAfter,
      rejectedBids,
      alreadyAccepted: false,
    };
  });
}