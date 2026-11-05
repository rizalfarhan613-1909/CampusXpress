/**
 * Data demo panel admin (Design.md §C.15, §C.4, tech.md §8.4).
 * Seluruh angka ilustrasi dan tidak mewakili data resmi.
 */

export interface OpsMetric {
  id: string;
  label: string;
  value: string;
  caption: string;
  badge?: string;
  tone: 'surface' | 'primary';
}

export const OPS_METRICS: OpsMetric[] = [
  {
    id: 'driver',
    label: 'Driver Online',
    value: '38',
    caption: '12 standby di pujasera FST',
    badge: 'Live',
    tone: 'surface',
  },
  {
    id: 'kios',
    label: 'Kios Standby',
    value: '27',
    caption: 'Dari 30 stan terdaftar',
    badge: 'Pujasera',
    tone: 'surface',
  },
  {
    id: 'volume',
    label: 'Volume Transaksi',
    value: '1.284',
    caption: 'Pesanan terkirim hari ini',
    badge: '+18%',
    tone: 'surface',
  },
  {
    id: 'kas',
    label: 'Kas BEM & Subsidi UKT',
    value: 'Rp 1,42 jt',
    caption: 'Iuran 0,5% pekan ini',
    badge: '5% Bagian',
    tone: 'primary',
  },
];

export interface VerificationApplicant {
  id: string;
  name: string;
  role: 'Driver Kampus' | 'Merchant Baru';
  cohort: string;
  identity: string;
  documents: { id: string; label: string; value: string }[];
}

export const VERIFICATION_QUEUE: VerificationApplicant[] = [
  {
    id: 'VRF-4412',
    name: 'Bayu Pratama',
    role: 'Driver Kampus',
    cohort: 'Angkatan 2022',
    identity: 'NIM 2022•••441',
    documents: [
      { id: 'sim', label: 'SIM C', value: 'B 4921 K••' },
      { id: 'kendaraan', label: 'Kendaraan', value: 'Honda Beat · 2021' },
    ],
  },
  {
    id: 'VRF-4413',
    name: 'Nadia Puspa',
    role: 'Driver Kampus',
    cohort: 'Angkatan 2023',
    identity: 'NIM 2023•••198',
    documents: [
      { id: 'sim', label: 'SIM C', value: 'B 5012 A••' },
      { id: 'kendaraan', label: 'Kendaraan', value: 'Yamaha Mio · 2019' },
    ],
  },
  {
    id: 'VRF-4414',
    name: 'Kantin Pak Rudi',
    role: 'Merchant Baru',
    cohort: 'Stan No. 18',
    identity: 'NIB 1•••8842',
    documents: [
      { id: 'ktm', label: 'KTM Pemilik', value: '2021•••067' },
      { id: 'halal', label: 'Sertifikat Halal', value: 'Verifikasi BEM' },
    ],
  },
];

export interface TariffZone {
  id: string;
  name: string;
  description: string;
  studentFee: number;
  bemSubsidy: number;
  dot: 'primary' | 'info' | 'glow';
}

export const TARIFF_ZONES: TariffZone[] = [
  {
    id: 'Z1',
    name: 'Zona 1 · Intra-Fakultas',
    description: 'Pujasera FST → seluruh gedung FST dan lobi barat',
    studentFee: 4000,
    bemSubsidy: 1200,
    dot: 'primary',
  },
  {
    id: 'Z2',
    name: 'Zona 2 · Antar-Fakultas',
    description: 'Kantin Rektorat → FEB, FH, dan FIKES',
    studentFee: 6000,
    bemSubsidy: 1800,
    dot: 'info',
  },
  {
    id: 'Z3',
    name: 'Zona 3 · Luar Ring 1',
    description: 'Drop point perpustakaan, asrama, dan gerbang timur',
    studentFee: 8000,
    bemSubsidy: 2400,
    dot: 'glow',
  },
];

export const BROADCAST_DRAFT =
  '[BEM KAMPUS] Layanan Campus Express dialihkan ke Lobi Barat FST selama renovasi pujasera timur. Pesanan tetap dilayani seperti biasa.';

export const BROADCAST_TARGET = '1.420 Mahasiswa Aktif';
