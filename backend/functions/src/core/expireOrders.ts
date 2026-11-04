import {
  FieldValue,
  Timestamp,
  type DocumentData,
  type Firestore,
} from 'firebase-admin/firestore';

export const MERCHANT_ACCEPT_TIMEOUT_MS = 5 * 60 * 1000;
export const DRIVER_CLAIM_TIMEOUT_MS = 10 * 60 * 1000;
const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 200;

export interface ExpireOrdersInput {
  now?: Date;
  limit?: number;
  merchantTimeoutMs?: number;
  driverTimeoutMs?: number;
}

export interface ExpireOrdersResult {
  ok: true;
  expiredPlaced: number;
  expiredAwaiting: number;
  total: number;
  ids: string[];
}

async function expireOne(
  db: Firestore,
  orderId: string,
  expectedStatus: 'PLACED' | 'AWAITING_DRIVER',
  reason: 'MERCHANT_TIMEOUT' | 'DRIVER_CLAIM_TIMEOUT',
): Promise<boolean> {
  return db.runTransaction(async (txn) => {
    const ref = db.collection('orders').doc(orderId);
    const snap = await txn.get(ref);
    if (!snap.exists) return false;

    const order = snap.data() as DocumentData;
    if (String(order.status ?? '') !== expectedStatus) return false;

    txn.update(ref, {
      status: 'EXPIRED',
      expire_reason: reason,
      expired_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });
    txn.set(ref.collection('events').doc(`expired_${reason.toLowerCase()}`), {
      type: 'EXPIRED',
      from_status: expectedStatus,
      to_status: 'EXPIRED',
      actor_id: null,
      actor_role: 'system',
      at: FieldValue.serverTimestamp(),
      meta: { reason },
    });
    return true;
  });
}

/**
 * Gateway Cron (tech.md §8.10) — kedaluwarsakan order yang melewati tenggat.
 *
 * - `PLACED` lebih dari 5 menit (merchant tidak merespons) -> EXPIRED.
 * - `AWAITING_DRIVER` lebih dari 10 menit tanpa klaim -> EXPIRED.
 *
 * Query dibatasi `limit` dan memakai indeks `status + created_at`; cron tidak
 * memindai seluruh koleksi. Setiap order diproses dalam transaksi agar status
 * yang sudah berubah tidak ditimpa.
 */
export async function expireOrdersEngine(
  db: Firestore,
  input: ExpireOrdersInput = {},
): Promise<ExpireOrdersResult> {
  const now = input.now ?? new Date();
  const limit = Math.min(
    Math.max(Math.trunc(input.limit ?? DEFAULT_LIMIT), 1),
    MAX_LIMIT,
  );
  const merchantTimeoutMs = input.merchantTimeoutMs ?? MERCHANT_ACCEPT_TIMEOUT_MS;
  const driverTimeoutMs = input.driverTimeoutMs ?? DRIVER_CLAIM_TIMEOUT_MS;

  const placedCutoff = Timestamp.fromMillis(now.getTime() - merchantTimeoutMs);
  const awaitingCutoff = Timestamp.fromMillis(now.getTime() - driverTimeoutMs);

  const ids: string[] = [];
  let expiredPlaced = 0;
  let expiredAwaiting = 0;

  const placedSnap = await db
    .collection('orders')
    .where('status', '==', 'PLACED')
    .where('created_at', '<', placedCutoff)
    .limit(limit)
    .get();
  for (const doc of placedSnap.docs) {
    if (await expireOne(db, doc.id, 'PLACED', 'MERCHANT_TIMEOUT')) {
      expiredPlaced += 1;
      ids.push(doc.id);
    }
  }

  const awaitingSnap = await db
    .collection('orders')
    .where('status', '==', 'AWAITING_DRIVER')
    .where('created_at', '<', awaitingCutoff)
    .limit(limit)
    .get();
  for (const doc of awaitingSnap.docs) {
    if (await expireOne(db, doc.id, 'AWAITING_DRIVER', 'DRIVER_CLAIM_TIMEOUT')) {
      expiredAwaiting += 1;
      ids.push(doc.id);
    }
  }

  return {
    ok: true,
    expiredPlaced,
    expiredAwaiting,
    total: expiredPlaced + expiredAwaiting,
    ids,
  };
}