import { Hono } from 'hono';
import type { Env } from '../env';
import { Firestore } from '../firestore';

export interface ExpireResult {
  ok: true;
  total: number;
  at: string;
  expired: Array<{ id: string; from: string }>;
}

const TIMEOUTS: ReadonlyArray<{ status: string; minutes: number }> = [
  { status: 'PLACED', minutes: 5 },
  { status: 'AWAITING_DRIVER', minutes: 10 },
  { status: 'SEARCHING_BIDS', minutes: 10 },
];

/**
 * Cron order expiry (interval 2 menit) — `tech.md` §8.10.
 * Memakai indeks `status + created_at` dan `limit(50)`; setiap order ditulis
 * dengan precondition `updateTime` agar status yang sudah berubah tidak
 * tertimpa.
 */
export async function expireOrders(
  env: Env['Bindings'],
  now: Date = new Date(),
): Promise<ExpireResult> {
  const db = new Firestore(env);
  const expired: Array<{ id: string; from: string }> = [];

  for (const rule of TIMEOUTS) {
    const cutoff = new Date(now.getTime() - rule.minutes * 60_000);
    const rows = await db.runQuery('orders', {
      where: [
        { field: 'status', op: 'EQUAL', value: rule.status },
        { field: 'created_at', op: 'LESS_THAN', value: cutoff },
      ],
      limit: 50,
    });

    for (const row of rows) {
      try {
        await db.commit([
          {
            path: `orders/${row.id}`,
            precondition: row.updateTime,
            mask: ['status', 'expire_reason', 'expired_at', 'updated_at'],
            set: {
              status: 'EXPIRED',
              expire_reason: `${rule.status}_TIMEOUT`,
            },
            serverTime: ['expired_at', 'updated_at'],
          },
        ]);
        expired.push({ id: row.id, from: rule.status });
      } catch {
        // Precondition gagal berarti order sudah berubah status; lanjutkan.
      }
    }
  }

  return { ok: true, total: expired.length, at: now.toISOString(), expired };
}

export const cronRoutes = new Hono<Env>();

cronRoutes.post('/cron/expire-orders', async (c) => {
  const result = await expireOrders(c.env);
  return c.json(result);
});

cronRoutes.get('/cron/expire-orders', async (c) => {
  const result = await expireOrders(c.env);
  return c.json(result);
});

export async function runScheduled(env: Env['Bindings'], cron = ''): Promise<void> {
  try {
    const result = await expireOrders(env);
    console.log(
      JSON.stringify({
        level: 'info',
        cron,
        message: 'expire-orders',
        total: result.total,
      }),
    );
  } catch (error) {
    console.error(
      JSON.stringify({
        level: 'error',
        cron,
        message: error instanceof Error ? error.message : String(error),
      }),
    );
  }
}