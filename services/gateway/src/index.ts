import { Hono } from 'hono';
import { requireAuth, verifyAppCheck } from './auth';
import type { Env } from './env';
import { errorResponse } from './errors';
import { bidRoutes } from './routes/bids';
import { cronRoutes, runScheduled } from './routes/cron';
import { fileRoutes } from './routes/files';
import { publicRoutes } from './routes/public';

const app = new Hono<Env>();

/** CORS policy (`tech.md` §8.1): hanya origin yang terdaftar. */
app.use('*', async (c, next) => {
  const origin = c.req.header('Origin') ?? '';
  const allowed = (c.env.ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
  const corsOrigin = allowed.includes(origin) ? origin : (allowed[0] ?? '*');

  c.header('Access-Control-Allow-Origin', corsOrigin);
  c.header('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
  c.header(
    'Access-Control-Allow-Headers',
    'Authorization, Content-Type, X-Firebase-AppCheck',
  );
  c.header('Vary', 'Origin');

  if (c.req.method === 'OPTIONS') return c.body(null, 204);
  await next();
});

/** Middleware keamanan: App Check + Bearer JWT untuk jalur privat. */
app.use('/upload/*', verifyAppCheck, requireAuth);
app.use('/files/*', verifyAppCheck, requireAuth);
app.use('/orders/*', verifyAppCheck, requireAuth);
app.use('/admin/*', verifyAppCheck, requireAuth);

app.route('/', publicRoutes);
app.route('/', fileRoutes);
app.route('/', bidRoutes);
app.route('/', cronRoutes);

app.get('/health', (c) => c.json({ ok: true, service: 'ce-gateway' }));

app.onError((err, c) => {
  const { status, body } = errorResponse(err);
  return c.json(body, status as 400);
});

interface ScheduledController {
  cron?: string;
  scheduledTime?: number;
}

export default {
  fetch: app.fetch,
  async scheduled(
    controller: ScheduledController,
    env: Env['Bindings'],
  ): Promise<void> {
    await runScheduled(env, controller.cron ?? '');
  },
};