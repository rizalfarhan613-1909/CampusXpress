import {
  FieldValue,
  type DocumentData,
  type Firestore,
} from 'firebase-admin/firestore';
import { GatewayError } from './errors';
import { calculateDeliveryFee } from './fareMatrix';
import { computeCommission, toInteger } from './money';

export interface FinalizeOrderInput {
  orderId: string;
  /** Pemanggil (konsumen pemilik order). Kosongkan untuk pemanggilan sistem/cron. */
  actorId?: string;
  /** True bila pemanggil adalah admin (boleh memfinalisasi order apa pun). */
  isAdmin?: boolean;
}

export interface FinalizePricing {
  subtotal: number;
  deliveryFee: number;
  total: number;
  commission: number;
}

export interface FinalizeOrderResult {
  ok: true;
  orderId: string;
  finalized: boolean;
  status: string;
  pricing: FinalizePricing | null;
  reason: 'ALREADY_FINALIZED' | 'PRICE_MISMATCH' | null;
}

const TERMINAL_STATUSES = new Set(['COMPLETED', 'CANCELLED', 'EXPIRED']);

/**
 * Menjumlahkan snapshot item bila order membawa array `items`.
 * Bentuk yang didukung: `{ price, qty|quantity, options?: [{ priceDelta }] }`.
 * Mengembalikan `null` bila tidak ada item (order tarif saja).
 */
function sumItems(items: unknown): number | null {
  if (!Array.isArray(items) || items.length === 0) return null;

  let subtotal = 0;
  for (const raw of items) {
    if (!raw || typeof raw !== 'object') return null;
    const item = raw as Record<string, unknown>;
    const price = toInteger(item.price);
    const qty = toInteger(item.qty) ?? toInteger(item.quantity) ?? 1;
    if (price === null || price < 0 || qty === null || qty <= 0) return null;

    let unit = price;
    if (Array.isArray(item.options)) {
      for (const rawOption of item.options) {
        if (!rawOption || typeof rawOption !== 'object') return null;
        const option = rawOption as Record<string, unknown>;
        const delta =
          toInteger(option.priceDelta) ?? toInteger(option.price_delta);
        if (delta === null) return null;
        unit += delta;
      }
    }
    subtotal += unit * qty;
  }
  return subtotal;
}

function readStoredPricing(order: DocumentData): FinalizePricing | null {
  const pricing = order.pricing;
  if (pricing && typeof pricing === 'object') {
    const map = pricing as Record<string, unknown>;
    const subtotal = toInteger(map.subtotal);
    const deliveryFee =
      toInteger(map.deliveryFee) ?? toInteger(map.delivery_fee);
    const total = toInteger(map.total);
    const commission =
      toInteger(map.commission) ?? toInteger(order.commission_fee);
    if (
      subtotal !== null &&
      deliveryFee !== null &&
      total !== null &&
      commission !== null
    ) {
      return { subtotal, deliveryFee, total, commission };
    }
  }

  const total = toInteger(order.total_price) ?? toInteger(order.totalPrice);
  const deliveryFee =
    toInteger(order.delivery_fee) ?? toInteger(order.deliveryFee);
  const commission = toInteger(order.commission_fee);
  if (total !== null && deliveryFee !== null && commission !== null) {
    return { subtotal: total - deliveryFee, deliveryFee, total, commission };
  }
  return null;
}

/**
 * Gateway M03/M07 — FINALIZE: menetapkan harga tepercaya.
 *
 * Sesuai Architecture.md §5.2 dan PRD X3, ongkir selalu dihitung ulang dari
 * matriks zona (bukan dari angka kiriman klien). Bila hasil hitung server
 * berbeda dari angka klien, order ditandai EXPIRED dengan alasan
 * PRICE_MISMATCH sehingga driver tidak pernah melihat order bertarif palsu.
 */
