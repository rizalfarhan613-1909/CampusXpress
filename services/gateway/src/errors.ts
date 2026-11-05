/** Error domain Gateway yang dipetakan ke respons JSON `{ code }`. */
export class HttpError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message?: string,
  ) {
    super(message ?? code);
    this.name = 'HttpError';
  }
}

export function errorResponse(error: unknown): { status: number; body: { code: string; message?: string } } {
  if (error instanceof HttpError) {
    return { status: error.status, body: { code: error.code, message: error.message } };
  }
  console.error(
    JSON.stringify({
      level: 'error',
      message: error instanceof Error ? error.message : String(error),
    }),
  );
  return { status: 500, body: { code: 'INTERNAL' } };
}