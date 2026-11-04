import { HttpsError } from 'firebase-functions/v2/https';
import { GatewayError, isGatewayError } from './errors';

const CODE_MAP: Record<string, ConstructorParameters<typeof HttpsError>[0]> = {
  UNAUTHENTICATED: 'unauthenticated',
  PERMISSION_DENIED: 'permission-denied',
  INVALID_ARGUMENT: 'invalid-argument',
  ORDER_NOT_FOUND: 'not-found',
  ORDER_TAKEN: 'already-exists',
  INVALID_ORDER_STATE: 'failed-precondition',
  SELF_ORDER: 'permission-denied',
  DRIVER_NOT_FOUND: 'not-found',
  DRIVER_NOT_VERIFIED: 'permission-denied',
  INSUFFICIENT_BALANCE: 'failed-precondition',
  TOO_MANY_JOBS: 'failed-precondition',
  WALLET_NOT_FOUND: 'not-found',
  WALLET_NEGATIVE: 'failed-precondition',
  SECRET_NOT_FOUND: 'not-found',
  PIN_WRONG: 'permission-denied',
  PIN_LOCKED: 'resource-exhausted',
  NOT_ASSIGNED: 'permission-denied',
  COD_LIMIT_EXCEEDED: 'failed-precondition',
  IDEMPOTENCY_CONFLICT: 'already-exists',
};

export function toHttpsError(error: unknown): HttpsError {
  if (isGatewayError(error)) {
    return new HttpsError(
      CODE_MAP[error.code] ?? 'internal',
      error.message,
      error.details,
    );
  }
  if (error instanceof HttpsError) return error;
  console.error(
    JSON.stringify({
      level: 'error',
      message: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
    }),
  );
  return new HttpsError('internal', 'Terjadi kesalahan pada server.');
}

export function requireAuthUid(auth: { uid?: string } | undefined): string {
  if (!auth?.uid) {
    throw new HttpsError('unauthenticated', 'Autentikasi diperlukan.');
  }
  return auth.uid;
}

export { GatewayError };
