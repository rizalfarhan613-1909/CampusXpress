import { randomUUID } from 'node:crypto';
import {
  FieldValue,
  type DocumentData,
  type Firestore,
} from 'firebase-admin/firestore';
import { GatewayError } from './errors';
import { toInteger } from './money';

export interface TopUpWalletInput {
  /** Custom claims token Firebase: role === 'admin' atau admin === true. */
  adminClaims: Record<string, unknown> | undefined;
  adminId?: string;
  driverId: string;
  amount: number;
  adminNotes?: string;
  idempotencyKey?: string;
}

export interface TopUpWalletResult {
  ok: true;
  ledgerId: string;
  driverId: string;
  amount: number;
  balanceAfter: number;
  alreadyProcessed: boolean;
}

function assertAdmin(claims: Record<string, unknown> | undefined): void {
  if (!claims) {
    throw new GatewayError('UNAUTHENTICATED', 'Admin harus login.');
  }
  const isAdmin = claims.role === 'admin' || claims.admin === true;
  if (!isAdmin) {
    throw new GatewayError(
      'PERMISSION_DENIED',
      'Hanya admin yang dapat mengonfirmasi top-up deposit driver.',
    );
  }
}

function safeLedgerKey(value: string): string {
  const cleaned = value.replace(/[^a-zA-Z0-9_-]/g, '_').slice(0, 100);
  return cleaned.length > 0 ? cleaned : randomUUID();
}

/**
 * Gateway M13 — konfirmasi top-up deposit driver oleh admin.
 *
 * Input: driverId, amount, adminNotes.
 * Efek: wallet_balance bertambah + satu baris wallet_ledger bertipe COMMISSION_TOPUP.
 */
export async function topUpWalletEngine(
  db: Firestore,
  input: TopUpWalletInput,
): Promise<TopUpWalletResult> {
  assertAdmin(input.adminClaims);

  if (!input.driverId || typeof input.driverId !== 'string') {
    throw new GatewayError('INVALID_ARGUMENT', 'driverId wajib diisi.');
  }
  if (!Number.isInteger(input.amount) || input.amount <= 0) {
    throw new GatewayError(
      'INVALID_ARGUMENT',
      'amount harus integer Rupiah lebih dari 0.',
    );
  }

  const ledgerId = input.idempotencyKey
    ? `topup_${safeLedgerKey(input.idempotencyKey)}`
    : `topup_${randomUUID()}`;

  return db.runTransaction(async (txn) => {
    const driverRef = db.collection('users').doc(input.driverId);
    const walletRef = db.collection('wallets').doc(input.driverId);
    const ledgerRef = db.collection('wallet_ledger').doc(ledgerId);

    const [driverSnap, walletSnap, ledgerSnap] = await Promise.all([
      txn.get(driverRef),
      txn.get(walletRef),
      txn.get(ledgerRef),
    ]);

    const driver = driverSnap.exists
      ? (driverSnap.data() as DocumentData)
      : undefined;
    const wallet = walletSnap.exists
      ? (walletSnap.data() as DocumentData)
      : undefined;

    if (!driver && !wallet) {
      throw new GatewayError(
        'DRIVER_NOT_FOUND',
        'Driver atau dompet driver tidak ditemukan.',
      );
    }

    if (ledgerSnap.exists) {
      const ledger = ledgerSnap.data() as DocumentData;
      return {
        ok: true as const,
        ledgerId,
        driverId: input.driverId,
        amount: toInteger(ledger.amount) ?? input.amount,
        balanceAfter:
          toInteger(ledger.balance_after) ??
          toInteger(driver?.wallet_balance) ??
          toInteger(wallet?.balance) ??
          0,
        alreadyProcessed: true,
      };
    }

    const currentBalance =
      toInteger(driver?.wallet_balance) ?? toInteger(wallet?.balance);
    if (currentBalance === null) {
      throw new GatewayError(
        'WALLET_NOT_FOUND',
        'Saldo dompet driver tidak ditemukan.',
      );
    }

    const balanceAfter = currentBalance + input.amount;
    if (!Number.isInteger(balanceAfter) || balanceAfter < 0) {
      throw new GatewayError(
        'WALLET_NEGATIVE',
        'Saldo dompet tidak boleh negatif.',
      );
    }

    if (driverSnap.exists && toInteger(driver?.wallet_balance) !== null) {
      txn.update(driverRef, {
        wallet_balance: balanceAfter,
        updated_at: FieldValue.serverTimestamp(),
      });
    } else if (walletSnap.exists) {
      txn.update(walletRef, {
        balance: balanceAfter,
        updated_at: FieldValue.serverTimestamp(),
      });
    }

    txn.set(ledgerRef, {
      id: ledgerId,
      driver_id: input.driverId,
      type: 'COMMISSION_TOPUP',
      amount: input.amount,
      balance_after: balanceAfter,
      description:
        input.adminNotes?.trim() ||
        `Top-up deposit driver oleh admin${input.adminId ? ` ${input.adminId}` : ''}`,
      admin_notes: input.adminNotes?.trim() ?? null,
      approved_by: input.adminId ?? null,
      idempotency_key: input.idempotencyKey
        ? `topup:${input.idempotencyKey}`
        : `topup:${ledgerId}`,
      created_at: FieldValue.serverTimestamp(),
    });

    return {
      ok: true as const,
      ledgerId,
      driverId: input.driverId,
      amount: input.amount,
      balanceAfter,
      alreadyProcessed: false,
    };
  });
}
