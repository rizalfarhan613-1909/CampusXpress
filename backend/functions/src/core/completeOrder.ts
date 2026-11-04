import { timingSafeEqual } from 'node:crypto';
import {
  FieldValue,
  type DocumentData,
  type Firestore,
} from 'firebase-admin/firestore';
import { GatewayError } from './errors';
import {
  PIN_LOCK_MS,
  PIN_MAX_ATTEMPTS,
  computeCommission,
  getOrderTotal,
  prettyRupiah,
  toInteger,
} from './money';
import { asDate } from './firestore';

export interface CompleteOrderInput {
  driverId: string;
  orderId: string;
  inputPin: string | number;
}

export interface CompleteOrderResult {
  ok: true;
  orderId: string;
  status: 'COMPLETED';
  alreadyCompleted: boolean;
  commission: number;
  balanceAfter: number;
}

type TxnFailure = {
  ok: false;
  code: 'PIN_WRONG' | 'PIN_LOCKED';
  message: string;
  attempts: number;
  lockedUntil: Date | null;
};

type TxnSuccess = CompleteOrderResult;

function safeEqual(a: string, b: string): boolean {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  if (left.length !== right.length) return false;
  return timingSafeEqual(left, right);
}

function normalizePin(value: string | number): string {
  const pin =
    typeof value === 'number'
      ? String(value).padStart(4, '0')
      : value.trim();
  if (!/^\d{4}$/.test(pin)) {
    throw new GatewayError('INVALID_ARGUMENT', 'PIN harus berupa 4 digit angka.');
  }
  return pin;
}

/**
 * Gateway M09 — verifikasi PIN serah-terima dan penyelesaian order.
 *
 * Termasuk:
 * - lock 10 menit setelah 5 PIN salah + event PIN_LOCKED,
 * - status COMPLETED,
 * - potong komisi 0,5% dari wallet driver,
 * - ledger COMMISSION_DEDUCTION idempoten (satu baris per order).
 */
