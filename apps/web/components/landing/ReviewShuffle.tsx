'use client';

import { motion, useReducedMotion } from 'framer-motion';
import { useState } from 'react';
import { Icon } from '@/components/ui/Icon';

export interface Review {
  id: string;
  name: string;
  initial: string;
  role: 'Mahasiswa' | 'Driver Kampus' | 'Mitra UMKM';
  cohort: string;
  text: string;
  rating: number;
  source: string;
}

/** Testimoni otentik (Design.md §D.4 & §C.23, data contoh gambar 27). */
export const REVIEWS: Review[] = [
  {
    id: 'anisa',
    name: 'Anisa Rahmawati',
    initial: 'AR',
    role: 'Mahasiswa',
    cohort: 'Teknik Informatika 2021',
    text: 'Sebelum ada Campus Express saya harus turun ke kantin dan kehilangan satu sesi praktikum. Sekarang pesanan sampai di meja kelas dengan PIN serah terima, jadi tidak pernah tertukar.',
    rating: 5,
    source: 'Kantin Rektorat → Lab Komputer 3',
  },
  {
    id: 'daffa',
    name: 'Daffa Firdaus',
    initial: 'DF',
    role: 'Driver Kampus',
    cohort: 'FEB 2022',
    text: 'Radar order 1-klik membuat saya bisa mengambil pesanan di sela-sela jeda kuliah. Pendapatan hari ini cair langsung ke Dompet Kampus tanpa menunggu pencairan mingguan.',
    rating: 5,
    source: 'Pujasera FST → Lobi Barat FST',
  },
  {
    id: 'siti',
    name: 'Bu Siti Maryam',
    initial: 'SM',
    role: 'Mitra UMKM',
    cohort: 'Pemilik Kantin Rektorat',
    text: 'Harga menu saya tetap, tidak ada potongan komisi stan. Pesanan jastip masuk otomatis ke tiket dapur dan driver sudah standby sebelum masakan selesai.',
    rating: 5,
    source: 'Stan No. 12 · Pujasera FST',
  },
  {
    id: 'rahmat',
    name: 'Rahmat Hidayat',
    initial: 'RH',
    role: 'Mahasiswa',
    cohort: 'Teknik Sipil 2020',
    text: 'Mengirim berkas laporan ke gedung sebelah biasanya butuh 30 menit jalan kaki. Lewat Campus Express hanya Rp 6.000 dan sampai dalam 12 menit.',
    rating: 4,
    source: 'Gedung FST → Fakultas Teknik',
  },
  {
    id: 'nadia',
    name: 'Nadia Puspa',
    initial: 'NP',
    role: 'Driver Kampus',
    cohort: 'FIKES 2023',
    text: 'Verifikasi SIM dan kendaraan lewat panel admin BEM cukup cepat. Peta isometrik kampus sangat membantu saat hujan karena rute sudah ditentukan.',
    rating: 5,
    source: 'Perpustakaan Pusat → Asrama Timur',
  },
  {
    id: 'bayu',
    name: 'Bayu Pratama',
    initial: 'BP',
    role: 'Driver Kampus',
    cohort: 'FST 2022',
    text: 'Subsidi ongkir dari iuran 0,5% membuat harga tetap ramah di kantong mahasiswa, tapi pendapatan rider tetap utuh karena tidak ada potongan tersembunyi.',
    rating: 5,
    source: 'Pujasera FST → Gedung FEB',
  },
];

function Stars({ rating }: { rating: number }) {
  return (
    <span className="flex items-center gap-0.5" aria-label={`Rating ${rating} dari 5`}>
      {Array.from({ length: 5 }, (_, index) => (
        <Icon
          key={index}
          name="star"
          size={16}
          filled={index < rating}
          className={index < rating ? 'text-star' : 'text-lav-400'}
        />
      ))}
    </span>
  );
}

