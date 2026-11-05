'use client';

import { motion, useReducedMotion } from 'framer-motion';
import { useEffect, useState } from 'react';
import { Icon } from '@/components/ui/Icon';

export interface Hotspot {
  id: string;
  /** Posisi relatif terhadap bingkai perangkat (persen). */
  x: number;
  y: number;
  title: string;
  body: string;
}

/** Isi hotspot mengikuti Design.md §C.23 "Cursor Tour" dan §B.5 "Hotspot web". */
export const HOTSPOTS: Hotspot[] = [
  {
    id: 'radar',
    x: 50,
    y: 30,
    title: 'Hotspot 1: Radar Order 1-Klik',
    body: 'Driver kampus melihat jarak, estimasi waktu tempuh, dan nilai ongkir sebelum menekan satu tombol klaim.',
  },
  {
    id: 'chip',
    x: 34,
    y: 17,
    title: 'Hotspot 2: Pemilih Titik Jemput',
    body: 'Titik jemput terpilih otomatis memakai landmark kampus: Lobi Barat FST, kantin, hingga perpustakaan pusat.',
  },
  {
    id: 'wallet',
    x: 50,
    y: 48,
    title: 'Hotspot 3: Saldo Dompet Kampus',
    body: 'Saldo Rp 45.000 siap dipakai untuk ongkir flat Rp 4.000 dan top-up QRIS tanpa biaya admin.',
  },
  {
    id: 'chat',
    x: 38,
    y: 66,
    title: 'Hotspot 4: Chat Lobi',
    body: 'Koordinasi titik temu dengan driver langsung dari aplikasi, tanpa bertukar nomor pribadi.',
  },
];

/** Isi layar perangkat (bar atas, chip pos jemput, dompet, chat lobi, kartu mode kurir). */
function PhoneMock() {
  return (
    <div className="flex h-full w-full flex-col gap-2.5 bg-bg p-3">
      <div className="flex items-center justify-between font-mono text-micro text-text-strong">
        <span>09:41</span>
        <span className="text-caption font-sans text-text-muted">Eduroam UIN-Connect</span>
        <span className="flex items-center gap-1">
          <span className="h-1.5 w-1.5 rounded-full bg-primary-glow" />
          <span className="h-1.5 w-1.5 rounded-full bg-primary-glow" />
        </span>
      </div>

      <div className="flex flex-wrap gap-1.5">
        <span className="rounded-full bg-lav-300 px-2.5 py-1 text-caption text-text-strong">
          Lobi Barat FST
        </span>
        <span className="rounded-full bg-primary px-2.5 py-1 text-caption font-semibold text-on-primary">
          Kantin Rektorat
        </span>
        <span className="rounded-full bg-lav-300 px-2.5 py-1 text-caption text-text-strong">
          Perpustakaan Pusat
        </span>
      </div>

      <div className="rounded-lg bg-wallet p-3 text-white shadow-card">
        <p className="font-display text-micro uppercase text-white/70">Saldo Dompet Kampus</p>
        <div className="mt-0.5 flex items-end justify-between">
          <p className="font-display text-h2 text-white">
            <span className="text-h5 font-semibold">Rp </span>45.000
          </p>
          <span className="rounded-full bg-mint-300 px-2.5 py-1 font-display text-caption font-bold text-mint-on">
            Top-Up
          </span>
        </div>
      </div>

      <div className="flex flex-1 flex-col gap-2 rounded-lg bg-surface p-2.5 shadow-card">
        <p className="font-display text-caption font-bold text-text-strong">Chat Lobi</p>
        <p className="max-w-[85%] rounded-lg rounded-tl-sm bg-lav-300 px-2.5 py-1.5 text-caption text-text-strong">
          Saya sudah tiba di Lobi Barat FST.
        </p>
        <p className="ml-auto max-w-[85%] rounded-lg rounded-tr-sm bg-primary px-2.5 py-1.5 text-caption text-on-primary">
          Siap, PIN serah terima dikirim ya.
        </p>
        <div className="mt-auto grid grid-cols-4 gap-1">
          {['849', '2', '·', '·'].map((digit, idx) => (
            <span
              key={`${digit}-${idx}`}
              className="grid h-7 place-items-center rounded-sm bg-lav-200 font-display text-caption font-bold text-primary"
            >
              {digit}
            </span>
          ))}
        </div>
      </div>

      <div className="flex items-center justify-between rounded-lg bg-lav-100 px-2.5 py-2">
        <span className="flex items-center gap-2 text-caption font-semibold text-text-strong">
          <Icon name="verified_user" size={16} className="text-primary" />
          Mode Kurir Terverifikasi
        </span>
        <span className="font-mono text-micro text-text-muted">v2.4.0-LIGHT</span>
      </div>
    </div>
  );
}

