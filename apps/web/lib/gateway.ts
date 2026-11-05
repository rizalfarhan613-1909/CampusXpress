/**
 * Klien Gateway REST Campus Express (`docs/tech.md` §6.1 dan §8).
 * Semua endpoint publik dibaca tanpa kredensial; endpoint tulis memakai
 * Firebase ID Token sebagai Bearer token.
 */

const BASE = process.env.NEXT_PUBLIC_GATEWAY_URL ?? '';

/** True bila `NEXT_PUBLIC_GATEWAY_URL` sudah diisi pada berkas `.env.local`. */
export const gatewayConfigured = BASE.length > 0;

export class GatewayError extends Error {
  constructor(
    message: string,
    readonly status: number,
    /** Kode galat Gateway (`{ code }`) bila tersedia, mis. `INSUFFICIENT_BALANCE`. */
    readonly code: string = 'ERROR',
  ) {
    super(message);
    this.name = 'GatewayError';
  }
}

/**
 * Membaca body galat Gateway `{ code, message }` (`errors.ts` Worker) agar UI
 * dapat menampilkan pesan spesifik. Body non-JSON tetap memakai `HTTP <status>`.
 */
async function readErrorResponse(res: Response): Promise<GatewayError> {
  let code = 'ERROR';
  let message = `HTTP ${res.status}`;
  try {
    const body = (await res.json()) as { code?: unknown; message?: unknown };
    if (typeof body.code === 'string' && body.code.length > 0) code = body.code;
    if (typeof body.message === 'string' && body.message.length > 0) {
      message = body.message;
    }
  } catch {
    // Body bukan JSON; pesan default dipertahankan.
  }
  return new GatewayError(message, res.status, code);
}

/** GET publik ber-cache 30 detik (`docs/tech.md` §6.11). */
export async function getPublic<T>(path: string, signal?: AbortSignal): Promise<T> {
  if (!gatewayConfigured) {
    throw new GatewayError('NEXT_PUBLIC_GATEWAY_URL belum dikonfigurasi.', 0);
  }
  const res = await fetch(`${BASE}${path}`, { signal });
  if (!res.ok) throw await readErrorResponse(res);
  return (await res.json()) as T;
}

/** POST dengan Firebase ID Token. */
export async function postAuthed<T>(
  path: string,
  token: string,
  body: unknown = {},
): Promise<T> {
  if (!gatewayConfigured) {
    throw new GatewayError('NEXT_PUBLIC_GATEWAY_URL belum dikonfigurasi.', 0);
  }
  const res = await fetch(`${BASE}${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw await readErrorResponse(res);
  return (await res.json()) as T;
}
