import { randomInt } from 'node:crypto';
import {
  FieldValue,
  type DocumentData,
  type Firestore,
} from 'firebase-admin/firestore';
import { GatewayError } from './errors';
import {
  DRIVER_MIN_BALANCE,
  MAX_ACTIVE_JOBS,
  assertCodPolicy,
  computeCommission,
  getOrderTotal,
  prettyRupiah,
  toInteger,
} from './money';

export interface ClaimOrderInput {
  driverId: string;
  orderId: string;
}

export interface ClaimOrderResult {
  ok: true;
  orderId: string;
  status: 'CLAIMED';
  activeJobs: number;
  commissionEstimate: number;
}

const ACTIVE_ORDER_STATUSES = new Set([
  'CLAIMED',
  'AT_PICKUP',
  'ON_DELIVERY',
  'ARRIVED',
  'DISPUTED',
]);

const CLAIMED_OR_FINISHED_STATUSES = new Set([
  ...ACTIVE_ORDER_STATUSES,
  'COMPLETED',
]);

function hasDriverRole(user: DocumentData | undefined, profile: DocumentData | undefined): boolean {
  if (user?.role === 'driver') return true;
  if (Array.isArray(user?.roles) && user.roles.includes('driver')) return true;
  return profile?.status === 'approved';
}

function isVerifiedDriver(user: DocumentData | undefined, profile: DocumentData | undefined): boolean {
  if (user?.is_verified === true) return true;
  if (user?.status === 'approved') return true;
  return profile?.status === 'approved';
}

/**
 * Gateway M08 — klaim order 1-klik secara atomik.
 *
 * Semua validasi dan tulisan berada di db.runTransaction() sehingga dua driver
 * yang menekan Klaim bersamaan tidak mungkin sama-sama menang.
 */
export async function claimOrderEngine(
  db: Firestore,
  input: ClaimOrderInput,
): Promise<ClaimOrderResult> {
  if (!input.driverId || !input.orderId) {
    throw new GatewayError('INVALID_ARGUMENT', 'driverId dan orderId wajib diisi.');
  }

  return db.runTransaction(async (txn) => {
    const orderRef = db.collection('orders').doc(input.orderId);
    const driverRef = db.collection('users').doc(input.driverId);
    const driverProfileRef = db.collection('driverProfiles').doc(input.driverId);
    const walletRef = db.collection('wallets').doc(input.driverId);
    const secretRef = orderRef.collection('secrets').doc('handover');

    // ---- SEMUA PEMBACAAN HARUS SELESAI SEBELUM PENULISAN PERTAMA ----
    const [orderSnap, driverSnap, profileSnap, walletSnap] = await Promise.all([
      txn.get(orderRef),
      txn.get(driverRef),
      txn.get(driverProfileRef),
      txn.get(walletRef),
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

    if (order.status !== 'AWAITING_DRIVER') {
      if (CLAIMED_OR_FINISHED_STATUSES.has(String(order.status))) {
        throw new GatewayError('ORDER_TAKEN', 'Order sudah diambil.');
      }
      throw new GatewayError(
        'INVALID_ORDER_STATE',
        `Order berstatus ${String(order.status)} dan belum bisa diklaim.`,
      );
    }

    if (order.consumer_id === input.driverId) {
      throw new GatewayError(
        'SELF_ORDER',
        'Driver tidak dapat mengklaim order miliknya sendiri.',
      );
    }

    // PRD M06 FR-06.3 — pertahanan terakhir bila order COD > Rp 200.000 lolos.
    assertCodPolicy(order);

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
        `Saldo deposit minimal ${prettyRupiah(DRIVER_MIN_BALANCE)} untuk klaim order. Silakan top-up.`,
        { balance, required: DRIVER_MIN_BALANCE },
      );
    }

    // Sumber utama adalah counter atomik users/{uid}.active_jobs. Jika data lama
    // belum memiliki counter, hitung dari order aktif sebagai fallback.
    let activeJobs =
      toInteger(driver?.active_jobs) ?? toInteger(profile?.active_jobs);
    if (activeJobs === null) {
      const activeSnap = await txn.get(
        db.collection('orders').where('driver_id', '==', input.driverId),
      );
      activeJobs = activeSnap.docs.filter((doc) =>
        ACTIVE_ORDER_STATUSES.has(String(doc.data().status)),
      ).length;
    }
    if (activeJobs >= MAX_ACTIVE_JOBS) {
      throw new GatewayError(
        'TOO_MANY_JOBS',
        `Driver sudah menangani ${MAX_ACTIVE_JOBS} order aktif. Selesaikan salah satu terlebih dahulu.`,
        { activeJobs, max: MAX_ACTIVE_JOBS },
      );
    }

    const commissionEstimate = computeCommission(getOrderTotal(order));
    const pin = String(randomInt(0, 10_000)).padStart(4, '0');
    const nextActiveJobs = activeJobs + 1;

    // ---- PENULISAN ATOMIK ----
    if (driverSnap.exists) {
      txn.update(driverRef, {
        active_jobs: nextActiveJobs,
        updated_at: FieldValue.serverTimestamp(),
      });
    } else if (profileSnap.exists) {
      txn.update(driverProfileRef, { active_jobs: nextActiveJobs });
    } else {
      txn.set(
        driverRef,
        { active_jobs: nextActiveJobs, updated_at: FieldValue.serverTimestamp() },
        { merge: true },
      );
    }

    txn.update(orderRef, {
      driver_id: input.driverId,
      status: 'CLAIMED',
      claimed_at: FieldValue.serverTimestamp(),
      commission_fee: commissionEstimate,
    });

    // Dokumen rahasia hanya dapat dibaca konsumen pemesan (firestore.rules).
    txn.set(secretRef, {
      dropoff_pin: pin,
      failed_attempts: 0,
      locked_until: null,
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });

    txn.set(orderRef.collection('events').doc(`claim_${input.driverId}`), {
      type: 'CLAIMED',
      from_status: 'AWAITING_DRIVER',
      to_status: 'CLAIMED',
      actor_id: input.driverId,
      actor_role: 'driver',
      at: FieldValue.serverTimestamp(),
      meta: { commissionEstimate },
    });

    return {
      ok: true as const,
      orderId: input.orderId,
      status: 'CLAIMED' as const,
      activeJobs: nextActiveJobs,
      commissionEstimate,
    };
  });
}
