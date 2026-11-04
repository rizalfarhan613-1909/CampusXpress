'use client';

import { motion, useReducedMotion, useSpring, useTransform } from 'framer-motion';
import { useEffect, useState } from 'react';
import { Badge } from '@/components/ui/Badge';
import { Icon } from '@/components/ui/Icon';
import { persen, rupiah } from '@/lib/format';

interface RowSpec {
  label: string;
  value: number;
  /** Catatan kecil setelah nilai, mis. "Gratis KTM". */
  note?: string;
}

interface Scenario {
  id: string;
  tab: string;
  commercial: RowSpec[];
  campus: RowSpec[];
  savingsCaption: string;
  note: string;
}

/**
 * Skenario perbandingan biaya (Design.md §C.23 "Perbandingan (Price Roll)").
 * Angka mengikuti tabel data contoh gambar 27 dan bersifat ilustratif.
 */
const SCENARIOS: Scenario[] = [
  {
    id: 'satuan',
    tab: 'Makan Siang Satuan',
    commercial: [
      { label: 'Harga Menu (Markup Resto 20%)', value: 20000 },
      { label: 'Biaya Ongkir Luar Kampus', value: 12000 },
      { label: 'Biaya Layanan & Jasa Aplikasi', value: 4500 },
      { label: 'Biaya Parkir Gedung Eksternal', value: 2000 },
    ],
    campus: [
      { label: 'Harga Asli Etalase Kantin', value: 15000 },
      { label: 'Ongkir Flat Intra-Kampus', value: 4000 },
      { label: 'Iuran Pemeliharaan BEM (0,5%)', value: 500 },
      { label: 'Biaya Parkir Kampus', value: 0, note: 'Gratis KTM' },
    ],
    savingsCaption: 'Cukup untuk fotokopi puluhan lembar tugas',
    note: 'Markup 20% dan biaya layanan Rp 4.500 adalah asumsi ilustrasi, bukan tarif resmi platform tertentu.',
  },
  {
    id: 'jastip',
    tab: 'Jastip Kelompok (3 Porsi)',
    commercial: [
      { label: 'Harga Menu ×3 (Markup Resto 20%)', value: 60000 },
      { label: 'Biaya Ongkir Luar Kampus', value: 12000 },
      { label: 'Biaya Layanan & Jasa Aplikasi', value: 9000 },
      { label: 'Biaya Parkir Gedung Eksternal', value: 2000 },
    ],
    campus: [
      { label: 'Harga Asli Etalase Kantin ×3', value: 45000 },
      { label: 'Ongkir Flat Intra-Kampus (1 rute)', value: 4000 },
      { label: 'Iuran Pemeliharaan BEM (0,5%)', value: 245 },
      { label: 'Biaya Parkir Kampus', value: 0, note: 'Gratis KTM' },
    ],
    savingsCaption: 'Sisa uang saku bisa dipakai beli buku praktikum',
    note: 'Biaya jastip kelompok dihitung satu rute, bukan tiga ongkir terpisah.',
  },
  {
    id: 'nebeng',
    tab: 'Nebeng Antar Fakultas',
    commercial: [
      { label: 'Tarif Kurir Instan Luar Kampus', value: 18000 },
      { label: 'Biaya Layanan & Jasa Aplikasi', value: 4500 },
      { label: 'Biaya Parkir Gedung Eksternal', value: 2000 },
      { label: 'Biaya Penanganan Berkas', value: 0, note: 'Antre loket' },
    ],
    campus: [
      { label: 'Ongkir Flat Antar-Fakultas', value: 6000 },
      { label: 'Iuran Pemeliharaan BEM (0,5%)', value: 30 },
      { label: 'Biaya Parkir Kampus', value: 0, note: 'Gratis KTM' },
      { label: 'Biaya Penanganan Berkas', value: 0, note: 'Dibawa rider kampus' },
    ],
    savingsCaption: 'Waktu hemat bisa dipakai untuk revisi laporan',
    note: 'Nebeng antar fakultas memakai rute landmark kampus tanpa biaya tambahan.',
  },
];

const total = (rows: RowSpec[]) => rows.reduce((sum, row) => sum + row.value, 0);

/** Angka berputar dengan spring (`stiffness 120, damping 20`) — Design.md §D.7. */
function RollValue({ value, className = '' }: { value: number; className?: string }) {
  const reduce = useReducedMotion();
  const spring = useSpring(value, { stiffness: 120, damping: 20 });
  const text = useTransform(spring, (latest) => rupiah(latest));

  useEffect(() => {
    spring.set(value);
  }, [spring, value]);

  if (reduce) {
    return <span className={className}>{rupiah(value)}</span>;
  }

  return (
    <motion.span className={className} aria-label={rupiah(value)}>
      {text}
    </motion.span>
  );
}

