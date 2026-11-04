import { onCall } from 'firebase-functions/v2/https';
import { getDb, requireNonEmptyString } from './core/firestore';
import { requireAuthUid, toHttpsError } from './core/https';
import { topUpWalletEngine } from './core/topUpWallet';

/**
 * POST /wallet/topup (callable, admin only).
 * Custom claim: role === 'admin' (juga menerima admin === true).
 */
export const topUpWallet = onCall(async (request) => {
  try {
    const adminId = requireAuthUid(request.auth);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const driverId = requireNonEmptyString(data.driverId, 'driverId');

    return await topUpWalletEngine(getDb(), {
      adminClaims: request.auth?.token as Record<string, unknown> | undefined,
      adminId,
      driverId,
      amount: Number(data.amount),
      adminNotes:
        typeof data.adminNotes === 'string' ? data.adminNotes : undefined,
      idempotencyKey:
        typeof data.idempotencyKey === 'string'
          ? data.idempotencyKey
          : undefined,
    });
  } catch (error) {
    throw toHttpsError(error);
  }
});
