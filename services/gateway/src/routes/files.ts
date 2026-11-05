import { Hono } from 'hono';
import type { Env } from '../env';
import { HttpError } from '../errors';
import {
  MAX_UPLOAD_BYTES,
  isUploadKind,
  presignGet,
  signFilePath,
  validateUpload,
  verifyFilePath,
} from '../r2';

export const fileRoutes = new Hono<Env>();

const PUBLIC_KINDS = new Set(['profiles', 'products']);

function keyFromUrl(url: string, prefix: string): string {
  const pathname = new URL(url).pathname;
  return decodeURIComponent(pathname.slice(prefix.length));
}

function visibilityFor(kind: string): 'public' | 'private' {
  return PUBLIC_KINDS.has(kind) ? 'public' : 'private';
}

/**
 * POST /upload/:kind — validasi magic bytes + batas WebP ≤ 80 KB, lalu simpan
 * ke Cloudflare R2 (public bucket untuk profil/produk, private untuk bukti QRIS
 * dan lampiran chat).
 */
fileRoutes.post('/upload/:kind', async (c) => {
  const kind = c.req.param('kind');
  if (!isUploadKind(kind)) {
    throw new HttpError(404, 'INVALID_KIND', `Kind unggahan tidak dikenal: ${kind}`);
  }
  const caller = c.get('caller');

  let bytes: Uint8Array;
  let fileName: string;
  const contentType = c.req.header('Content-Type') ?? '';
  if (contentType.includes('multipart/form-data')) {
    const form = await c.req.formData();
    const file = form.get('file');
    if (!(file instanceof File)) {
      throw new HttpError(400, 'NO_FILE', 'Field "file" wajib diisi.');
    }
    bytes = new Uint8Array(await file.arrayBuffer());
    fileName = file.name || `${kind}.webp`;
  } else {
    bytes = new Uint8Array(await c.req.arrayBuffer());
    fileName = `${kind}.webp`;
  }

  const validated = validateUpload(kind, bytes, fileName);
  const key = `${kind}/${caller.uid}-${crypto.randomUUID()}.${validated.extension}`;
  const visibility = visibilityFor(kind);
  const bucket =
    visibility === 'public' ? c.env.PUBLIC_BUCKET : c.env.PRIVATE_BUCKET;

  await bucket.put(key, bytes, {
    httpMetadata: {
      contentType: validated.contentType,
      cacheControl:
        visibility === 'public'
          ? 'public, max-age=31536000, immutable'
          : 'private, no-store',
    },
  });

  const publicDomain = c.env.R2_PUBLIC_DOMAIN?.replace(/\/+$/, '');
  const url =
    visibility === 'public' && publicDomain ? `${publicDomain}/${key}` : null;

  return c.json(
    {
      key,
      url,
      contentType: validated.contentType,
      size: validated.size,
      maxBytes: MAX_UPLOAD_BYTES,
    },
    201,
  );
});

/**
 * GET /files/* — URL bertanda tangan 5 menit (via `@aws-sdk/s3-request-presigner`).
 * Pemilik berkas (`<kind>/<uid>-...`) atau admin berhak meminta tautan.
 */
fileRoutes.get('/files/*', async (c) => {
  const caller = c.get('caller');
  const key = keyFromUrl(c.req.url, '/files/');
  if (!key || key.includes('..')) {
    throw new HttpError(400, 'INVALID_KEY', 'Kunci berkas tidak valid.');
  }

  const [kind] = key.split('/');
  const ownerPrefix = `${kind}/${caller.uid}-`;
  const owner = key.startsWith(ownerPrefix);
  if (!owner && !caller.admin) {
    throw new HttpError(403, 'FORBIDDEN', 'Berkas ini bukan milik Anda.');
  }

  const visibility = visibilityFor(kind);
  const url = await presignGet(c.env, key, visibility);

  const secret = c.env.URL_SIGNING_KEY;
  let path: string | null = null;
  if (secret) {
    const exp = Math.floor(Date.now() / 1000) + 300;
    const sig = await signFilePath(secret, key, exp);
    path = `/f/${encodeURIComponent(key)}?exp=${exp}&sig=${sig}`;
  }

  return c.json({ url, path, expiresIn: 300 });
});

/**
 * GET /f/* — pengalihan bertanda tangan (tanpa Bearer) ke URL R2 5 menit.
 * Tautan hanya valid bila `exp` belum lewat dan `sig` cocok.
 */
fileRoutes.get('/f/*', async (c) => {
  const key = keyFromUrl(c.req.url, '/f/');
  const secret = c.env.URL_SIGNING_KEY;
  if (!secret) {
    throw new HttpError(500, 'SIGNING_NOT_CONFIGURED', 'URL_SIGNING_KEY belum diisi.');
  }
  if (!key || key.includes('..')) {
    throw new HttpError(400, 'INVALID_KEY', 'Kunci berkas tidak valid.');
  }

  const exp = Number(c.req.query('exp'));
  const sig = c.req.query('sig') ?? '';
  const valid = await verifyFilePath(secret, key, exp, sig);
  if (!valid) {
    throw new HttpError(403, 'BAD_SIGNATURE', 'Tautan kedaluwarsa atau tanda tangan salah.');
  }

  const [kind] = key.split('/');
  const url = await presignGet(c.env, key, visibilityFor(kind));
  return c.redirect(url, 302);
});