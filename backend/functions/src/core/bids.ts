import type { DocumentData } from 'firebase-admin/firestore';
import { GatewayError } from './errors';
import {
  BID_MAX_ARRIVAL_MINUTES,
  BID_MAX_PRICE,
  BID_MIN_ARRIVAL_MINUTES,
  BID_MIN_PRICE,
  prettyRupiah,
  toInteger,
} from './money';

/**
 * Fase 5 — Reverse Auction / Bidding Engine.
 *
 * Skema subkoleksi: `orders/{orderId}/bids/{bidId}`.
 * Satu driver memiliki paling banyak satu dokumen bid per order (id deterministik
 * `bid_<driverId>`), sehingga mengubah penawaran bersifat idempoten.
 */
export const BID_COLLECTION = 'bids';
export const BID_STATUSES = ['PENDING', 'ACCEPTED', 'REJECTED'] as const;
export type BidStatus = (typeof BID_STATUSES)[number];

/** Order boleh menerima bid selama belum ada pemenang. */
export const BIDDING_ORDER_STATUSES = new Set([
  'AWAITING_DRIVER',
  'SEARCHING_BIDS',
]);

export interface BidRecord {
  bidId: string;
  orderId: string;
  driverId: string;
  driverName: string;
  driverPhoto: string | null;
  rating: number;
  platNumber: string;
  vehicleModel: string;
  offeredPrice: number;
  estimatedArrivalMinutes: number;
  status: BidStatus;
}

export interface BidProfileInput {
  driverName?: unknown;
  driverPhoto?: unknown;
  rating?: unknown;
  platNumber?: unknown;
  vehicleModel?: unknown;
}

export function hasDriverRole(
  user: DocumentData | undefined,
  profile: DocumentData | undefined,
): boolean {
  if (user?.role === 'driver') return true;
  if (Array.isArray(user?.roles) && user.roles.includes('driver')) return true;
  return profile?.status === 'approved';
}

export function isVerifiedDriver(
  user: DocumentData | undefined,
  profile: DocumentData | undefined,
): boolean {
  if (user?.is_verified === true) return true;
  if (user?.status === 'approved') return true;
  return profile?.status === 'approved';
}

export function sanitizeIdPart(value: string): string {
  const cleaned = value.replace(/[^a-zA-Z0-9_-]/g, '_').slice(0, 120);
  return cleaned.length > 0 ? cleaned : 'unknown';
}

/** Satu bid per driver per order. */
export function bidDocId(driverId: string): string {
  return `bid_${sanitizeIdPart(driverId)}`;
}

export function normalizeOfferedPrice(value: unknown): number {
  const price = toInteger(value) ?? (typeof value === 'string' ? Number(value) : null);
  if (price === null || !Number.isInteger(price)) {
    throw new GatewayError('INVALID_ARGUMENT', 'offeredPrice wajib integer Rupiah.');
  }
  if (price < BID_MIN_PRICE) {
    throw new GatewayError(
      'BID_TOO_LOW',
      `Penawaran minimal ${prettyRupiah(BID_MIN_PRICE)}.`,
      { offeredPrice: price, min: BID_MIN_PRICE },
    );
  }
  if (price > BID_MAX_PRICE) {
    throw new GatewayError(
      'INVALID_ARGUMENT',
      `Penawaran maksimal ${prettyRupiah(BID_MAX_PRICE)}.`,
      { offeredPrice: price, max: BID_MAX_PRICE },
    );
  }
  return price;
}

export function normalizeArrivalMinutes(value: unknown, fallback = 10): number {
  const minutes = toInteger(value) ?? (typeof value === 'string' ? Number(value) : null);
  if (minutes === null || !Number.isInteger(minutes)) return fallback;
  return Math.min(
    Math.max(minutes, BID_MIN_ARRIVAL_MINUTES),
    BID_MAX_ARRIVAL_MINUTES,
  );
}

function readNumber(value: unknown, fallback: number): number {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  return fallback;
}

function readString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

/**
 * Membentuk data bid yang disimpan. Field mengikuti spesifikasi Fase 5
 * (camelCase), ditambah alias snake_case untuk kompatibilitas Gateway.
 */
export function buildBidData(
  input: {
    orderId: string;
    driverId: string;
    offeredPrice: number;
    estimatedArrivalMinutes: number;
    profile: BidProfileInput;
  },
): BidRecord & Record<string, unknown> {
  const driverName = readString(input.profile.driverName) || 'Driver';
  const driverPhotoRaw = readString(input.profile.driverPhoto);
  const rating = readNumber(input.profile.rating, 5);
  const platNumber = readString(input.profile.platNumber);
  const vehicleModel = readString(input.profile.vehicleModel) || 'Motor';

  return {
    bidId: bidDocId(input.driverId),
    orderId: input.orderId,
    driverId: input.driverId,
    driverName,
    driverPhoto: driverPhotoRaw.length > 0 ? driverPhotoRaw : null,
    rating: Math.min(Math.max(rating, 0), 5),
    platNumber,
    vehicleModel,
    offeredPrice: input.offeredPrice,
    estimatedArrivalMinutes: input.estimatedArrivalMinutes,
    status: 'PENDING',
    // Alias snake_case dipakai Gateway REST dan pembacaan Skema Fase 1.
    order_id: input.orderId,
    driver_id: input.driverId,
    driver_name: driverName,
    offered_price: input.offeredPrice,
    estimated_arrival_minutes: input.estimatedArrivalMinutes,
  };
}

export function bidStatus(value: unknown): BidStatus | null {
  const status = String(value ?? '');
  return (BID_STATUSES as readonly string[]).includes(status)
    ? (status as BidStatus)
    : null;
}