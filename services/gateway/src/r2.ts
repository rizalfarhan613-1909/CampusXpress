import { GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import type { Env } from './env';
import { HttpError } from './errors';

export const UPLOAD_KINDS = ['profiles', 'products', 'qris-proofs', 'chat'] as const;
export type UploadKind = (typeof UPLOAD_KINDS)[number];

/** Batas WebP setelah kompresi klien (Monetization/Rules: ≤ 80 KB). */
export const MAX_UPLOAD_BYTES = 80 * 1024;
export const SIGNED_URL_TTL_SECONDS = 300;

export type ImageExtension = 'webp' | 'jpg' | 'png';

const CONTENT_TYPES: Record<ImageExtension, string> = {
  webp: 'image/webp',
  jpg: 'image/jpeg',
  png: 'image/png',
};

export function isUploadKind(value: string): value is UploadKind {
  return (UPLOAD_KINDS as readonly string[]).includes(value);
}

export function sniffImage(bytes: Uint8Array): ImageExtension | null {
  if (
    bytes.length >= 12 &&
    bytes[0] === 0x52 && // R
    bytes[1] === 0x49 && // I
    bytes[2] === 0x46 && // F
    bytes[3] === 0x46 && // F
    bytes[8] === 0x57 && // W
    bytes[9] === 0x45 && // E
    bytes[10] === 0x42 && // B
    bytes[11] === 0x50 // P
  ) {
    return 'webp';
  }
  if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return 'jpg';
  }
  if (
    bytes.length >= 8 &&
    bytes[0] === 0x89 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x4e &&
    bytes[3] === 0x47 &&
    bytes[4] === 0x0d &&
    bytes[5] === 0x0a &&
    bytes[6] === 0x1a &&
    bytes[7] === 0x0a
  ) {
    return 'png';
  }
  return null;
}

export interface ValidatedUpload {
  extension: ImageExtension;
  contentType: string;
  size: number;
}

/**
 * Validasi unggahan: magic bytes + batas 80 KB. Klien (mobile) sudah
 * mengompresi ke WebP lewat `webp_compress.dart`; Gateway memverifikasi ulang
 * agar tidak ada berkas > 80 KB yang masuk R2.
 */
export function validateUpload(
  kind: string,
  bytes: Uint8Array,
  fileName: string,
): ValidatedUpload {
  if (!isUploadKind(kind)) {
    throw new HttpError(404, 'INVALID_KIND', `Kind unggahan tidak dikenal: ${kind}`);
  }
  if (bytes.byteLength === 0) {
    throw new HttpError(400, 'EMPTY_FILE', 'Berkas kosong.');
  }
  if (bytes.byteLength > MAX_UPLOAD_BYTES) {
    throw new HttpError(
      413,
      'IMAGE_TOO_LARGE',
      `Berkas melebihi ${Math.floor(MAX_UPLOAD_BYTES / 1024)} KB setelah kompresi.`,
    );
  }

  const sniffed = sniffImage(bytes);
  if (!sniffed) {
    throw new HttpError(415, 'INVALID_CONTENT', 'Isi berkas bukan gambar WebP/JPEG/PNG.');
  }

  const extension = fileName.includes('.')
    ? (fileName.split('.').pop() ?? '').toLowerCase()
    : sniffed;
  if (extension && extension !== sniffed && ['webp', 'jpg', 'png', 'jpeg'].includes(extension)) {
    throw new HttpError(400, 'EXTENSION_MISMATCH', 'Ekstensi tidak cocok dengan isi berkas.');
  }

  return {
    extension: sniffed,
    contentType: CONTENT_TYPES[sniffed],
    size: bytes.byteLength,
  };
}

export function r2BucketName(
  env: Env['Bindings'],
  visibility: 'public' | 'private',
): string {
  if (visibility === 'public') {
    return env.R2_BUCKET_NAME?.trim() || 'ce-public';
  }
  return env.R2_PRIVATE_BUCKET_NAME?.trim() || env.R2_BUCKET_NAME?.trim() || 'ce-private';
}

function createS3Client(env: Env['Bindings']): S3Client {
  if (!env.R2_ACCOUNT_ID || !env.R2_ACCESS_KEY_ID || !env.R2_SECRET_ACCESS_KEY) {
    throw new HttpError(500, 'R2_NOT_CONFIGURED', 'Kredensial R2 belum diisi.');
  }
  return new S3Client({
    region: 'auto',
    endpoint: `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: env.R2_ACCESS_KEY_ID,
      secretAccessKey: env.R2_SECRET_ACCESS_KEY,
    },
    forcePathStyle: true,
  });
}

/** URL bertanda tangan 5 menit via `@aws-sdk/s3-request-presigner`. */
export async function presignGet(
  env: Env['Bindings'],
  key: string,
  visibility: 'public' | 'private' = 'private',
): Promise<string> {
  const client = createS3Client(env);
  const command = new GetObjectCommand({
    Bucket: r2BucketName(env, visibility),
    Key: key,
  });
  return getSignedUrl(client, command, { expiresIn: SIGNED_URL_TTL_SECONDS });
}

async function hmacHex(secret: string, data: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(data),
  );
  return [...new Uint8Array(signature)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

export async function signFilePath(
  secret: string,
  key: string,
  exp: number,
): Promise<string> {
  return hmacHex(secret, `${key}.${exp}`);
}

export async function verifyFilePath(
  secret: string,
  key: string,
  exp: number,
  signature: string,
): Promise<boolean> {
  if (!Number.isFinite(exp) || exp < Date.now() / 1000) return false;
  const expected = await hmacHex(secret, `${key}.${exp}`);
  if (expected.length !== signature.length) return false;
  let result = 0;
  for (let index = 0; index < expected.length; index += 1) {
    result |= expected.charCodeAt(index) ^ signature.charCodeAt(index);
  }
  return result === 0;
}