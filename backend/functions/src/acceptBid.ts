import { onCall } from 'firebase-functions/v2/https';
import { acceptBidEngine } from './core/acceptBid';
import { getDb, requireNonEmptyString } from './core/firestore';
import { requireAuthUid, toHttpsError } from './core/https';

/**
 * POST /orders/{id}/bids/{bidId}/accept (callable) — Fase 5.
 * Konsumen menerima satu penawaran secara atomik.
 */
export const acceptBid = onCall(async (request) => {
  try {
    const consumerId = requireAuthUid(request.auth);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const orderId = requireNonEmptyString(data.orderId, 'orderId');
    const bidId = requireNonEmptyString(data.bidId, 'bidId');

    return await acceptBidEngine(getDb(), { consumerId, orderId, bidId });
  } catch (error) {
    throw toHttpsError(error);
  }
});