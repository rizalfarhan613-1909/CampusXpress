/**
 * Data demo katalog menu merchant (Design.md §C.17 — UMKM Menu Management).
 */

export type MenuAvailability = 'READY' | 'OUT';

export interface MenuOption {
  id: string;
  name: string;
  extra: number;
  isDefault?: boolean;
}

export interface MenuVariantGroup {
  id: string;
  title: string;
  rule: 'WAJIB_1' | 'OPSIONAL';
  options: MenuOption[];
}

export interface MerchantMenu {
  id: string;
  name: string;
  category: string;
  description: string;
  price: number;
  dailyQuota: number;
  soldToday: number;
  availability: MenuAvailability;
  photoWebpKb: number;
  variants: MenuVariantGroup[];
}

/** Batas validasi formulir menu (Design.md §C.17 "Aturan formulir"). */
export const MENU_RULES = {
  nameMin: 2,
  nameMax: 50,
  descriptionMax: 200,
  priceMin: 500,
  priceMax: 500000,
  priceStep: 100,
  quotaMin: 1,
  quotaMax: 999,
  maxGroups: 6,
  maxOptionsPerGroup: 12,
  photoMaxKb: 80,
} as const;

export const MENU_CATEGORIES = [
  'Makanan Berat',
  'Minuman',
  'Snack / Gorengan',
  'Paket Hemat UKT',
] as const;

export const MERCHANT_MENUS: MerchantMenu[] = [
  {
    id: 'MNU-001',
    name: 'Ayam Geprek Sambal Matah Spesial',
    category: 'Makanan Berat',
    description:
      'Ayam paha/dada renyah dengan sambal matah serai segar khas Bali dan lalapan segar timun.',
    price: 16000,
    dailyQuota: 50,
    soldToday: 32,
    availability: 'READY',
    photoWebpKb: 74,
    variants: [
      {
        id: 'VAR-PEDAS',
        title: 'Tingkat Kepedasan',
        rule: 'WAJIB_1',
        options: [
          { id: 'L0', name: 'Level 0 · Tidak Pedas', extra: 0 },
          { id: 'L1', name: 'Level 1 (Standar) · Sedang', extra: 0, isDefault: true },
          { id: 'L3', name: 'Level 3 · Nampol', extra: 1000 },
          { id: 'L5', name: 'Level 5 · Pedas Mampus', extra: 2000 },
        ],
      },
      {
        id: 'VAR-TOPPING',
        title: 'Tambahan Topping / Lauk',
        rule: 'OPSIONAL',
        options: [
          { id: 'T1', name: 'Telur Cepok Balado / Mata Sapi', extra: 3500 },
          { id: 'T2', name: 'Kol Goreng Crispy', extra: 2000 },
          { id: 'T3', name: 'Ekstra Sambal Matah 1 Cup', extra: 1500 },
        ],
      },
    ],
  },
  {
    id: 'MNU-002',
    name: 'Soto Bening Spesial Ayam Kampung',
    category: 'Makanan Berat',
    description:
      'Soto kuah bening resep 2018 dengan ayam kampung, soun, dan kerupuk rambak.',
    price: 19000,
    dailyQuota: 30,
    soldToday: 30,
    availability: 'OUT',
    photoWebpKb: 68,
    variants: [
      {
        id: 'VAR-NASI',
        title: 'Pilihan Karbohidrat',
        rule: 'WAJIB_1',
        options: [
          { id: 'N1', name: 'Nasi Putih', extra: 0, isDefault: true },
          { id: 'N2', name: 'Tanpa Nasi (Lontong)', extra: 1000 },
        ],
      },
    ],
  },
  {
    id: 'MNU-003',
    name: 'Paket Hemat UKT (Geprek + Es Teh)',
    category: 'Paket Hemat UKT',
    description:
      'Paket makan siang hemat mahasiswa dengan subsidi mitra BEM Kampus.',
    price: 21000,
    dailyQuota: 40,
    soldToday: 18,
    availability: 'READY',
    photoWebpKb: 79,
    variants: [
      {
        id: 'VAR-MINUM',
        title: 'Pilihan Minuman',
        rule: 'WAJIB_1',
        options: [
          { id: 'E1', name: 'Es Teh Manis', extra: 0, isDefault: true },
          { id: 'E2', name: 'Es Jeruk Peras', extra: 1000 },
        ],
      },
    ],
  },
];

export const KITCHEN_STATS = {
  session: 'Sesi Siang',
  revenue: 1875000,
  revenueDeltaPersen: 12.4,
  portionsSold: 142,
  cashlessPersen: 86,
  waitingResponse: 3,
  queueCount: 7,
};

export interface StoreScheduleRow {
  id: string;
  day: string;
  ranges: string[];
  note: string;
  dot: 'primary' | 'info' | 'glow';
}

export const STORE_SCHEDULE: StoreScheduleRow[] = [
  {
    id: 'SEN-KAM',
    day: 'Senin – Kamis',
    ranges: ['07:30', '17:00'],
    note: 'Reguler Perkuliahan',
    dot: 'primary',
  },
  {
    id: 'JUM',
    day: 'Jumat',
    ranges: ['07:30', '11:00'],
    note: 'Jeda Sholat Jumat · lanjut 13.00 - 17.00',
    dot: 'info',
  },
  {
    id: 'SAB',
    day: 'Sabtu',
    ranges: ['08:00', '15:00'],
    note: 'Sesi Praktikum',
    dot: 'glow',
  },
];
