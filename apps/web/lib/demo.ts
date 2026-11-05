/**
 * Data demo dasbor merchant.
 *
 * Bersumber dari data contoh `docs/Design.md` §C.12, §C.13, §C.17, §C.21.
 * Dipakai untuk uji UI sebelum Gateway terhubung; seluruh angka ilustrasi.
 */

export type OrderStatus = 'HOT' | 'COOKING' | 'READY' | 'DISPATCHED';

export interface MerchantOrderItem {
  qty: number;
  name: string;
  note?: string;
  price: number;
}

export interface MerchantOrder {
  id: string;
  customer: string;
  destination: string;
  placedAgo: string;
  total: number;
  paid: boolean;
  method: 'JASTIP' | 'PICKUP';
  status: OrderStatus;
  driver?: { name: string; note: string };
  items: MerchantOrderItem[];
}

export const MERCHANT_STORE = {
  name: 'Kantin Bu Siti - Spesialis Geprek & Soto',
  stand: 'Stan #12 FST',
  location: 'Pujasera FST · Stand No. 12',
  specialist: 'Spesialis Kuliner Pedas Cepat Saji FST',
  verified: 'Mitra Halal BEM 2025',
  pickupPoint: 'Etalase Stand 12, samping tangga barat FST',
  bank: {
    name: 'Bank Syariah Indonesia (BSI)',
    label: 'Rekening Operasional Stan',
    masked: '7120-•••••-8812',
    holder: 'a/n Siti Aminah',
  },
  qris: { nmid: 'ID1020039102931', status: 'Aktif' },
};

export const MERCHANT_ORDERS: MerchantOrder[] = [
  {
    id: 'CX-9092',
    customer: 'Rizal Maulana',
    destination: 'Lab Komputer 3, Gedung FST',
    placedAgo: '4 menit lalu',
    total: 26500,
    paid: true,
    method: 'JASTIP',
    status: 'HOT',
    items: [
      { qty: 1, name: 'Ayam Geprek Sambal Matah Spesial', note: 'Level 3 · Nampol', price: 17000 },
      { qty: 1, name: 'Telur Cepok Balado', price: 3500 },
      { qty: 2, name: 'Es Teh Manis Jumbo', price: 3000 },
    ],
  },
  {
    id: 'CX-9091',
    customer: 'Anisa Rahmawati',
    destination: 'Ambil Sendiri · Etalase Stand 12',
    placedAgo: '7 menit lalu',
    total: 19000,
    paid: true,
    method: 'PICKUP',
    status: 'COOKING',
    items: [{ qty: 1, name: 'Soto Bening Spesial Ayam Kampung', price: 19000 }],
  },
  {
    id: 'CX-9089',
    customer: 'Daffa Firdaus',
    destination: 'Lobi Barat FST · Drop Point Driver',
    placedAgo: '11 menit lalu',
    total: 40000,
    paid: true,
    method: 'JASTIP',
    status: 'COOKING',
    driver: { name: 'Bayu Pratama', note: 'Sudah standby di depan loket kantin' },
    items: [
      { qty: 2, name: 'Ayam Geprek Sambal Matah Spesial', price: 16000 },
      { qty: 1, name: 'Kol Goreng Crispy', price: 2000 },
      { qty: 2, name: 'Es Jeruk Peras', price: 3000 },
    ],
  },
  {
    id: 'CX-9085',
    customer: 'Fahira Zahwa',
    destination: 'Perpustakaan Pusat · Meja Baca 2',
    placedAgo: '19 menit lalu',
    total: 21000,
    paid: false,
    method: 'JASTIP',
    status: 'READY',
    items: [{ qty: 1, name: 'Paket Hemat UKT (Geprek + Es Teh)', price: 21000 }],
  },
];
