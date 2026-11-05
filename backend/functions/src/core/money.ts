import type { DocumentData } from 'firebase-admin/firestore';
import { GatewayError } from './errors';

/** PRD X2: komisi 0,5% (commissionBps = 50). */
export const COMMISSION_BPS = 50;
export const MIN_COMMISSION = 50;

/** PRD M06 FR-06.3. */
export const COD_MAX = 200_000;

/** PRD M08 FR-08.3. */
export const DRIVER_MIN_BALANCE = 5_000;
export const MAX_ACTIVE_JOBS = 2;

/** Fase 5 — Reverse Auction (Bidding Engine). */
export const BID_MIN_PRICE = 3_000;
export const BID_MAX_PRICE = 500_000;
export const BID_MIN_ARRIVAL_MINUTES = 1;
export const BID_MAX_ARRIVAL_MINUTES = 120;

/** PRD M09 FR-09.3. */
export const PIN_MAX_ATTEMPTS = 5;
export const PIN_LOCK_MS = 10 * 60 * 1000;

export function toInteger(value: unknown): number | null {
  return typeof value === 'number' && Number.isInteger(value) ? value : null;
}

/**
 * PRD X2 / Aturan X1:
 * commission = max(50, round_half_up((subtotal + ongkir) * 0,005)).
 *
 * Semua nilai uang adalah integer Rupiah. Rumus integer di bawah identik dengan
 * round-half-up tanpa risiko floating point:
 *   round(x / 200) = floor((x + 100) / 200)
 */
export function computeCommission(total: number): number {
  if (!Number.isInteger(total) || total < 0) {
    throw new Error('computeCommission: total harus integer Rupiah >= 0');
  }
  return Math.max(MIN_COMMISSION, Math.floor((total + 100) / 200));
}

/**
 * Mengambil dasar komisi (subtotal + ongkir) dari dua bentuk skema yang ada:
 * - skema Fase 1: total_price, delivery_fee (total_price sudah termasuk ongkir)
 * - skema Architecture.md: pricing.{subtotal, deliveryFee, total}
 */
export function getOrderCommissionBase(order: DocumentData): number {
  const pricing = order.pricing;
  if (pricing && typeof pricing === 'object') {
    const pricingMap = pricing as Record<string, unknown>;
    const subtotal = toInteger(pricingMap.subtotal);
    const deliveryFee =
      toInteger(pricingMap.deliveryFee) ?? toInteger(pricingMap.delivery_fee);
    const total =
      toInteger(pricingMap.total) ??
      (subtotal !== null ? subtotal + (deliveryFee ?? 0) : null);
    if (total !== null && total >= 0) return total;
  }

  const subtotal = toInteger(order.subtotal);
  const deliveryFee =
    toInteger(order.delivery_fee) ?? toInteger(order.deliveryFee) ?? 0;
  if (subtotal !== null) return subtotal + deliveryFee;

  return toInteger(order.total_price) ?? toInteger(order.totalPrice) ?? 0;
}

export function getOrderTotal(order: DocumentData): number {
  return getOrderCommissionBase(order);
}

export function assertCodPolicy(order: DocumentData): void {
  const payment = order.payment;
  const method =
    order.payment_method ??
    (payment && typeof payment === 'object'
      ? (payment as Record<string, unknown>).method
      : undefined);
  const total = getOrderTotal(order);

  if (method === 'COD' && total > COD_MAX) {
    throw new GatewayError(
      'COD_LIMIT_EXCEEDED',
      `Transaksi COD maksimal Rp ${COD_MAX.toLocaleString('id-ID')}; gunakan QRIS_STATIC.`,
      { total, max: COD_MAX },
    );
  }
}

export function prettyRupiah(amount: number): string {
  return `Rp ${amount.toLocaleString('id-ID')}`;
}
