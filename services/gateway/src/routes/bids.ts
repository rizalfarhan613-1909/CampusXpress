import { Hono, type Context } from 'hono';
import type { Env } from '../env';
import { HttpError } from '../errors';
import { Firestore, type FirestoreDoc, type WriteOp } from '../firestore';
import { COD_MAX, computeCommission, paymentMethodOf } from '../money';

export const bidRoutes = new Hono<Env>();

const MIN_OFFERED_PRICE = 3_000;
const MAX_OFFERED_PRICE = 500_000;
const DRIVER_MIN_BALANCE = 5_000;
const MAX_ACTIVE_JOBS = 2;

const BIDDING_STATUSES = ['AWAITING_DRIVER', 'SEARCHING_BIDS'];

function toInt(value: unknown): number | null {
  if (typeof value === 'number' && Number.isInteger(value)) return value;
  if (typeof value === 'string' && /^\d+$/.test(value)) return Number(value);
  return null;
}

function clampEta(value: number | null): number {
  if (value === null) return 10;
  return Math.min(Math.max(value, 1), 120);
}

function bidDocId(uid: string): string {
  const clean = uid.replace(/[^a-zA-Z0-9_-]/g, '_').slice(0, 120);
  return `bid_${clean || 'driver'}`;
}

async function readBody(c: Context<Env>): Promise<Record<string, unknown>> {
  try {
    return await c.req.json<Record<string, unknown>>();
  } catch {
    return {};
  }
}

function text(value: unknown, fallback: string): string {
  return typeof value === 'string' && value.trim().length > 0
    ? value.trim()
    : fallback;
}

/** POST /orders/:orderId/bids — driver mengirim penawaran harga. */
bidRoutes.post('/orders/:orderId/bids', async (c) => {
  const caller = c.get('caller');
  const orderId = c.req.param('orderId');
  const body = await readBody(c);

  const offeredPrice = toInt(body.offeredPrice);
  if (offeredPrice === null || offeredPrice < MIN_OFFERED_PRICE) {
    throw new HttpError(
      400,
      'BID_TOO_LOW',
      `Penawaran minimal Rp ${MIN_OFFERED_PRICE.toLocaleString('id-ID')}.`,
    );
  }
  if (offeredPrice > MAX_OFFERED_PRICE) {
    throw new HttpError(400, 'BID_TOO_HIGH', 'Penawaran melebihi batas order.');
  }
  const estimatedArrivalMinutes = clampEta(toInt(body.estimatedArrivalMinutes));
  const bidId = bidDocId(caller.uid);

  const db = new Firestore(c.env);
  const txn = await db.begin();
  const [order, user, profile, wallet, existing] = await Promise.all([
    db.get(`orders/${orderId}`, txn),
    db.get(`users/${caller.uid}`, txn),
    db.get(`driverProfiles/${caller.uid}`, txn),
    db.get(`wallets/${caller.uid}`, txn),
    db.get(`orders/${orderId}/bids/${bidId}`, txn),
  ]);

  if (!order) throw new HttpError(404, 'ORDER_NOT_FOUND', 'Order tidak ditemukan.');

  const status = String(order.data.status ?? '');
  if (!BIDDING_STATUSES.includes(status)) {
    throw new HttpError(409, 'ORDER_NOT_BIDDING', `Order berstatus ${status}.`);
  }
  if (String(order.data.consumer_id ?? '') === caller.uid) {
    throw new HttpError(403, 'SELF_ORDER', 'Tidak dapat menawar order sendiri.');
  }

  const isApproved =
    user?.data.role === 'driver' ||
    (Array.isArray(user?.data.roles) && (user?.data.roles as unknown[]).includes('driver')) ||
    user?.data.is_verified === true ||
    user?.data.status === 'approved' ||
    profile?.data.status === 'approved';
  if (!isApproved) {
    throw new HttpError(403, 'DRIVER_NOT_VERIFIED', 'Driver belum terverifikasi.');
  }

  const balance =
    toInt(user?.data.wallet_balance) ?? toInt(wallet?.data.balance);
  if (balance === null) throw new HttpError(404, 'WALLET_NOT_FOUND', 'Dompet tidak ditemukan.');
  if (balance < DRIVER_MIN_BALANCE) {
    throw new HttpError(
      402,
      'INSUFFICIENT_BALANCE',
      `Saldo deposit minimal Rp ${DRIVER_MIN_BALANCE.toLocaleString('id-ID')}.`,
    );
  }

  if (existing && String(existing.data.status) === 'ACCEPTED') {
    throw new HttpError(409, 'BID_ALREADY_EXISTS', 'Penawaran sudah diterima.');
  }

  const isUpdate = existing !== null;
  const commissionEstimate = computeCommission(offeredPrice);
  const bidFields: Record<string, unknown> = {
    bidId,
    orderId,
    driverId: caller.uid,
    driverName: text(body.driverName, text(user?.data.name, 'Driver')),
    driverPhoto: text(body.driverPhoto, text(user?.data.photo_url, '')) || null,
    rating: Number(body.rating ?? user?.data.rating ?? 5),
    platNumber: text(body.platNumber, text(profile?.data.plat_number, '')),
    vehicleModel: text(body.vehicleModel, text(profile?.data.vehicle_model, 'Motor')),
    offeredPrice,
    estimatedArrivalMinutes,
    status: 'PENDING',
  };

  const ops: WriteOp[] = [
    {
      path: `orders/${orderId}/bids/${bidId}`,
      set: bidFields,
      mask: Object.keys(bidFields),
      serverTime: isUpdate ? ['updated_at'] : ['created_at'],
    },
    {
      path: `orders/${orderId}`,
      precondition: order.updateTime,
      mask: ['status', 'bid_count', 'updated_at'],
      set: { status: 'SEARCHING_BIDS' },
      ...(isUpdate ? {} : { increments: { bid_count: 1 } }),
      serverTime: ['updated_at'],
    },
  ];

  await db.commit(ops, txn);

  return c.json({
    ok: true,
    bidId,
    orderId,
    offeredPrice,
    estimatedArrivalMinutes,
    commissionEstimate,
    balance,
    updated: isUpdate,
  });
});

