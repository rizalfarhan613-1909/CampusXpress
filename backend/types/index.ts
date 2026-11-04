export type UserRole = 'consumer' | 'driver' | 'merchant' | 'admin';

export type OrderType = 'numpang' | 'jastip' | 'paket' | 'umkm';

export type OrderStatus =
  | 'PLACED'
  | 'ACCEPTED'
  | 'READY'
  | 'AWAITING_DRIVER'
  | 'CLAIMED'
  | 'AT_PICKUP'
  | 'ON_DELIVERY'
  | 'ARRIVED'
  | 'COMPLETED'
  | 'CANCELLED'
  | 'EXPIRED'
  | 'DISPUTED';

export type PaymentMethod = 'COD' | 'QRIS_STATIC';

export type DeliveryType = 'pickup' | 'delivery' | 'both';

export type WalletLedgerType =
  | 'topup'
  | 'commission'
  | 'adjustment'
  | 'refund'
  | 'COMMISSION_TOPUP'
  | 'COMMISSION_DEDUCTION';

export interface FirestoreTimestamp {
  readonly seconds: number;
  readonly nanoseconds: number;
  toDate(): Date;
  toMillis(): number;
}

export interface ProductVariant {
  id: string;
  name: string;
  price_delta: number;
}

export interface UserProfile {
  id: string;
  name: string;
  phone: string;
  role: UserRole;
  is_verified: boolean;
  wallet_balance: number;
  /** Counter atomik jumlah order aktif (maks. 2), dikelola Gateway. */
  active_jobs?: number;
}

export interface Landmark {
  id: string;
  name: string;
  zone_group: string;
}

export interface Merchant {
  id: string;
  owner_id: string;
  store_name: string;
  is_open: boolean;
  delivery_type: DeliveryType;
}

export interface Product {
  id: string;
  merchant_id: string;
  name: string;
  price: number;
  is_available: boolean;
  image_url: string;
  variants: ProductVariant[];
}

export interface Order {
  id: string;
  consumer_id: string;
  driver_id: string | null;
  merchant_id: string | null;
  order_type: OrderType;
  pickup_landmark_id: string;
  destination_landmark_id: string;
  total_price: number;
  delivery_fee: number;
  commission_fee: number;
  payment_method: PaymentMethod;
  status: OrderStatus;
  /** Consumer-only. Stored in orders/{id}/secrets/handover, never on the order document. */
  dropoff_pin?: string;
  created_at: FirestoreTimestamp;
  claimed_at?: FirestoreTimestamp;
  completed_at?: FirestoreTimestamp;
  updated_at?: FirestoreTimestamp;
}

export interface ChatMessage {
  id: string;
  order_id: string;
  sender_id: string;
  text: string | null;
  image_url: string | null;
  created_at: FirestoreTimestamp;
}

export interface WalletLedger {
  id: string;
  driver_id: string;
  amount: number;
  type: WalletLedgerType;
  description: string;
  created_at: FirestoreTimestamp;
  order_id?: string;
  balance_after?: number;
  idempotency_key?: string;
}
