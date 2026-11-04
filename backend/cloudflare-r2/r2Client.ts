import { randomUUID } from 'node:crypto';
import { extname } from 'node:path';
import {
  DeleteObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';

export const R2_FOLDERS = ['profiles', 'products', 'qris-proofs', 'chat'] as const;

export type R2Folder = (typeof R2_FOLDERS)[number];
export type ImageExtension = 'webp' | 'jpg' | 'png';
export type R2ErrorCode =
  | 'MISSING_ENV'
  | 'INVALID_FOLDER'
  | 'INVALID_KEY'
  | 'INVALID_EXTENSION'
  | 'INVALID_CONTENT'
  | 'EXTENSION_MISMATCH'
  | 'EMPTY_FILE'
  | 'TOO_LARGE';

const ALLOWED_EXTENSIONS: readonly string[] = ['webp', 'jpg', 'png'];
const MAX_IMAGE_BYTES = 85 * 1024;

const CONTENT_TYPES: Record<ImageExtension, string> = {
  webp: 'image/webp',
  jpg: 'image/jpeg',
  png: 'image/png',
};

const FOLDER_POLICY: Record<R2Folder, { visibility: 'public' | 'private'; cacheControl: string }> = {
  profiles: { visibility: 'public', cacheControl: 'public, max-age=31536000, immutable' },
  products: { visibility: 'public', cacheControl: 'public, max-age=31536000, immutable' },
  'qris-proofs': { visibility: 'private', cacheControl: 'private, no-store' },
  chat: { visibility: 'private', cacheControl: 'private, no-store' },
};

export class R2UploadError extends Error {
  readonly code: R2ErrorCode;

  constructor(code: R2ErrorCode, message: string) {
    super(message);
    this.name = 'R2UploadError';
    this.code = code;
  }
}

export interface R2Config {
  accountId: string;
  accessKeyId: string;
  secretAccessKey: string;
  bucket: string;
  privateBucket: string;
  publicDomain: string;
}

export interface UploadImageInput {
  folder: R2Folder;
  fileName: string;
  body: Uint8Array;
}

export interface UploadImageResult {
  key: string;
  bucket: string;
  url: string | null;
  contentType: string;
  size: number;
}

function required(env: NodeJS.ProcessEnv, key: string): string {
  const value = env[key]?.trim();
  if (!value) {
    throw new R2UploadError('MISSING_ENV', `Missing environment variable: ${key}`);
  }
  return value;
}

function normalizeDomain(value: string): string {
  const withScheme = /^https?:\/\//i.test(value) ? value : `https://${value}`;
  return withScheme.replace(/\/+$/, '');
}

function isR2Folder(value: string): value is R2Folder {
  return (R2_FOLDERS as readonly string[]).includes(value);
}

function sniffImageExtension(bytes: Uint8Array): ImageExtension | null {
  if (
    bytes.length >= 12 &&
    bytes[0] === 0x52 &&
    bytes[1] === 0x49 &&
    bytes[2] === 0x46 &&
    bytes[3] === 0x46 &&
    bytes[8] === 0x57 &&
    bytes[9] === 0x45 &&
    bytes[10] === 0x42 &&
    bytes[11] === 0x50
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

export function validateImage(fileName: string, body: Uint8Array): ImageExtension {
  if (body.byteLength === 0) {
    throw new R2UploadError('EMPTY_FILE', 'File is empty');
  }

  if (body.byteLength > MAX_IMAGE_BYTES) {
    throw new R2UploadError('TOO_LARGE', `File exceeds ${MAX_IMAGE_BYTES} bytes`);
  }

  const extension = extname(fileName).toLowerCase().replace(/^\./, '');
  if (!ALLOWED_EXTENSIONS.includes(extension)) {
    throw new R2UploadError(
      'INVALID_EXTENSION',
      'Only .webp, .jpg, and .png files are allowed',
    );
  }

  const sniffed = sniffImageExtension(body);
  if (!sniffed) {
    throw new R2UploadError(
      'INVALID_CONTENT',
      'File content is not a valid WebP, JPEG, or PNG image',
    );
  }

  if (sniffed !== extension) {
    throw new R2UploadError(
      'EXTENSION_MISMATCH',
      `Extension .${extension} does not match file content (${sniffed})`,
    );
  }

  return sniffed;
}

export function loadR2Config(env: NodeJS.ProcessEnv = process.env): R2Config {
  const bucket = required(env, 'R2_BUCKET_NAME');

  return {
    accountId: required(env, 'R2_ACCOUNT_ID'),
    accessKeyId: required(env, 'R2_ACCESS_KEY_ID'),
    secretAccessKey: required(env, 'R2_SECRET_ACCESS_KEY'),
    bucket,
    privateBucket: env.R2_PRIVATE_BUCKET_NAME?.trim() || bucket,
    publicDomain: normalizeDomain(required(env, 'R2_PUBLIC_DOMAIN')),
  };
}

export function createR2Client(config: R2Config): S3Client {
  return new S3Client({
    region: 'auto',
    endpoint: `https://${config.accountId}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: config.accessKeyId,
      secretAccessKey: config.secretAccessKey,
    },
    forcePathStyle: true,
    requestChecksumCalculation: 'WHEN_REQUIRED',
    responseChecksumValidation: 'WHEN_REQUIRED',
  });
}

export class R2Uploader {
  constructor(
    private readonly client: S3Client,
    private readonly config: R2Config,
  ) {}

  async uploadImage(input: UploadImageInput): Promise<UploadImageResult> {
    if (!isR2Folder(input.folder)) {
      throw new R2UploadError('INVALID_FOLDER', `Unknown folder: ${String(input.folder)}`);
    }

    const extension = validateImage(input.fileName, input.body);
    const policy = FOLDER_POLICY[input.folder];
    const bucket = policy.visibility === 'public' ? this.config.bucket : this.config.privateBucket;
    const key = `${input.folder}/${randomUUID()}.${extension}`;

    await this.client.send(
      new PutObjectCommand({
        Bucket: bucket,
        Key: key,
        Body: input.body,
        ContentType: CONTENT_TYPES[extension],
        CacheControl: policy.cacheControl,
        ContentLength: input.body.byteLength,
      }),
    );

    return {
      key,
      bucket,
      url: policy.visibility === 'public' ? `${this.config.publicDomain}/${key}` : null,
      contentType: CONTENT_TYPES[extension],
      size: input.body.byteLength,
    };
  }

  async deleteObject(key: string): Promise<void> {
    const folder = key.split('/')[0] ?? '';
    if (!key || key.startsWith('/') || key.includes('..') || !isR2Folder(folder)) {
      throw new R2UploadError('INVALID_KEY', `Invalid object key: ${key}`);
    }

    const policy = FOLDER_POLICY[folder];
    const bucket = policy.visibility === 'public' ? this.config.bucket : this.config.privateBucket;

    await this.client.send(
      new DeleteObjectCommand({
        Bucket: bucket,
        Key: key,
      }),
    );
  }
}

export function createR2Uploader(env: NodeJS.ProcessEnv = process.env): R2Uploader {
  const config = loadR2Config(env);
  return new R2Uploader(createR2Client(config), config);
}
