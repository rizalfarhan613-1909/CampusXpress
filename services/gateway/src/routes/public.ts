import { Hono } from 'hono';
import type { Env } from '../env';
import { Firestore, type FirestoreDoc } from '../firestore';

export const publicRoutes = new Hono<Env>();

/** Header edge cache wajib (`tech.md` §8.9, Fase 5). */
const CACHE_HEADERS = {
  'Cache-Control': 'public, max-age=30, s-maxage=30',
  'Access-Control-Allow-Origin': '*',
} as const;

async function safeList(
  env: Env['Bindings'],
  collection: string,
  limit: number,
): Promise<FirestoreDoc[]> {
  try {
    return await new Firestore(env).listLatest(collection, limit);
  } catch {
    return [];
  }
}

async function safeDoc(
  env: Env['Bindings'],
  path: string,
): Promise<Record<string, unknown> | null> {
  try {
    const doc = await new Firestore(env).get(path);
    return doc ? doc.data : null;
  } catch {
    return null;
  }
}

publicRoutes.get('/public/pings', async (c) => {
  const rows = await safeList(c.env, 'salesPings', 8);
  const pings = rows.map((row) => ({
    id: row.id,
    label: String(row.data.label ?? ''),
    place: String(row.data.place ?? ''),
  }));
  return c.json({ pings }, 200, CACHE_HEADERS);
});

publicRoutes.get('/public/stats', async (c) => {
  const data = await safeDoc(c.env, 'stats/campus');
  return c.json(
    {
      stats: {
        orders: Number(data?.orders ?? 0),
        drivers: Number(data?.drivers ?? 0),
        merchants: Number(data?.merchants ?? 0),
        avgRating: Number(data?.avg_rating ?? data?.avgRating ?? 0),
      },
    },
    200,
    CACHE_HEADERS,
  );
});

publicRoutes.get('/public/reviews', async (c) => {
  const rows = await safeList(c.env, 'reviews', 6);
  const reviews = rows.map((row) => ({
    id: row.id,
    rating: Number(row.data.rating ?? 5),
    comment: String(row.data.comment ?? row.data.text ?? ''),
    author: String(row.data.author ?? row.data.consumer_name ?? 'Mahasiswa'),
  }));
  return c.json({ reviews }, 200, CACHE_HEADERS);
});