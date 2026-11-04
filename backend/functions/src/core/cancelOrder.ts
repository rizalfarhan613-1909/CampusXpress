import {
  FieldValue,
  type DocumentData,
  type DocumentSnapshot,
  type Firestore,
} from 'firebase-admin/firestore';
import { GatewayError } from './errors';
import { toInteger } from './money';

export type CancelActorRole = 'consumer' | 'driver' | 'merchant' | 'admin';

export interface CancelOrderInput {
  orderId: string;
  actorId: string;
  actorRole: CancelActorRole;
  /** Custom claims Firebase; dipakai untuk verifikasi admin/merchant. */
  adminClaims?: Record<string, unknown>;
  /** merchantId hasil resolusi (fallback ke claim merchant_id). */
  merchantId?: string;
  reason?: string;
  now?: Date;
}

export interface CancelOrderResult {
  ok: true;
  orderId: string;
  status: 'CANCELLED' | 'AWAITING_DRIVER';
  cancelledBy: string;
  cancelledByRole: CancelActorRole;
  strikeApplied: boolean;
  freeCancelRemaining: number | null;
}

/** Rules.md §7: konsumen gratis 2× per hari setelah klaim, sebelum AT_PICKUP. */
export const FREE_CANCELS_PER_DAY = 2;

const TERMINAL_STATUSES = new Set(['COMPLETED', 'CANCELLED', 'EXPIRED']);
const CONSUMER_FREE_STATUSES = new Set([
  'PLACED',
  'ACCEPTED',
  'READY',
  'AWAITING_DRIVER',
]);
const DRIVER_ACTIVE_STATUSES = new Set([
  'CLAIMED',
  'AT_PICKUP',
  'ON_DELIVERY',
  'ARRIVED',
]);

function todayKey(now: Date): string {
  return now.toISOString().slice(0, 10);
}

function hasAdminClaim(claims: Record<string, unknown> | undefined): boolean {
  return claims?.role === 'admin' || claims?.admin === true;
}

function readStrikeCount(user: DocumentData | undefined): number {
  if (!user) return 0;
  const strikes = user.strikes;
  if (strikes && typeof strikes === 'object') {
    const count = toInteger((strikes as Record<string, unknown>).count);
    if (count !== null) return count;
  }
  return toInteger(user.strikes_count) ?? toInteger(user.strikes) ?? 0;
}

/**
 * Gateway M07 — pembatalan order + perhitungan strike.
 *
 * Kebijakan mengikuti Rules.md §7:
 * - konsumen: gratis sebelum klaim; setelah klaim & sebelum AT_PICKUP gratis
 *   2×/hari lalu 1 strike; setelah AT_PICKUP tidak dapat dibatalkan;
 * - driver: order kembali AWAITING_DRIVER + 1 strike;
 * - merchant: hanya PLACED/ACCEPTED, tanpa strike;
 * - admin: kapan saja, tanpa strike.
 */