export async function finalizeOrderEngine(
  db: Firestore,
  input: FinalizeOrderInput,
): Promise<FinalizeOrderResult> {
  if (!input.orderId) {
    throw new GatewayError('INVALID_ARGUMENT', 'orderId wajib diisi.');
  }

  return db.runTransaction(async (txn) => {
    const orderRef = db.collection('orders').doc(input.orderId);

    // ---- BACA order ----
    const orderSnap = await txn.get(orderRef);
    if (!orderSnap.exists) {
      throw new GatewayError('ORDER_NOT_FOUND', 'Order tidak ditemukan.');
    }
    const order = orderSnap.data() as DocumentData;

    if (
      input.actorId &&
      input.isAdmin !== true &&
      String(order.consumer_id ?? '') !== input.actorId
    ) {
      throw new GatewayError(
        'PERMISSION_DENIED',
        'Hanya konsumen pemilik order yang dapat memfinalisasi order ini.',
      );
    }

    const status = String(order.status ?? '');

    if (order.finalized === true) {
      return {
        ok: true as const,
        orderId: input.orderId,
        finalized: true,
        status,
        pricing: readStoredPricing(order),
        reason: 'ALREADY_FINALIZED' as const,
      };
    }

    if (TERMINAL_STATUSES.has(status)) {
      throw new GatewayError(
        'INVALID_ORDER_STATE',
        `Order berstatus ${status} tidak dapat difinalisasi.`,
      );
    }

    const pickupId = String(order.pickup_landmark_id ?? '');
    const destinationId = String(order.destination_landmark_id ?? '');
    if (!pickupId || !destinationId) {
      throw new GatewayError(
        'INVALID_ARGUMENT',
        'Landmark jemput dan tujuan wajib diisi.',
      );
    }

    // ---- BACA landmark (semua pembacaan selesai sebelum penulisan) ----
    const [pickupSnap, destinationSnap] = await Promise.all([
      txn.get(db.collection('landmarks').doc(pickupId)),
      txn.get(db.collection('landmarks').doc(destinationId)),
    ]);
    if (!pickupSnap.exists || !destinationSnap.exists) {
      throw new GatewayError(
        'INVALID_ARGUMENT',
        'Landmark jemput atau tujuan tidak ditemukan.',
      );
    }

    let deliveryFee: number;
    try {
      deliveryFee = calculateDeliveryFee(
        (pickupSnap.data() as DocumentData).zone_group,
        (destinationSnap.data() as DocumentData).zone_group,
      );
    } catch {
      throw new GatewayError(
        'INVALID_ARGUMENT',
        'Zona landmark tidak dikenal pada matriks tarif.',
      );
    }

// ---- Hitung ulang harga tepercaya ----
    const clientDeliveryFee =
      toInteger(order.delivery_fee) ?? toInteger(order.deliveryFee);
    const clientTotal =
      toInteger(order.total_price) ?? toInteger(order.totalPrice);
    const itemsSubtotal = sumItems(order.items);

    const declaredSubtotal =
      toInteger(order.subtotal) ??
      (clientTotal !== null && clientDeliveryFee !== null
        ? clientTotal - clientDeliveryFee
        : null);

    const subtotal = itemsSubtotal ?? declaredSubtotal ?? 0;
    if (subtotal < 0) {
      throw new GatewayError(
        'INVALID_ARGUMENT',
        'Subtotal order tidak boleh negatif.',
      );
    }

    const expectedTotal = subtotal + deliveryFee;
    const commission = computeCommission(expectedTotal);

    const mismatch =
      clientTotal === null ||
      (itemsSubtotal !== null &&
        declaredSubtotal !== null &&
        itemsSubtotal !== declaredSubtotal) ||
      clientTotal !== expectedTotal ||
      (clientDeliveryFee !== null && clientDeliveryFee !== deliveryFee) ||
      (declaredSubtotal !== null && declaredSubtotal !== subtotal);

    if (mismatch) {
      txn.update(orderRef, {
        finalized: false,
        status: 'EXPIRED',
        expire_reason: 'PRICE_MISMATCH',
        expected_pricing: {
          subtotal,
          deliveryFee,
          total: expectedTotal,
          commission,
        },
        expired_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      });
      txn.set(orderRef.collection('events').doc('price_mismatch'), {
        type: 'PRICE_MISMATCH',
        from_status: status,
        to_status: 'EXPIRED',
        actor_id: input.actorId ?? null,
        actor_role: 'system',
        at: FieldValue.serverTimestamp(),
        meta: {
          clientTotal,
          clientDeliveryFee,
          declaredSubtotal,
          expected: { subtotal, deliveryFee, total: expectedTotal },
        },
      });

      return {
        ok: true as const,
        orderId: input.orderId,
        finalized: false,
        status: 'EXPIRED',
        pricing: null,
        reason: 'PRICE_MISMATCH' as const,
      };
    }

    const pricing: FinalizePricing = {
      subtotal,
      deliveryFee,
      total: expectedTotal,
      commission,
    };

    txn.update(orderRef, {
      finalized: true,
      subtotal,
      delivery_fee: deliveryFee,
      total_price: expectedTotal,
      commission_fee: commission,
      pricing,
      finalized_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    });
    txn.set(orderRef.collection('events').doc('finalized'), {
      type: 'FINALIZED',
      from_status: status,
      to_status: status,
      actor_id: input.actorId ?? null,
      actor_role: input.actorId ? 'consumer' : 'system',
      at: FieldValue.serverTimestamp(),
      meta: pricing,
    });

    return {
      ok: true as const,
      orderId: input.orderId,
      finalized: true,
      status,
      pricing,
      reason: null,
    };
  });
}