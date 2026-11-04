import { onCall } from 'firebase-functions/v2/https';
import {
  cancelOrderEngine,
  type CancelActorRole,
} from './core/cancelOrder';
import { getDb, requireNonEmptyString } from './core/firestore';
import { requireAuthUid, toHttpsError } from './core/https';

const ROLES: readonly CancelActorRole[] = [
  'consumer',
  'driver',
  'merchant',
  'admin',
];

function parseRole(value: unknown): CancelActorRole {
  return typeof value === 'string' && (ROLES as readonly string[]).includes(value)
    ? (value as CancelActorRole)
    : 'consumer';
}

/**
 * POST /orders/{id}/cancel (callable).
 * Menerapkan kebijakan pembatalan Rules.md §7 beserta perhitungan strike.
 */
export const cancelOrder = onCall(async (request) => {
  try {
    const actorId = requireAuthUid(request.auth);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const orderId = requireNonEmptyString(data.orderId, 'orderId');
    const claims = request.auth?.token as Record<string, unknown> | undefined;

    return await cancelOrderEngine(getDb(), {
      orderId,
      actorId,
      actorRole: parseRole(data.role),
      adminClaims: claims,
      merchantId:
        typeof claims?.merchant_id === 'string' ? claims.merchant_id : undefined,
      reason: typeof data.reason === 'string' ? data.reason : undefined,
    });
  } catch (error) {
    throw toHttpsError(error);
  }
});