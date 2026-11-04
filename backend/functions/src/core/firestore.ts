import { getApps, initializeApp } from 'firebase-admin/app';
import {
  getFirestore,
  Timestamp,
  type Firestore,
} from 'firebase-admin/firestore';
import { GatewayError } from './errors';

let cachedDb: Firestore | null = null;

/** Dipakai wrapper Cloud Functions; diinisialisasi sekali per instance. */
export function getDb(): Firestore {
  if (!cachedDb) {
    if (getApps().length === 0) initializeApp();
    cachedDb = getFirestore();
  }
  return cachedDb;
}

export function asDate(value: unknown): Date | null {
  if (value instanceof Date) return value;
  if (value instanceof Timestamp) return value.toDate();
  if (value && typeof value === 'object' && 'toDate' in value) {
    const toDate = (value as { toDate?: unknown }).toDate;
    if (typeof toDate === 'function') {
      const date = (toDate as () => Date).call(value);
      return date instanceof Date ? date : null;
    }
  }
  return null;
}

export function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new GatewayError('INVALID_ARGUMENT', `${field} wajib diisi.`);
  }
  return value.trim();
}

export function optionalString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0
    ? value.trim()
    : undefined;
}