function CostRows({ rows, tone }: { rows: RowSpec[]; tone: 'light' | 'dark' }) {
  const isDark = tone === 'dark';
  return (
    <dl className="mt-4 space-y-3">
      {rows.map((row) => (
        <div key={row.label} className="flex items-baseline justify-between gap-3">
          <dt className={isDark ? 'text-web-small text-white/80' : 'text-web-small text-text-body'}>
            {row.label}
          </dt>
          <dd
            className={`shrink-0 font-display text-h5 ${
              isDark
                ? row.value === 0
                  ? 'text-mint-300'
                  : 'text-white'
                : row.value === 0
                  ? 'text-primary'
                  : 'text-text-strong'
            }`}
          >
            {row.value === 0 ? rupiah(0) : <RollValue value={row.value} />}
            {row.note ? (
              <span className="ml-1 text-caption font-normal opacity-75">({row.note})</span>
            ) : null}
          </dd>
        </div>
      ))}
    </dl>
  );
}

/**
 * Price Roll — tab perbandingan biaya komersial vs Campus Express
 * (Design.md §C.23 & §D.7). Indikator tab bergeser 250 ms dan tinggi kartu
 * dijaga tetap antar skenario.
 */
export function PriceRoll() {
  const [activeId, setActiveId] = useState<string>(SCENARIOS[0].id);
  const scenario = SCENARIOS.find((item) => item.id === activeId) ?? SCENARIOS[0];

  const commercialTotal = total(scenario.commercial);
  const campusTotal = total(scenario.campus);
  const saving = commercialTotal - campusTotal;
  const savingRate = commercialTotal > 0 ? Math.round((saving / commercialTotal) * 100) : 0;

  return (
    <div className="mx-auto max-w-[880px]">
      <div
        role="tablist"
        aria-label="Skenario perbandingan biaya"
        className="mx-auto flex w-fit max-w-full flex-wrap justify-center gap-1 rounded-full bg-lav-200 p-1"
      >
        {SCENARIOS.map((item) => {
          const active = item.id === activeId;
          return (
            <button
              key={item.id}
              role="tab"
              type="button"
              aria-selected={active}
              onClick={() => setActiveId(item.id)}
              className={`ce-focus relative rounded-full px-4 py-2 font-display text-body-s transition-colors duration-fast ${
                active ? 'text-on-primary' : 'text-text-body hover:text-primary'
              }`}
            >
              {active ? (
                <motion.span
                  layoutId="price-roll-tab"
                  className="absolute inset-0 rounded-full bg-primary"
                  transition={{ duration: 0.25, ease: 'easeInOut' }}
                />
              ) : null}
              <span className="relative z-10 whitespace-nowrap">{item.tab}</span>
            </button>
          );
        })}
      </div>

      <div className="mt-5 grid gap-3 lg:grid-cols-2">
        <article className="flex flex-col rounded-lg border border-line-subtle bg-surface p-4">
          <header className="flex items-center justify-between gap-3">
            <h3 className="font-display text-web-card-title text-text-strong">
              Aplikasi Komersial Umum
            </h3>
            <Badge tone="lav">Asumsi</Badge>
          </header>
          <div className="flex-1">
            <CostRows rows={scenario.commercial} tone="light" />
          </div>
          <div className="mt-4 flex items-end justify-between gap-3 border-t border-line-subtle pt-4">
            <span className="font-display text-micro uppercase text-text-muted">
              Total Pengeluaran
            </span>
            <span className="font-display text-h2 text-text-strong">
              <RollValue value={commercialTotal} />
            </span>
          </div>
        </article>

        <article className="relative flex flex-col rounded-lg bg-primary p-4">
          <span className="absolute right-4 top-4">
            <Badge tone="mint">BEST VALUE SIVITAS</Badge>
          </span>
          <header className="pr-36">
            <h3 className="font-display text-web-card-title text-white">
              Campus Express (Go-Campus)
            </h3>
          </header>
          <div className="flex-1">
            <CostRows rows={scenario.campus} tone="dark" />
          </div>
          <div className="mt-4 flex items-end justify-between gap-3 border-t border-white/20 pt-4">
            <span className="font-display text-micro uppercase text-white/70">Total Bersih</span>
            <span className="font-display text-h2 text-mint-300">
              <RollValue value={campusTotal} />
            </span>
          </div>
        </article>
      </div>

      <div className="mt-4 flex flex-col items-start justify-between gap-2 rounded-md bg-mint-100 px-4 py-3 md:flex-row md:items-center">
        <p className="flex items-center gap-2 font-display text-body-m font-bold text-mint-on">
          <Icon name="trending_up" size={20} />
          Kamu berhemat {rupiah(saving)} ({persen(savingRate, 0)}) untuk pesanan ini!
        </p>
        <p className="text-caption text-mint-on">{scenario.savingsCaption}</p>
      </div>

      <p className="mt-2 text-caption text-text-muted">{scenario.note}</p>
    </div>
  );
}

