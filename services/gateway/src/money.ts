/** Rumus komisi terkunci 0,5% dengan minimum Rp 50 (`Monetization.md` §2). */
export const COMMISSION_BPS = 50;
export const MIN_COMMISSION = 50;

/** PRD M06 FR-06.3 — batas transaksi COD (ditegakkan server, bukan klien). */
export const COD_MAX = 200_000;

/**
 * Metode pembayaran order dalam dua bentuk skema yang dipakai repo:
 * `payment_method: 'COD'` (Fase 1) atau `payment.method` (Architecture.md).
 */
export function paymentMethodOf(order: Record<string, unknown>): string {
  const direct = order.payment_method;
  if (typeof direct === 'string' && direct.length > 0) return direct;

  const payment = order.payment;
  if (payment && typeof payment === 'object') {
    const method = (payment as Record<string, unknown>).method;
    if (typeof method === 'string') return method;
  }
  return '';
}

export function computeCommission(
  total: number,
  bps: number = COMMISSION_BPS,
  min: number = MIN_COMMISSION,
): number {
  if (!Number.isInteger(total) || total < 0) {
    throw new Error('computeCommission: total harus integer Rupiah >= 0');
  }
  return Math.max(min, Math.floor((total * bps + 5000) / 10000));
}

export function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let index = 0; index < a.length; index += 1) {
    result |= a.charCodeAt(index) ^ b.charCodeAt(index);
  }
  return result === 0;
}

export function prettyRupiah(amount: number): string {
  return `Rp ${amount.toLocaleString('id-ID')}`;
}