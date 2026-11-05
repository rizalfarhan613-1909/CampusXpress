import {
  FieldValue,
  type DocumentData,
  type Firestore,
} from 'firebase-admin/firestore';
import {
  BIDDING_ORDER_STATUSES,
  bidDocId,
  buildBidData,
  hasDriverRole,
  isVerifiedDriver,
  normalizeArrivalMinutes,
  normalizeOfferedPrice,
  type BidStatus,
} from './bids';
import { GatewayError } from './errors';
import {
  DRIVER_MIN_BALANCE,
  computeCommission,
  prettyRupiah,
  toInteger,
} from './money';

export interface SubmitBidInput {
  driverId: string;
  orderId: string;
  offeredPrice: number;
  estimatedArrivalMinutes?: number;
  driverName?: string;
  driverPhoto?: string;
  rating?: number;
  platNumber?: string;
  vehicleModel?: string;
}

export interface SubmitBidResult {
  ok: true;
  bidId: string;
  orderId: string;
  driverId: string;
  offeredPrice: number;
  estimatedArrivalMinutes: number;
  commissionEstimate: number;
  balance: number;
  updated: boolean;
  status: BidStatus;
}

/**
 * Fase 5 — `submitBid`: driver mengirim penawaran harga secara atomik.
 *
 * Validasi:
 * - driver berstatus `approved` (role driver + terverifikasi),
 * - saldo deposit driver ≥ Rp 5.000,
 * - `offeredPrice` integer ≥ Rp 3.000,
 * - order masih menerima bid (`AWAITING_DRIVER` / `SEARCHING_BIDS`),
 * - driver bukan konsumen pemesan.
 *
 * Efek: `orders/{orderId}/bids/bid_<driverId>` (status PENDING) +
 * `orders/{orderId}.status = 'SEARCHING_BIDS'` + `bid_count` bertambah.
 */
export async function submitBidEngine(
  db: Firestore,
  input: SubmitBidInput,
): Promise<SubmitBidResult> {
  if (!input.driverId || !input.orderId) {
    throw new GatewayError('INVALID_ARGUMENT', 'driverId dan orderId wajib diisi.');
  }
  const offeredPrice = normalizeOfferedPrice(input.offeredPrice);
  const estimatedArrivalMinutes = normalizeArrivalMinutes(
    input.estimatedArrivalMinutes,
  );

  return db.runTransaction(async (txn) => {
    const orderRef = db.collection('orders').doc(input.orderId);
    const driverRef = db.collection('users').doc(input.driverId);
    const driverProfileRef = db.collection('driverProfiles').doc(input.driverId);
    const walletRef = db.collection('wallets').doc(input.driverId);
    const bidRef = orderRef.collection('bids').doc(bidDocId(input.driverId));

    // ---- SEMUA PEMBACAAN SEBELUM PENULISAN PERTAMA ----
    const [orderSnap, driverSnap, profileSnap, walletSnap, bidSnap] =
      await Promise.all([
        txn.get(orderRef),
        txn.get(driverRef),
        txn.get(driverProfileRef),
        txn.get(walletRef),
        txn.get(bidRef),
      ]);

    if (!orderSnap.exists) {
      throw new GatewayError('ORDER_NOT_FOUND', 'Order tidak ditemukan.');
    }

    const order = orderSnap.data() as DocumentData;
    const driver = driverSnap.exists
      ? (driverSnap.data() as DocumentData)
      : undefined;
    const profile = profileSnap.exists
      ? (profileSnap.data() as DocumentData)
      : undefined;
    const wallet = walletSnap.exists
      ? (walletSnap.data() as DocumentData)
      : undefined;

    if (!hasDriverRole(driver, profile)) {
      throw new GatewayError(
        'DRIVER_NOT_VERIFIED',
        'Akun ini tidak memiliki peran driver yang terverifikasi.',
      );
    }
    if (!isVerifiedDriver(driver, profile)) {
      throw new GatewayError(
        'DRIVER_NOT_VERIFIED',
        'Driver belum terverifikasi. Selesaikan verifikasi KTM/SIM terlebih dahulu.',
      );
    }

    if (!BIDDING_ORDER_STATUSES.has(String(order.status ?? ''))) {
      throw new GatewayError(
        'ORDER_NOT_BIDDING',
        `Order berstatus ${String(order.status)} dan tidak menerima penawaran lagi.`,
      );
    }

    if (String(order.consumer_id ?? '') === input.driverId) {
      throw new GatewayError(
        'SELF_ORDER',
        'Driver tidak dapat menawar order miliknya sendiri.',
      );
    }

    const balance =
      toInteger(driver?.wallet_balance) ?? toInteger(wallet?.balance);
    if (balance === null) {
      throw new GatewayError(
        'WALLET_NOT_FOUND',
        'Dompet deposit driver tidak ditemukan.',
      );
    }
    if (balance < DRIVER_MIN_BALANCE) {
      throw new GatewayError(
        'INSUFFICIENT_BALANCE',
        `Saldo deposit minimal ${prettyRupiah(DRIVER_MIN_BALANCE)} untuk mengirim penawaran. Silakan top-up.`,
        { balance, required: DRIVER_MIN_BALANCE },
      );
    }

    const previous = bidSnap.exists ? (bidSnap.data() as DocumentData) : null;
    if (previous && String(previous.status) === 'ACCEPTED') {
      throw new GatewayError(
        'BID_ALREADY_EXISTS',
        'Penawaran ini sudah diterima konsumen dan tidak dapat diubah.',
      );
    }

    const commissionEstimate = computeCommission(offeredPrice);
    const data = buildBidData({
      orderId: input.orderId,
      driverId: input.driverId,
      offeredPrice,
      estimatedArrivalMinutes,
      profile: {
        driverName: input.driverName ?? driver?.name ?? profile?.name,
        driverPhoto:
          input.driverPhoto ??
          driver?.photo_url ??
          driver?.photoUrl ??
          profile?.photo_url,
        rating: input.rating ?? driver?.rating ?? profile?.rating,
        platNumber:
          input.platNumber ??
          driver?.plat_number ??
          profile?.plat_number ??
          profile?.plate_number,
        vehicleModel:
          input.vehicleModel ??
          driver?.vehicle_model ??
          profile?.vehicle_model ??
          profile?.vehicle_type,
      },
    });

    const isUpdate = bidSnap.exists;

    txn.set(
      bidRef,
      {
        ...data,
        ...(isUpdate
          ? { updated_at: FieldValue.serverTimestamp() }
          : { created_at: FieldValue.serverTimestamp() }),
        status: 'PENDING',
      },
      { merge: true },
    );

    txn.update(orderRef, {
      status: 'SEARCHING_BIDS',
      bid_count: FieldValue.increment(isUpdate ? 0 : 1),
      updated_at: FieldValue.serverTimestamp(),
    });

    txn.set(orderRef.collection('events').doc(`bid_${input.driverId}`), {
      type: 'BID_SUBMITTED',
      from_status: String(order.status ?? ''),
      to_status: 'SEARCHING_BIDS',
      actor_id: input.driverId,
      actor_role: 'driver',
      at: FieldValue.serverTimestamp(),
      meta: { bidId: data.bidId, offeredPrice, estimatedArrivalMinutes },
    });

    return {
      ok: true as const,
      bidId: data.bidId,
      orderId: input.orderId,
      driverId: input.driverId,
      offeredPrice,
      estimatedArrivalMinutes,
      commissionEstimate,
      balance,
      updated: isUpdate,
      status: 'PENDING' as const,
    };
  });
}