function ReviewCard({ review, className = '' }: { review: Review; className?: string }) {
  return (
    <article className={`flex h-full flex-col rounded-lg border border-line-subtle bg-surface p-4 shadow-card ${className}`}>
      <header className="flex items-start gap-3">
        <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-lav-300 font-display text-caption font-bold text-[#2F3B8F]">
          {review.initial}
        </span>
        <div className="min-w-0 flex-1">
          <h3 className="font-display text-h5 text-text-strong">{review.name}</h3>
          <p className="text-caption text-text-muted">
            {review.cohort} · {review.role}
          </p>
        </div>
        <Stars rating={review.rating} />
      </header>

      <p className="mt-3 flex-1 text-body-m text-text-body">{review.text}</p>

      <footer className="mt-3 flex items-center gap-1.5 text-caption text-primary">
        <Icon name="store" size={16} />
        {review.source}
      </footer>
    </article>
  );
}

/**
 * Review Shuffle — grid 3 kolom pada `lg` ke atas dan tumpukan kartu yang dapat
 * digeser di bawah `lg` (Design.md §D.4 & §C.23).
 *
 * Geser melewati 100 px atau kecepatan 500 px/dtk: kartu keluar 250 ms lalu
 * berpindah ke dasar tumpukan; bila di bawah ambang, kartu kembali dengan
 * spring (`stiffness 300, damping 26`).
 */
export function ReviewShuffle({ reviews = REVIEWS }: { reviews?: Review[] }) {
  const reduce = useReducedMotion();
  const [order, setOrder] = useState<string[]>(() => reviews.map((review) => review.id));
  const [flying, setFlying] = useState<{ id: string; dir: number } | null>(null);

  const byId = new Map(reviews.map((review) => [review.id, review]));
  const rotate = () => setOrder(([first, ...rest]) => [...rest, first]);

  const shuffleAll = () =>
    setOrder((current) => {
      const next = [...current];
      for (let i = next.length - 1; i > 0; i -= 1) {
        const j = Math.floor(Math.random() * (i + 1));
        const temp = next[i];
        next[i] = next[j];
        next[j] = temp;
      }
      return next;
    });

  const stacked = order
    .slice(0, 4)
    .map((id) => byId.get(id))
    .filter((review): review is Review => Boolean(review));

  return (
    <div className="mx-auto max-w-[1100px]">
      {/* Tumpukan geser (mobile & tablet) */}
      <div className="relative mx-auto h-[360px] w-full max-w-sm lg:hidden">
        {stacked.map((review, depth) => {
          const isTop = depth === 0;
          const isFlying = flying?.id === review.id;
          return (
            <motion.div
              key={review.id}
              drag={isTop && !reduce ? 'x' : false}
              dragMomentum={false}
              onDragEnd={(_, info) => {
                const passed = Math.abs(info.offset.x) > 100 || Math.abs(info.velocity.x) > 500;
                if (!passed) return;
                if (reduce) {
                  rotate();
                  return;
                }
                const dir = info.offset.x >= 0 ? 1 : -1;
                setFlying({ id: review.id, dir });
                window.setTimeout(() => {
                  rotate();
                  setFlying(null);
                }, 250);
              }}
              animate={
                isFlying && flying
                  ? { x: flying.dir * 320, rotate: flying.dir * 8, opacity: 0, scale: 1, y: 0 }
                  : { x: 0, rotate: 0, scale: 1 - depth * 0.05, y: depth * 14, opacity: 1 - depth * 0.2 }
              }
              transition={
                isFlying
                  ? { duration: 0.25, ease: 'easeIn' }
                  : { type: 'spring', stiffness: 300, damping: 26 }
              }
              style={{ zIndex: 10 - depth, cursor: isTop ? 'grab' : 'default' }}
              className="absolute inset-0 touch-pan-y"
            >
              <ReviewCard review={review} />
            </motion.div>
          );
        })}

        <div className="absolute -bottom-12 left-0 right-0 flex items-center justify-between">
          <button
            type="button"
            onClick={rotate}
            className="ce-focus inline-flex h-10 items-center gap-2 rounded-md bg-lav-300 px-3 font-display text-body-s font-semibold text-text-strong"
          >
            <Icon name="arrow_forward" size={18} />
            Ulasan berikutnya
          </button>
          <button
            type="button"
            onClick={shuffleAll}
            className="ce-focus inline-flex h-10 items-center gap-2 rounded-md bg-surface px-3 font-display text-body-s font-semibold text-primary shadow-card"
          >
            <Icon name="sync" size={18} />
            Acak ulasan
          </button>
        </div>
      </div>

      <p className="mt-16 text-center text-caption text-text-muted lg:hidden">
        Geser kartu teratas ke kiri atau kanan untuk melihat ulasan berikutnya.
      </p>

      {/* Grid 3 kolom (desktop) */}
      <ul className="hidden gap-3 lg:grid lg:grid-cols-3">
        {reviews.map((review, index) => (
          <motion.li
            key={review.id}
            initial={reduce ? false : { opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, amount: 0.3 }}
            transition={{ duration: 0.25, delay: index * 0.06 }}
          >
            <ReviewCard review={review} className="h-full" />
          </motion.li>
        ))}
      </ul>
    </div>
  );
}
