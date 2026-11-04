'use client';

import Link from 'next/link';
import { motion, useInView, useReducedMotion } from 'framer-motion';
import { useRef } from 'react';
import type { ReactNode } from 'react';
import { Icon } from '@/components/ui/Icon';

const PIN = ['8', '4', '9', '2'];

/** Widget mini kartu 01: progres ETA terisi 0 → 65% (800 ms) & PIN digit demi digit. */
function EtaWidget() {
  const ref = useRef<HTMLDivElement>(null);
  const reduce = useReducedMotion();
  const inView = useInView(ref, { once: true, amount: 0.4 });
  const revealed = Boolean(reduce) || inView;

  return (
    <div ref={ref} className="rounded-md bg-lav-100 p-3">
      <p className="font-display text-micro uppercase text-text-muted">
        Keamanan Serah Terima Lobi
      </p>

      <p className="mt-1 flex items-baseline gap-1 font-mono text-body-m font-bold text-text-strong">
        <span>PIN:</span>
        {PIN.map((digit, index) => (
          <motion.span
            key={`${digit}-${index}`}
            className="inline-block"
            initial={false}
            animate={{ opacity: revealed ? 1 : 0, y: revealed ? 0 : 4 }}
            transition={{ delay: 0.1 + index * 0.08, duration: 0.2 }}
          >
            {digit}
          </motion.span>
        ))}
      </p>

      <div className="mt-2 flex items-center justify-between text-caption">
        <span className="text-text-body">Driver menuju Lobi FST</span>
        <span className="font-display font-bold text-primary">ETA: 3 Menit</span>
      </div>

      <div className="mt-2 h-1.5 w-full overflow-hidden rounded-full bg-lav-200">
        <motion.div
          className="h-full rounded-full bg-primary-glow"
          initial={false}
          animate={{ width: revealed ? '65%' : '0%' }}
          transition={{ duration: 0.8, ease: 'easeOut' }}
        />
      </div>
    </div>
  );
}

/** Kotak `rgba(255,255,255,0.14)` pada kartu driver (Design.md §C.23). */
function RevenueBox() {
  return (
    <div
      className="rounded-md p-3"
      style={{ backgroundColor: 'rgba(255,255,255,0.14)' }}
    >
      <p className="font-display text-micro uppercase text-white/80">Pendapatan Hari Ini</p>
      <p className="mt-1 font-display text-web-stat text-white">Rp 84.500</p>
      <p className="mt-1 text-caption text-mint-300">
        100% langsung cair ke Dompet Kampus
      </p>
    </div>
  );
}

function Checklist({ items }: { items: string[] }) {
  return (
    <ul className="space-y-2">
      {items.map((item) => (
        <li key={item} className="flex items-start gap-2 text-web-small text-text-body">
          <Icon name="check_circle" size={18} className="mt-0.5 shrink-0 text-primary" />
          <span>{item}</span>
        </li>
      ))}
    </ul>
  );
}

/** Kartu masuk `opacity 0 → 1` + `translateY(16 → 0)` 250 ms, jeda 60 ms antar kartu. */
function BentoCard({
  index,
  children,
  className = '',
}: {
  index: number;
  children: ReactNode;
  className?: string;
}) {
  const reduce = useReducedMotion();
  return (
    <motion.article
      initial={reduce ? false : { opacity: 0, y: 16 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, amount: 0.3 }}
      transition={{ duration: 0.25, delay: index * 0.06 }}
      className={className}
    >
      {children}
    </motion.article>
  );
}

/**
 * Bento Build Showcase — grid 3 kolom untuk tiga pilar sivitas akademika
 * (Design.md §C.23, §D.7, tech.md §6.10). Di bawah `lg` grid menjadi 1 kolom.
 */
