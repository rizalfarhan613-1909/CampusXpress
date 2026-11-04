import { onCall } from 'firebase-functions/v2/https';
import { claimOrderEngine } from './core/claimOrder';
import { getDb } from './core/firestore';
import { requireNonEmptyString } from './core/firestore';
import { requireAuthUid, toHttpsError } from './core/https';

/**
 * POST /orders/{id}/claim (callable).
 * Driver mengklaim order AWAITING_DRIVER -> CLAIMED secara atomik.
 */
export const claimOrder = onCall(async (request) => {
  try {
    const driverId = requireAuthUid(request.auth);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const orderId = requireNonEmptyString(data.orderId, 'orderId');

    return await claimOrderEngine(getDb(), { driverId, orderId });
  } catch (error) {
    throw toHttpsError(error);
  }
});
