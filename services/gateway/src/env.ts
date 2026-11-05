/**
 * Bindings & tipe Worker Trusted Gateway (`docs/tech.md` §8).
 *
 * Tipe R2 didefinisikan minimal agar proyek dapat di-typecheck tanpa paket
 * `@cloudflare/workers-types`; kontraknya identik untuk `get`, `put`, `delete`.
 */

export interface R2ObjectBody {
  body: ReadableStream;
  httpMetadata?: { contentType?: string; cacheControl?: string };
  size?: number;
}

export interface R2PutOptions {
  httpMetadata?: { contentType?: string; cacheControl?: string };
}

export interface R2Bucket {
  get(key: string): Promise<R2ObjectBody | null>;
  put(
    key: string,
    value: ArrayBuffer | Uint8Array | ReadableStream | string,
    options?: R2PutOptions,
  ): Promise<unknown>;
  delete(key: string): Promise<void>;
}

export interface Caller {
  uid: string;
  email: string;
  email_verified: boolean;
  admin?: boolean;
  adminScope?: string[];
  driver?: boolean;
  merchantId?: string;
  suspended?: boolean;
}

export interface Env {
  Bindings: {
    FIREBASE_PROJECT_ID: string;
    FIREBASE_PROJECT_NUMBER?: string;
    ALLOWED_ORIGINS?: string;
    FIREBASE_SERVICE_ACCOUNT_JSON?: string;
    URL_SIGNING_KEY?: string;
    R2_ACCOUNT_ID?: string;
    R2_ACCESS_KEY_ID?: string;
    R2_SECRET_ACCESS_KEY?: string;
    R2_PUBLIC_DOMAIN?: string;
    R2_BUCKET_NAME?: string;
    R2_PRIVATE_BUCKET_NAME?: string;
    PUBLIC_BUCKET: R2Bucket;
    PRIVATE_BUCKET: R2Bucket;
    APP_CHECK_ENFORCE?: string;
    DISABLE_APP_CHECK?: string;
  };
  Variables: {
    caller: Caller;
  };
}