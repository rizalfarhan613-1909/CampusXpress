/**
 * Error domain Gateway.
 *
 * Kode error dipakai oleh wrapper Cloud Functions untuk memetakan ke HttpsError.
 * Pesan sengaja berbahasa Indonesia karena ditampilkan langsung di klien.
 */
export type GatewayErrorCode =
  | 'UNAUTHENTICATED'
  | 'PERMISSION_DENIED'
  | 'INVALID_ARGUMENT'
  | 'ORDER_NOT_FOUND'
  | 'ORDER_TAKEN'
  | 'INVALID_ORDER_STATE'
  | 'SELF_ORDER'
  | 'DRIVER_NOT_FOUND'
  | 'DRIVER_NOT_VERIFIED'
  | 'INSUFFICIENT_BALANCE'
  | 'TOO_MANY_JOBS'
  | 'WALLET_NOT_FOUND'
  | 'WALLET_NEGATIVE'
  | 'SECRET_NOT_FOUND'
  | 'PIN_WRONG'
  | 'PIN_LOCKED'
  | 'NOT_ASSIGNED'
  | 'COD_LIMIT_EXCEEDED'
  | 'IDEMPOTENCY_CONFLICT'
  | 'BID_NOT_FOUND'
  | 'BID_TOO_LOW'
  | 'BID_ALREADY_EXISTS'
  | 'ORDER_NOT_OWNER'
  | 'ORDER_NOT_BIDDING';

export class GatewayError extends Error {
  readonly code: GatewayErrorCode;
  readonly details?: Record<string, unknown>;

  constructor(
    code: GatewayErrorCode,
    message: string,
    details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = 'GatewayError';
    this.code = code;
    this.details = details;
  }
}

export function isGatewayError(error: unknown): error is GatewayError {
  return error instanceof GatewayError;
}
