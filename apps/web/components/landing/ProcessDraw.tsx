'use client';

import { motion, useMotionValueEvent, useReducedMotion, useScroll } from 'framer-motion';
import { useRef, useState } from 'react';
import { Icon, type IconName } from '@/components/ui/Icon';

interface Step {
  no: string;
  title: string;
  body: string;
  tag: string;
  icon: IconName;
}

/** Workflow 4 langkah cepat (Design.md §C.23 "Workflow (Process Draw)"). */
const STEPS: Step[] = [
  {
    no: '01',
    title: 'Pilih Layanan & Titik Jemput',
    body: 'Pilih kantin, drop point lobi, atau lokasi kelas langsung dari peta landmark kampus.',
    tag: 'PRESET AKURAT',
    icon: 'location_on',
  },
  {
    no: '02',
    title: 'Pesan, Bayar, Pesanan Disiarkan',
    body: 'Pembayaran QRIS Dompet Kampus langsung diteruskan ke radar driver kampus terdekat.',
    tag: 'RESPON < 30 DETIK',
    icon: 'bolt',
  },
  {
    no: '03',
    title: 'Driver Klaim & Antar',
    body: 'Satu driver 1-klik claim membawa pesanan lewat rute isometrik paling presisi.',
    tag: 'PRESISI SELANG KELAS',
    icon: 'two_wheeler',
  },
  {
    no: '04',
    title: 'Serah Terima dengan PIN',
    body: 'Empat digit PIN memastikan pesanan tidak tertukar sebelum status dinyatakan selesai.',
    tag: '100% ANTI TERTUKAR',
    icon: 'verified_user',
  },
];

/**
 * Process Draw — garis progres terikat scroll di belakang tile nomor
 * (Design.md §D.3 & §D.7, tech.md §6.6). `pathLength` mengikuti
 * `scrollYProgress` pada offset `["start 80%", "end 40%"]`; tile nomor
 * berubah `mint-100 → mint-300` setelah garis melewatinya (150 ms).
 */
export function ProcessDraw() {
  const ref = useRef<HTMLDivElement>(null);
  const reduce = useReducedMotion();
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start 80%', 'end 40%'] });
  const [progress, setProgress] = useState(0);

  useMotionValueEvent(scrollYProgress, 'change', (value) => setProgress(value));

  const activeIndex = reduce
    ? STEPS.length
    : Math.min(STEPS.length, Math.max(1, Math.ceil(progress * STEPS.length)));

  return (
    <div ref={ref} className="relative">
      {/* Garis horizontal desktop: di belakang kartu, tepat di tengah tile nomor. */}
      <svg
        aria-hidden="true"
        viewBox="0 0 100 1"
        preserveAspectRatio="none"
        className="pointer-events-none absolute inset-x-0 z-0 hidden h-1 lg:block"
        style={{ top: 31 }}
      >
        <path
          d="M0 .5 H100"
          fill="none"
          stroke="#E3E7F4"
          strokeWidth={1}
          vectorEffect="non-scaling-stroke"
        />
        <motion.path
          d="M0 .5 H100"
          fill="none"
          stroke="#006C4A"
          strokeWidth={3}
          vectorEffect="non-scaling-stroke"
          style={{ pathLength: reduce ? 1 : scrollYProgress }}
        />
      </svg>

      {/* Garis vertikal mobile (satu kolom, tepat di tengah kolom tile nomor). */}
      <div
        aria-hidden="true"
        className="absolute bottom-0 left-[31px] top-0 z-0 w-[2px] overflow-hidden rounded-full bg-lav-300 md:hidden"
      >
        <motion.div
          className="h-full w-full origin-top bg-primary"
          style={{ scaleY: reduce ? 1 : scrollYProgress }}
        />
      </div>

      <ol className="relative z-10 grid gap-3 md:grid-cols-2 lg:grid-cols-4">
        {STEPS.map((step, index) => {
          const reached = index < activeIndex;
          return (
            <li key={step.no} className="ce-panel relative p-4 pt-14">
              <span
                aria-hidden="true"
                className={`absolute left-4 top-4 grid h-8 w-8 place-items-center rounded-md font-display text-h5 transition-colors duration-fast ease-emphasis ${
                  reached ? 'bg-mint-300 text-primary' : 'bg-mint-100 text-primary'
                }`}
              >
                {step.no}
              </span>
              <Icon
                name={step.icon}
                size={20}
                className="absolute right-4 top-4 text-primary"
              />
              <h3 className="font-display text-web-card-title text-text-strong">{step.title}</h3>
              <p className="mt-1.5 text-web-small text-text-body">{step.body}</p>
              <p className="mt-3 font-display text-micro uppercase text-primary">{step.tag}</p>
            </li>
          );
        })}
      </ol>
    </div>
  );
}
