import { onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { expireOrdersEngine } from './core/expireOrders';
import { getDb } from './core/firestore';
import { toHttpsError } from './core/https';
import { GatewayError } from './core/errors';

/**
 * POST /cron/expire-orders (callable, admin only).
 * Pemicu manual untuk pembersihan order timeout (PLACED 5 mnt / AWAITING 10 mnt).
 */
export const expireOrders = onCall(async (request) => {
  try {
    const claims = request.auth?.token as Record<string, unknown> | undefined;
    const isAdmin = claims?.role === 'admin' || claims?.admin === true;
    if (!isAdmin) {
      throw new GatewayError(
        'PERMISSION_DENIED',
        'Hanya admin yang dapat memicu pembersihan order timeout.',
      );
    }
    return await expireOrdersEngine(getDb());
  } catch (error) {
    throw toHttpsError(error);
  }
});

/**
 * Cron terjadwal tiap 2 menit (tech.md §8.10). Idempoten dan dibatasi `limit`.
 */
export const expireOrdersCron = onSchedule('*/2 * * * *', async () => {
  const result = await expireOrdersEngine(getDb());
  console.log(
    JSON.stringify({
      level: 'info',
      message: 'expire-orders cron selesai',
      ...result,
    }),
  );
});