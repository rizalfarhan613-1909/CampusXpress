import type { MiddlewareHandler } from 'hono';
import { createRemoteJWKSet, jwtVerify } from 'jose';
import type { Caller, Env } from './env';
import { HttpError } from './errors';

const FIREBASE_JWKS = createRemoteJWKSet(
  new URL(
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
  ),
);

const APP_CHECK_JWKS = createRemoteJWKSet(
  new URL('https://firebaseappcheck.googleapis.com/v1/jwks'),
);

/**
 * Verifikasi Firebase ID Token (`docs/tech.md` §8.2).
 * Domain kampus diwajibkan untuk akun non-admin.
 */
export async function verifyIdToken(
  token: string,
  projectId: string,
): Promise<Caller> {
  const { payload } = await jwtVerify(token, FIREBASE_JWKS, {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
  });

  if (!payload.sub) throw new HttpError(403, 'NO_SUBJECT');

  const email = String(payload.email ?? '');
  const isAdmin = payload.admin === true || payload.role === 'admin';
  if (!isAdmin) {
    if (payload.email_verified !== true) {
      throw new HttpError(403, 'EMAIL_NOT_VERIFIED');
    }
    if (!/@mhs\.uin\.ac\.id$/i.test(email)) {
      throw new HttpError(403, 'DOMAIN_NOT_ALLOWED');
    }
  }
  if (payload.suspended === true) throw new HttpError(403, 'SUSPENDED');

  return {
    uid: payload.sub,
    email,
    email_verified: payload.email_verified === true,
    admin: isAdmin,
    adminScope: Array.isArray(payload.adminScope)
      ? (payload.adminScope as string[])
      : undefined,
    driver: payload.driver === true,
    merchantId:
      typeof payload.merchantId === 'string' ? payload.merchantId : undefined,
    suspended: false,
  };
}

/** Middleware Authorization Bearer JWT. */
export const requireAuth: MiddlewareHandler<Env> = async (c, next) => {
  const header = c.req.header('Authorization') ?? '';
  if (!header.startsWith('Bearer ')) {
    throw new HttpError(401, 'NO_TOKEN', 'Header Authorization Bearer wajib diisi.');
  }
  const caller = await verifyIdToken(header.slice(7), c.env.FIREBASE_PROJECT_ID);
  c.set('caller', caller);
  await next();
};

/**
 * Middleware X-Firebase-AppCheck.
 *
 * `APP_CHECK_ENFORCE=true` menolak token yang tidak valid/absen;
 * `DISABLE_APP_CHECK=true` melewati pemeriksaan (hanya untuk pengujian lokal).
 */
export const verifyAppCheck: MiddlewareHandler<Env> = async (c, next) => {
  if (c.env.DISABLE_APP_CHECK === 'true') {
    await next();
    return;
  }

  const token = c.req.header('X-Firebase-AppCheck') ?? '';
  const enforce = c.env.APP_CHECK_ENFORCE === 'true';

  let valid = false;
  if (token.length > 0) {
    try {
      const audience = c.env.FIREBASE_PROJECT_NUMBER
        ? `projects/${c.env.FIREBASE_PROJECT_NUMBER}`
        : undefined;
      await jwtVerify(token, APP_CHECK_JWKS, audience ? { audience } : {});
      valid = true;
    } catch {
      valid = false;
    }
  }

  if (!valid && enforce) {
    throw new HttpError(401, 'APP_CHECK_REQUIRED', 'App Check tidak valid.');
  }
  await next();
};