export function BentoShowcase() {
  return (
    <div id="fitur">
      <header className="max-w-measure">
        <p className="ce-eyebrow">ARSITEKTUR EKOSISTEM 3-ARAH</p>
        <h2 className="mt-2 font-display text-web-h2 text-text-strong">
          Satu Jaringan Terpadu untuk Tiga Pilar Civitas Akademika
        </h2>
        <p className="mt-3 text-web-body text-text-body">
          Mahasiswa, driver rider, dan mitra UMKM kantin bekerja pada alur yang sama:
          pesanan dipesan dari kelas, diantar rider mahasiswa, dan dibayar langsung ke
          rekening stan.
        </p>
      </header>

      <div className="mt-5 grid gap-3 lg:grid-cols-3">
        <BentoCard index={0} className="ce-panel flex flex-col p-4">
          <div className="flex items-start justify-between gap-3">
            <p className="font-display text-micro uppercase text-primary">01 · MAHASISWA</p>
            <Icon name="school" size={24} className="text-primary" />
          </div>
          <h3 className="mt-2 font-display text-web-card-title text-text-strong">
            Pesan Tepat Sampai di Meja Kelas
          </h3>
          <p className="mt-2 flex-1 text-web-small text-text-body">
            Pilih kantin dan titik jemput dari landmark kampus, lalu pantau driver lewat
            peta isometrik sampai PIN serah terima diverifikasi.
          </p>
          <div className="mt-3">
            <EtaWidget />
          </div>
          <Link
            href="/#cara-kerja"
            className="ce-focus mt-3 inline-flex items-center gap-1 rounded font-display text-body-s font-semibold text-primary"
          >
            Lihat panduan pemesanan
            <Icon name="chevron_right" size={16} />
          </Link>
        </BentoCard>

        <BentoCard index={1} className="flex flex-col rounded-lg bg-primary p-4">
          <div className="flex items-start justify-between gap-3">
            <p className="font-display text-micro uppercase text-mint-300">
              02 · DRIVER RIDER
            </p>
            <Icon name="two_wheeler" size={24} className="text-white/80" />
          </div>
          <h3 className="mt-2 font-display text-web-card-title text-white">
            1-Click Order Radar Mahasiswa
          </h3>
          <p className="mt-2 flex-1 text-web-small text-white/80">
            Radar menampilkan jarak, estimasi waktu, dan nilai ongkir sebelum rider
            mengklaim pesanan di sela jeda kelas.
          </p>
          <div className="mt-3">
            <RevenueBox />
          </div>
          <Link
            href="/#driver"
            className="ce-focus mt-3 inline-flex items-center gap-1 rounded font-display text-body-s font-semibold text-mint-300"
          >
            Syarat pendaftaran driver
            <Icon name="chevron_right" size={16} />
          </Link>
        </BentoCard>

        <BentoCard index={2} className="ce-panel flex flex-col p-4">
          <div className="flex items-start justify-between gap-3">
            <p className="font-display text-micro uppercase text-primary">03 · MITRA UMKM</p>
            <Icon name="restaurant" size={24} className="text-primary" />
          </div>
          <h3 className="mt-2 font-display text-web-card-title text-text-strong">
            Harga Menu Tetap, Zero Markup
          </h3>
          <p className="mt-2 text-web-small text-text-body">
            Komisi stan 0% sehingga harga etalase kantin tidak pernah dinaikkan untuk
            menutup biaya platform.
          </p>
          <div className="mt-3 flex-1">
            <Checklist
              items={[
                'Etalase digital tetap memakai harga kantin asli',
                'Pencairan otomatis ke rekening stan tiap 18.00 WIB',
                'Kuota harian & varian rasa diatur dari dasbor merchant',
              ]}
            />
          </div>
          <Link
            href="/merchant/"
            className="ce-focus mt-3 inline-flex items-center gap-1 rounded font-display text-body-s font-semibold text-primary"
          >
            Daftarkan warung kantin
            <Icon name="chevron_right" size={16} />
          </Link>
        </BentoCard>
      </div>
    </div>
  );
}