export async function cancelOrderEngine(
  db: Firestore,
  input: CancelOrderInput,
): Promise<CancelOrderResult> {
  if (!input.orderId || !input.actorId) {
    throw new GatewayError('INVALID_ARGUMENT', 'orderId dan actorId wajib diisi.');
  }

  const now = input.now ?? new Date();
  const dayKey = todayKey(now);

  return db.runTransaction(async (txn) => {
    const orderRef = db.collection('orders').doc(input.orderId);
    const orderSnap = await txn.get(orderRef);
    if (!orderSnap.exists) {
      throw new GatewayError('ORDER_NOT_FOUND', 'Order tidak ditemukan.');
    }
    const order = orderSnap.data() as DocumentData;
    const status = String(order.status ?? '');

    // Idempoten: pembatalan ganda tidak menambah strike.
    if (status === 'CANCELLED') {
      return {
        ok: true as const,
        orderId: input.orderId,
        status: 'CANCELLED' as const,
        cancelledBy: String(order.cancelled_by ?? input.actorId),
        cancelledByRole:
          (order.cancelled_by_role as CancelActorRole | undefined) ??
          input.actorRole,
        strikeApplied: false,
        freeCancelRemaining: null,
      };
    }
    if (TERMINAL_STATUSES.has(status)) {
      throw new GatewayError(
        'INVALID_ORDER_STATE',
        `Order berstatus ${status} tidak dapat dibatalkan.`,
      );
    }

    // ---- Verifikasi otorisasi peran ----
    if (input.actorRole === 'admin' && !hasAdminClaim(input.adminClaims)) {
      throw new GatewayError(
        'PERMISSION_DENIED',
        'Hanya admin yang dapat membatalkan order atas nama sistem.',
      );
    }
    if (
      input.actorRole === 'consumer' &&
      String(order.consumer_id ?? '') !== input.actorId
    ) {
      throw new GatewayError('PERMISSION_DENIED', 'Order ini bukan milik Anda.');
    }
    if (
      input.actorRole === 'driver' &&
      String(order.driver_id ?? '') !== input.actorId
    ) {
      throw new GatewayError(
        'PERMISSION_DENIED',
        'Order ini bukan tugas driver yang sedang login.',
      );
    }
    if (input.actorRole === 'merchant') {
      const merchantId =
        input.merchantId ??
        (typeof input.adminClaims?.merchant_id === 'string'
          ? input.adminClaims.merchant_id
          : '');
      if (!merchantId || String(order.merchant_id ?? '') !== merchantId) {
        throw new GatewayError(
          'PERMISSION_DENIED',
          'Anda bukan pemilik merchant pada order ini.',
        );
      }
    }

    // ---- BACA seluruh dokumen sebelum penulisan ----
    const driverId = String(order.driver_id ?? '');
    const actorRef = db.collection('users').doc(input.actorId);
    const driverRef = driverId ? db.collection('users').doc(driverId) : null;
    const secretRef = orderRef.collection('secrets').doc('handover');

    const [actorSnap, driverSnap, secretSnap] = await Promise.all([
      txn.get(actorRef),
      driverRef ? txn.get(driverRef) : Promise.resolve(null),
      txn.get(secretRef),
    ]);

    const actor = actorSnap.exists
      ? (actorSnap.data() as DocumentData)
      : undefined;
    const driver = driverSnap?.exists
      ? (driverSnap.data() as DocumentData)
      : undefined;

    const userPatches = new Map<string, Record<string, unknown>>();
    const patchUser = (uid: string, patch: Record<string, unknown>): void => {
      userPatches.set(uid, { ...(userPatches.get(uid) ?? {}), ...patch });
    };

    let nextStatus: 'CANCELLED' | 'AWAITING_DRIVER' = 'CANCELLED';
    let strikeApplied = false;
    let freeCancelRemaining: number | null = null;
    let releaseDriver = false;

// ---- Terapkan kebijakan pembatalan per peran ----
    if (input.actorRole === 'admin') {
      nextStatus = 'CANCELLED';
    } else if (input.actorRole === 'merchant') {
      if (!['PLACED', 'ACCEPTED'].includes(status)) {
        throw new GatewayError(
          'INVALID_ORDER_STATE',
          'Merchant hanya dapat membatalkan order berstatus PLACED atau ACCEPTED.',
        );
      }
      nextStatus = 'CANCELLED';
    } else if (input.actorRole === 'consumer') {
      if (CONSUMER_FREE_STATUSES.has(status)) {
        nextStatus = 'CANCELLED';
      } else if (status === 'CLAIMED') {
        const usedToday =
          typeof actor?.free_cancel_date === 'string' &&
          actor.free_cancel_date === dayKey
            ? (toInteger(actor.free_cancel_count) ?? 0)
            : 0;
        if (usedToday < FREE_CANCELS_PER_DAY) {
          freeCancelRemaining = FREE_CANCELS_PER_DAY - (usedToday + 1);
          patchUser(input.actorId, {
            free_cancel_date: dayKey,
            free_cancel_count: usedToday + 1,
          });
        } else {
          strikeApplied = true;
        }
        nextStatus = 'CANCELLED';
        releaseDriver = true;
      } else {
        throw new GatewayError(
          'INVALID_ORDER_STATE',
          'Order sudah dijemput/dalam pengantaran sehingga tidak dapat dibatalkan. Buka dispute bila ada masalah.',
        );
      }
    } else {
      // driver
      if (!DRIVER_ACTIVE_STATUSES.has(status)) {
        throw new GatewayError(
          'INVALID_ORDER_STATE',
          `Driver tidak dapat membatalkan order berstatus ${status}.`,
        );
      }
      nextStatus = 'AWAITING_DRIVER';
      strikeApplied = true;
      releaseDriver = true;
    }

    if (strikeApplied) {
      const nextStrikes = readStrikeCount(actor) + 1;
      patchUser(input.actorId, {
        strikes: { count: nextStrikes, last_at: FieldValue.serverTimestamp() },
      });
    }

    if (releaseDriver && driverId) {
      const driverData =
        driver ?? (driverId === input.actorId ? actor : undefined);
      const currentJobs = toInteger(driverData?.active_jobs) ?? 0;
      patchUser(driverId, { active_jobs: Math.max(0, currentJobs - 1) });
    }

    // ---- PENULISAN ATOMIK ----
    const orderPatch: Record<string, unknown> = {
      status: nextStatus,
      cancelled_by: input.actorId,
      cancelled_by_role: input.actorRole,
      updated_at: FieldValue.serverTimestamp(),
    };
    const reason = input.reason?.trim();
    if (reason) orderPatch.cancel_reason = reason.slice(0, 280);
    if (nextStatus === 'CANCELLED') {
      orderPatch.cancelled_at = FieldValue.serverTimestamp();
    } else {
      orderPatch.requeued_at = FieldValue.serverTimestamp();
      orderPatch.driver_id = null;
      orderPatch.commission_fee = FieldValue.delete();
    }
    txn.update(orderRef, orderPatch);

    if (releaseDriver && secretSnap?.exists) {
      txn.delete(secretRef);
    }

    const eventId =
      nextStatus === 'CANCELLED'
        ? 'cancelled'
        : `requeued_${input.actorId}_${now.getTime()}`;
    txn.set(orderRef.collection('events').doc(eventId), {
      type: nextStatus === 'CANCELLED' ? 'CANCELLED' : 'REQUEUED',
      from_status: status,
      to_status: nextStatus,
      actor_id: input.actorId,
      actor_role: input.actorRole,
      at: FieldValue.serverTimestamp(),
      meta: { strikeApplied, freeCancelRemaining, reason: reason ?? null },
    });

    for (const [uid, patch] of userPatches) {
      txn.set(
        db.collection('users').doc(uid),
        { ...patch, updated_at: FieldValue.serverTimestamp() },
        { merge: true },
      );
    }

    return {
      ok: true as const,
      orderId: input.orderId,
      status: nextStatus,
      cancelledBy: input.actorId,
      cancelledByRole: input.actorRole,
      strikeApplied,
      freeCancelRemaining,
    };
  });
}