/**
 * Cursor Tour — hotspot tooltip interaktif pada bingkai antarmuka perangkat
 * (Design.md §B.5 "Hotspot web", §C.23, dan §D.7).
 *
 * Tanpa interaksi, sorotan berpindah antar hotspot tiap 3000 ms dan berhenti
 * saat pengguna melakukan hover atau fokus. Navigasi keyboard memakai Tab.
 */
export function CursorTour({ hotspots = HOTSPOTS }: { hotspots?: Hotspot[] }) {
  const reduce = useReducedMotion();
  const [activeId, setActiveId] = useState<string>(hotspots[0]?.id ?? '');
  const [paused, setPaused] = useState(false);

  useEffect(() => {
    if (reduce || paused || hotspots.length < 2) return undefined;
    const timer = window.setInterval(() => {
      setActiveId((current) => {
        const index = hotspots.findIndex((item) => item.id === current);
        return hotspots[(index + 1) % hotspots.length].id;
      });
    }, 3000);
    return () => window.clearInterval(timer);
  }, [hotspots, paused, reduce]);

  const active = hotspots.find((item) => item.id === activeId) ?? hotspots[0];

  return (
    <div className="flex flex-col items-center gap-4 lg:flex-row lg:items-start lg:justify-center lg:gap-8">
      <div
        className="relative w-[286px] shrink-0 rounded-sheet border-[10px] border-ink-800 bg-ink-800 shadow-float sm:w-[310px]"
        onMouseEnter={() => setPaused(true)}
        onMouseLeave={() => setPaused(false)}
        onFocus={() => setPaused(true)}
        onBlur={() => setPaused(false)}
      >
        <div className="relative h-[520px] overflow-hidden rounded-[18px] bg-bg sm:h-[560px]">
          <PhoneMock />

          {hotspots.map((spot) => {
            const isActive = spot.id === activeId;
            return (
              <button
                key={spot.id}
                type="button"
                aria-label={spot.title}
                aria-pressed={isActive}
                onClick={() => setActiveId(spot.id)}
                onFocus={() => setActiveId(spot.id)}
                onMouseEnter={() => setActiveId(spot.id)}
                style={{ left: `${spot.x}%`, top: `${spot.y}%` }}
                className={`absolute z-20 -translate-x-1/2 -translate-y-1/2 rounded-full transition duration-fast ease-emphasis ${
                  isActive
                    ? 'h-6 w-6 bg-primary ring-4 ring-primary/25'
                    : 'h-5 w-5 bg-surface ring-2 ring-primary'
                }`}
              >
                <span className="sr-only">{spot.title}</span>
              </button>
            );
          })}

          {active ? (
            <motion.span
              key={`label-${active.id}`}
              initial={reduce ? false : { opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.25, ease: [0.2, 0, 0, 1] }}
              style={{
                left: `${Math.min(Math.max(active.x - 22, 4), 42)}%`,
                top: `${Math.min(active.y + 7, 84)}%`,
              }}
              className="pointer-events-none absolute z-30 inline-flex h-6 max-w-[92%] items-center gap-1 truncate rounded-full bg-ink-800 px-2.5 font-display text-micro uppercase text-white"
            >
              <Icon name="my_location" size={12} />
              {active.title.replace(/^Hotspot \d+: /, '')}
            </motion.span>
          ) : null}
        </div>
      </div>

      <div className="w-full max-w-sm">
        <p className="ce-eyebrow">Tur Antarmuka</p>
        <h3 className="mt-1 font-display text-web-h2 text-text-strong">
          Lihat alur aplikasi tanpa memasang apa pun
        </h3>
        <p className="mt-2 text-web-small text-text-body">
          Arahkan kursor atau tekan Tab untuk berpindah antar hotspot pada bingkai
          perangkat di samping.
        </p>

        <ul className="mt-4 space-y-2">
          {hotspots.map((spot) => {
            const isActive = spot.id === activeId;
            return (
              <li key={spot.id}>
                <button
                  type="button"
                  onClick={() => setActiveId(spot.id)}
                  aria-pressed={isActive}
                  className={`ce-focus flex w-full items-start gap-3 rounded-md border p-3 text-left transition duration-fast ease-emphasis ${
                    isActive
                      ? 'border-primary bg-mint-100'
                      : 'border-line-subtle bg-surface hover:bg-lav-100'
                  }`}
                >
                  <span
                    className={`mt-0.5 grid h-6 w-6 shrink-0 place-items-center rounded-full font-display text-micro ${
                      isActive ? 'bg-primary text-on-primary' : 'bg-lav-300 text-text-strong'
                    }`}
                  >
                    {hotspots.findIndex((item) => item.id === spot.id) + 1}
                  </span>
                  <span className="min-w-0">
                    <span className="block font-display text-web-card-title text-text-strong">
                      {spot.title.replace(/^Hotspot \d+: /, '')}
                    </span>
                    <span className="mt-0.5 block text-web-small text-text-body">{spot.body}</span>
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
      </div>
    </div>
  );
}
