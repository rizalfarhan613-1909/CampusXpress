import { onCall } from 'firebase-functions/v2/https';
import { finalizeOrderEngine } from './core/finalizeOrder';
import { getDb, requireNonEmptyString } from './core/firestore';
import { requireAuthUid, toHttpsError } from './core/https';

/**
 * POST /orders/{id}/finalize (callable).
 * Gateway menghitung ulang ongkir + total dari matriks zona (X3) lalu menandai
 * order `finalized=true` atau `EXPIRED` bila harga klien tidak cocok.
 */
export const finalizeOrder = onCall(async (request) => {
  try {
    const uid = requireAuthUid(request.auth);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const orderId = requireNonEmptyString(data.orderId, 'orderId');
    const claims = request.auth?.token as Record<string, unknown> | undefined;
    const isAdmin = claims?.role === 'admin' || claims?.admin === true;

    return await finalizeOrderEngine(getDb(), { orderId, actorId: uid, isAdmin });
  } catch (error) {
    throw toHttpsError(error);
  }
});