export async function completeOrderEngine(
  db: Firestore,
  input: CompleteOrderInput,
): Promise<CompleteOrderResult> {
  if (!input.driverId || !input.orderId) {
    throw new GatewayError('INVALID_ARGUMENT', 'driverId dan orderId wajib diisi.');
  }
  const inputPin = normalizePin(input.inputPin);

  const transactionResult = await db.runTransaction<TxnSuccess | TxnFailure>(
    async (txn) => {
      const orderRef = db.collection('orders').doc(input.orderId);
      const secretRef = orderRef.collection('secrets').doc('handover');
      const driverRef = db.collection('users').doc(input.driverId);
      const driverProfileRef = db.collection('driverProfiles').doc(input.driverId);
      const walletRef = db.collection('wallets').doc(input.driverId);
      const ledgerRef = db
        .collection('wallet_ledger')
        .doc(`commission_${input.orderId}`);

      // ---- SEMUA PEMBACAAN SEBELUM PENULISAN ----
      const [orderSnap, secretSnap, driverSnap, profileSnap, walletSnap, ledgerSnap] =
        await Promise.all([
          txn.get(orderRef),
          txn.get(secretRef),
          txn.get(driverRef),
          txn.get(driverProfileRef),
          txn.get(walletRef),
          txn.get(ledgerRef),
        ]);

      if (!orderSnap.exists) {
        throw new GatewayError('ORDER_NOT_FOUND', 'Order tidak ditemukan.');
      }

      const order = orderSnap.data() as DocumentData;
      const orderDriverId = String(order.driver_id ?? '');
      if (orderDriverId !== input.driverId) {
        throw new GatewayError(
          'NOT_ASSIGNED',
          'Order ini bukan tugas driver yang sedang login.',
        );
      }

      const commissionFromOrder =
        toInteger(order.commission_fee) ??
        computeCommission(getOrderTotal(order));

      // Idempotensi: permintaan selesai yang dikirim ulang tidak memotong saldo lagi.
      if (order.status === 'COMPLETED') {
        const ledger = ledgerSnap.exists
          ? (ledgerSnap.data() as DocumentData)
          : undefined;
        const ledgerAmount = toInteger(ledger?.amount);
        const driver = driverSnap.exists
          ? (driverSnap.data() as DocumentData)
          : undefined;
        return {
          ok: true,
          orderId: input.orderId,
          status: 'COMPLETED',
          alreadyCompleted: true,
          commission:
            ledgerAmount !== null ? Math.abs(ledgerAmount) : commissionFromOrder,
          balanceAfter:
            toInteger(ledger?.balance_after) ??
            toInteger(driver?.wallet_balance) ??
            0,
        };
      }

      // M07 FR-07.1: driver hanya boleh menutup order dari status ARRIVED.
      if (order.status !== 'ARRIVED') {
        throw new GatewayError(
          'INVALID_ORDER_STATE',
          `Order harus berstatus ARRIVED sebelum diselesaikan (saat ini ${String(order.status)}).`,
        );
      }

      if (!secretSnap.exists) {
        throw new GatewayError(
          'SECRET_NOT_FOUND',
          'Dokumen PIN serah-terima tidak ditemukan.',
        );
      }

      const secret = secretSnap.data() as DocumentData;
      const now = new Date();
      const lockedUntil = asDate(secret.locked_until);
      if (lockedUntil && lockedUntil.getTime() > now.getTime()) {
        return {
          ok: false,
          code: 'PIN_LOCKED',
          message: 'Input PIN terkunci 10 menit akibat salah 5 kali.',
          attempts: toInteger(secret.failed_attempts) ?? PIN_MAX_ATTEMPTS,
          lockedUntil,
        };
      }

      const lockExpired =
        lockedUntil !== null && lockedUntil.getTime() <= now.getTime();
      let attempts =
        toInteger(secret.failed_attempts) ?? toInteger(secret.attempts) ?? 0;
      if (lockExpired) attempts = 0;

      const expectedPin = String(secret.dropoff_pin ?? secret.pin ?? '');
      const pinMatches =
        expectedPin.length === 4 && safeEqual(expectedPin, inputPin);

      if (!pinMatches) {
        const nextAttempts = attempts + 1;
        const shouldLock = nextAttempts >= PIN_MAX_ATTEMPTS;
        const newLockedUntil = shouldLock
          ? new Date(now.getTime() + PIN_LOCK_MS)
          : null;

        txn.set(
          secretRef,
          {
            failed_attempts: nextAttempts,
            locked_until: newLockedUntil,
            last_attempt_at: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );

        if (shouldLock) {
          txn.set(orderRef.collection('events').doc('pin_locked'), {
            type: 'PIN_LOCKED',
            from_status: String(order.status),
            to_status: String(order.status),
            actor_id: input.driverId,
            actor_role: 'driver',
            at: FieldValue.serverTimestamp(),
            meta: {
              attempts: nextAttempts,
              locked_until: newLockedUntil,
              order_id: input.orderId,
            },
          });
        }

        return {
          ok: false,
          code: shouldLock ? 'PIN_LOCKED' : 'PIN_WRONG',
          message: shouldLock
            ? 'Input PIN terkunci 10 menit akibat salah 5 kali.'
            : `PIN salah. Sisa percobaan: ${PIN_MAX_ATTEMPTS - nextAttempts}.`,
          attempts: nextAttempts,
          lockedUntil: newLockedUntil,
        };
      }

      // ---- PIN BENAR: selesaikan order dan potong komisi secara atomik ----
      const total = getOrderTotal(order);
      if (total <= 0) {
        throw new GatewayError(
          'INVALID_ORDER_STATE',
          'Nilai order tidak valid untuk perhitungan komisi.',
        );
      }
      const commission = computeCommission(total);
      const driver = driverSnap.exists
        ? (driverSnap.data() as DocumentData)
        : undefined;
      const wallet = walletSnap.exists
        ? (walletSnap.data() as DocumentData)
        : undefined;
      const profile = profileSnap.exists
        ? (profileSnap.data() as DocumentData)
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
          `Saldo tidak cukup untuk komisi ${prettyRupiah(commission)}.`,
          { balance: currentBalance, commission },
        );
      }

      const balanceAfter = alreadySettled
        ? currentBalance
        : currentBalance - commission;
      const activeJobs =
        toInteger(driver?.active_jobs) ?? toInteger(profile?.active_jobs) ?? 1;
      const nextActiveJobs = Math.max(0, activeJobs - 1);

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
      }

      txn.update(orderRef, {
        status: 'COMPLETED',
        commission_fee: commission,
        completed_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      });

      if (!alreadySettled) {
        txn.set(ledgerRef, {
          id: ledgerRef.id,
          driver_id: input.driverId,
          order_id: input.orderId,
          type: 'COMMISSION_DEDUCTION',
          amount: -commission,
          balance_after: balanceAfter,
          description: `Komisi 0,5% untuk order ${input.orderId}`,
          idempotency_key: `commission:${input.orderId}`,
          created_at: FieldValue.serverTimestamp(),
        });
      }

      txn.set(
        secretRef,
        {
          failed_attempts: 0,
          locked_until: null,
          verified_at: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      txn.set(orderRef.collection('events').doc('completed'), {
        type: 'COMPLETED',
        from_status: 'ARRIVED',
        to_status: 'COMPLETED',
        actor_id: input.driverId,
        actor_role: 'driver',
        at: FieldValue.serverTimestamp(),
        meta: { commission, balanceAfter },
      });

      return {
        ok: true,
        orderId: input.orderId,
        status: 'COMPLETED',
        alreadyCompleted: false,
        commission,
        balanceAfter,
      };
    },
  );

  if (!transactionResult.ok) {
    throw new GatewayError(
      transactionResult.code,
      transactionResult.message,
      {
        attempts: transactionResult.attempts,
        lockedUntil: transactionResult.lockedUntil?.toISOString() ?? null,
      },
    );
  }

  return transactionResult;
}
