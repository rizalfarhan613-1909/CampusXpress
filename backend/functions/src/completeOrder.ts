import { onCall } from 'firebase-functions/v2/https';
import { completeOrderEngine } from './core/completeOrder';
import { getDb, requireNonEmptyString } from './core/firestore';
import { requireAuthUid, toHttpsError } from './core/https';

/**
 * POST /orders/{id}/complete (callable).
 * Driver memasukkan PIN 4 digit; status ARRIVED -> COMPLETED, komisi dipotong.
 */
export const completeOrder = onCall(async (request) => {
  try {
    const driverId = requireAuthUid(request.auth);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const orderId = requireNonEmptyString(data.orderId, 'orderId');

    return await completeOrderEngine(getDb(), {
      driverId,
      orderId,
      inputPin:
        typeof data.inputPin === 'number' || typeof data.inputPin === 'string'
          ? data.inputPin
          : '',
    });
  } catch (error) {
    throw toHttpsError(error);
  }
});
