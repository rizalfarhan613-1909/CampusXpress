import { HttpsError, onCall } from 'firebase-functions/v2/https';
import {
  compareCoordinates,
  estimateFare as estimateFareEngine,
  type Coordinate,
} from './core/osrmRouting';
import { requireAuthUid, toHttpsError } from './core/https';

function readCoordinate(value: unknown, field: string): Coordinate {
  if (!value || typeof value !== 'object') {
    throw new HttpsError('invalid-argument', `${field} wajib berisi koordinat.`);
  }
  const map = value as Record<string, unknown>;
  const latitude = Number(map.latitude ?? map.lat);
  const longitude = Number(map.longitude ?? map.lng ?? map.lon);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    throw new HttpsError('invalid-argument', `${field} tidak valid.`);
  }
  return { latitude, longitude };
}

/**
 * POST /fare/estimate (callable) — Fase 5.
 * Menghitung jarak jalan OSRM + rentang harga rekomendasi.
 */
export const estimateFare = onCall(async (request) => {
  try {
    requireAuthUid(request.auth);
    const data = (request.data ?? {}) as Record<string, unknown>;
    const from = readCoordinate(data.from, 'from');
    const to = readCoordinate(data.to, 'to');
    const estimate = await estimateFareEngine(from, to, {
      baseUrl: process.env.OSRM_BASE_URL,
    });
    return { ...estimate, pairKey: compareCoordinates(from, to) };
  } catch (error) {
    throw toHttpsError(error);
  }
});