/** POST /orders/:orderId/bids/:bidId/accept — konsumen menerima penawaran. */
bidRoutes.post('/orders/:orderId/bids/:bidId/accept', async (c) => {
  const caller = c.get('caller');
  const orderId = c.req.param('orderId');
  const bidId = c.req.param('bidId');

  const db = new Firestore(c.env);
  const txn = await db.begin();

  const order = await db.get(`orders/${orderId}`, txn);
  if (!order) throw new HttpError(404, 'ORDER_NOT_FOUND', 'Order tidak ditemukan.');
  if (String(order.data.consumer_id ?? '') !== caller.uid) {
    throw new HttpError(403, 'ORDER_NOT_OWNER', 'Bukan order milik Anda.');
  }

  const status = String(order.data.status ?? '');
  if (!BIDDING_STATUSES.includes(status)) {
    throw new HttpError(409, 'ORDER_NOT_BIDDING', `Order berstatus ${status}.`);
  }

  const bids: FirestoreDoc[] = await db.runQuery(
    'bids',
    {},
    txn,
    `orders/${orderId}`,
  );
  const target = bids.find((item) => item.id === bidId);
  if (!target) throw new HttpError(404, 'BID_NOT_FOUND', 'Penawaran tidak ditemukan.');
  if (String(target.data.status) !== 'PENDING') {
    throw new HttpError(409, 'ORDER_NOT_BIDDING', 'Penawaran tidak lagi aktif.');
  }

  const finalPrice =
    toInt(target.data.offeredPrice) ?? toInt(target.data.offered_price);
  if (finalPrice === null || finalPrice < MIN_OFFERED_PRICE) {
    throw new HttpError(400, 'BID_TOO_LOW', 'Nominal penawaran tidak valid.');
  }

  // Batas COD divalidasi pada harga final yang dikunci, bukan pada input klien.
  if (paymentMethodOf(order.data) === 'COD' && finalPrice > COD_MAX) {
    throw new HttpError(
      400,
      'COD_LIMIT_EXCEEDED',
      `Transaksi COD maksimal Rp ${COD_MAX.toLocaleString('id-ID')}; penawaran ini melebihi batas.`,
    );
  }

  const driverId = String(target.data.driverId ?? target.data.driver_id ?? '');
  if (!driverId) throw new HttpError(404, 'BID_NOT_FOUND', 'Penawaran tanpa driver.');

  const commission = computeCommission(finalPrice);
  const [driver, profile, wallet, ledger] = await Promise.all([
    db.get(`users/${driverId}`, txn),
    db.get(`driverProfiles/${driverId}`, txn),
    db.get(`wallets/${driverId}`, txn),
    db.get(`wallet_ledger/commission_${orderId}`, txn),
  ]);

  const balance =
    toInt(driver?.data.wallet_balance) ?? toInt(wallet?.data.balance);
  if (balance === null) {
    throw new HttpError(404, 'WALLET_NOT_FOUND', 'Dompet tidak ditemukan.');
  }

  const alreadySettled = ledger !== null;
  if (!alreadySettled && balance < commission) {
    throw new HttpError(402, 'INSUFFICIENT_BALANCE', 'Saldo tidak cukup untuk komisi.');
  }
  const balanceAfter = alreadySettled ? balance : balance - commission;

  const activeJobs =
    toInt(driver?.data.active_jobs) ?? toInt(profile?.data.active_jobs) ?? 0;
  if (activeJobs >= MAX_ACTIVE_JOBS) {
    throw new HttpError(409, 'TOO_MANY_JOBS', 'Driver sudah menangani 2 order aktif.');
  }

  const driverName = text(
    target.data.driverName,
    text(target.data.driver_name, text(driver?.data.name, 'Driver')),
  );

  const ops: WriteOp[] = [];

  if (driver && toInt(driver.data.wallet_balance) !== null) {
    ops.push({
      path: `users/${driverId}`,
      precondition: driver.updateTime,
      mask: ['wallet_balance', 'active_jobs', 'updated_at'],
      set: { wallet_balance: balanceAfter, active_jobs: activeJobs + 1 },
      serverTime: ['updated_at'],
    });
  } else if (wallet) {
    ops.push({
      path: `wallets/${driverId}`,
      precondition: wallet.updateTime,
      mask: ['balance', 'updated_at'],
      set: { balance: balanceAfter },
      serverTime: ['updated_at'],
    });
  }

  if (!alreadySettled) {
    ops.push({
      path: `wallet_ledger/commission_${orderId}`,
      mustNotExist: true,
      set: {
        id: `commission_${orderId}`,
        driver_id: driverId,
        order_id: orderId,
        type: 'COMMISSION_DEDUCTION',
        amount: -commission,
        balance_after: balanceAfter,
        description: `Komisi 0,5% bid disetujui untuk order ${orderId}`,
        idempotency_key: `commission:${orderId}`,
      },
      serverTime: ['created_at'],
    });
  }

  const orderFields: Record<string, unknown> = {
    status: 'ACCEPTED',
    driver_id: driverId,
    driver_name: driverName,
    final_price: finalPrice,
    total_price: finalPrice,
    commission_fee: commission,
    accepted_bid_id: bidId,
  };
  ops.push({
    path: `orders/${orderId}`,
    precondition: order.updateTime,
    mask: Object.keys(orderFields),
    set: orderFields,
    serverTime: ['accepted_at', 'updated_at'],
  });

  ops.push({
    path: `orders/${orderId}/bids/${bidId}`,
    precondition: target.updateTime,
    mask: ['status', 'accepted_at'],
    set: { status: 'ACCEPTED' },
    serverTime: ['accepted_at'],
  });

  let rejectedBids = 0;
  for (const bid of bids) {
    if (bid.id === bidId) continue;
    if (String(bid.data.status) !== 'PENDING') continue;
    ops.push({
      path: `orders/${orderId}/bids/${bid.id}`,
      precondition: bid.updateTime,
      mask: ['status', 'rejected_reason', 'rejected_at'],
      set: { status: 'REJECTED', rejected_reason: 'BID_NOT_SELECTED' },
      serverTime: ['rejected_at'],
    });
    rejectedBids += 1;
  }

  const event = {
    type: 'BID_ACCEPTED',
    from_status: status,
    to_status: 'ACCEPTED',
    actor_id: caller.uid,
    actor_role: 'consumer',
    meta: { bidId, driverId, finalPrice, commission, rejectedBids },
  };
  ops.push({
    path: `orders/${orderId}/events/bid_accepted`,
    set: event,
    mask: Object.keys(event),
    serverTime: ['at'],
  });

  await db.commit(ops, txn);

  return c.json({
    ok: true,
    orderId,
    bidId,
    driverId,
    finalPrice,
    commission,
    balanceAfter,
    rejectedBids,
  });
});