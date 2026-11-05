import { onCall } from 'firebase-functions/v2/https';
import { getDb, requireNonEmptyString } from './core/firestore';
import { requireAuthUid, toHttpsError } from './core/https';
import { submitBidEngine } from './core/submitBid';

function optionalNumber(value: unknown): number | undefined {
  if (value === undefined || value === null || value === '') return undefined;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : undefined;
}

function optionalText(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0
    ? value.trim()
    : undefined;
}

/**
 * POST /orders/{id}/bids (callable) — Fase 5.
 * Driver mengirim penawaran harga (Reverse Auction).
 */
export const submitBid = onCall(async (request) => {
  try {
    const driverId = requireAuthUid(request.auth);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const orderId = requireNonEmptyString(data.orderId, 'orderId');

    return await submitBidEngine(getDb(), {
      driverId,
      orderId,
      offeredPrice: Number(data.offeredPrice),
      estimatedArrivalMinutes: optionalNumber(data.estimatedArrivalMinutes),
      driverName: optionalText(data.driverName),
      driverPhoto: optionalText(data.driverPhoto),
      rating: optionalNumber(data.rating),
      platNumber: optionalText(data.platNumber),
      vehicleModel: optionalText(data.vehicleModel),
    });
  } catch (error) {
    throw toHttpsError(error);
  }
});