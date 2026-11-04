'use client';

import { AnimatePresence, motion } from 'framer-motion';
import { useEffect, useRef, useState } from 'react';
import { Icon } from '@/components/ui/Icon';
import { getPublic, gatewayConfigured } from '@/lib/gateway';

interface Ping {
  id: string;
  name: string;
  initial: string;
  label: string;
  route: string;
  ago: string;
}

/** Antrean cadangan bila Gateway belum dikonfigurasi (Design.md §C.23 "Toast aktivitas"). */
const DEMO_PINGS: Ping[] = [
  {
    id: 'demo-1',
    name: 'Rizal',
    initial: 'RZ',
    label: 'Nasi Ayam Geprek Sambal Matah',
    route: 'Kantin Rektorat → Lab Komputer 3',
    ago: '2m yang lalu',
  },
  {
    id: 'demo-2',
    name: 'Anisa',
    initial: 'AN',
    label: 'Soto Bening Spesial Ayam Kampung',
    route: 'Pujasera FST → Perpustakaan Pusat',
    ago: '4m yang lalu',
  },
  {
    id: 'demo-3',
    name: 'Daffa',
    initial: 'DF',
    label: 'Paket Hemat UKT (Geprek + Es Teh)',
    route: 'Kantin FEB → Lobi Barat FST',
    ago: '6m yang lalu',
  },
  {
    id: 'demo-4',
    name: 'Fahira',
    initial: 'FH',
    label: '3 Porsi Jastip Kelompok',
    route: 'Pujasera FST → Gedung FIKES',
    ago: '8m yang lalu',
  },
];

/**
 * Sales Pings — toast melayang di kiri bawah (Design.md §B.5, §D.5, §D.7).
 * Masuk 250 ms (`translateY 16 → 0` + `opacity`), tampil 4000 ms, keluar 250 ms,
 * satu toast per 6 detik. Tombol tutup langsung mematikan toast saat itu juga
 * dan menghentikan antrean berikutnya selama sesi.
 */
export function SalesPings({ pings }: { pings?: Ping[] }) {
  const queue = useRef<Ping[]>([]);
  const seen = useRef(new Set<string>());
  const [current, setCurrent] = useState<Ping | null>(null);
  const [muted, setMuted] = useState(false);

  useEffect(() => {
    if (muted) return undefined;
    const ctrl = new AbortController();

    const enqueue = (items: Ping[]) => {
      for (const item of items) {
        if (seen.current.has(item.id)) continue;
        seen.current.add(item.id);
        queue.current.push(item);
      }
    };

    if (pings?.length) {
      enqueue(pings);
    } else {
      // Rotasi data demo berulang agar tampilan selalu hidup saat offline.
      enqueue(DEMO_PINGS.map((ping, i) => ({ ...ping, id: `${ping.id}-awal-${i}` })));
      queue.current.push(
        ...DEMO_PINGS.map((ping, i) => ({ ...ping, id: `${ping.id}-antre-${i}` })),
      );
      const rotate = window.setInterval(() => {
        const next = {
          ...DEMO_PINGS[Math.floor(Math.random() * DEMO_PINGS.length)],
          id: `demo-${Date.now()}`,
        };
        if (queue.current.length < 4) queue.current.push(next);
      }, 24_000);
      return () => window.clearInterval(rotate);
    }

    if (gatewayConfigured) {
      const poll = async () => {
        try {
          const data = await getPublic<{ pings: Ping[] }>('/public/pings', ctrl.signal);
          enqueue(data.pings);
        } catch {
          // Tampilan dekoratif: kegagalan jaringan diabaikan.
        }
      };
      void poll();
      const pollTimer = window.setInterval(() => void poll(), 30_000);
      return () => {
        ctrl.abort();
        window.clearInterval(pollTimer);
      };
    }

    return () => ctrl.abort();
  }, [muted, pings]);

  useEffect(() => {
    if (muted) return undefined;
    const showTimer = window.setInterval(() => {
      const next = queue.current.shift();
      if (!next) return;
      setCurrent(next);
      window.setTimeout(
        () => setCurrent((active) => (active?.id === next.id ? null : active)),
        4000,
      );
    }, 6000);
    return () => window.clearInterval(showTimer);
  }, [muted]);

  return (
    <div
      aria-live="polite"
      aria-label="Aktivitas pesanan terbaru"
      className="pointer-events-none fixed bottom-4 left-4 z-40 max-w-[calc(100vw-2rem)]"
    >
      <AnimatePresence>
        {current && !muted ? (
          <motion.div
            key={current.id}
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 16, transition: { duration: 0.15 } }}
            transition={{ duration: 0.25, ease: [0.2, 0, 0, 1] }}
            className="pointer-events-auto flex w-[336px] max-w-[calc(100vw-2rem)] items-start gap-3 rounded-lg border border-line-subtle bg-surface p-3 shadow-float"
          >
            <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-mint-300 font-display text-caption font-bold text-mint-on">
              {current.initial}
            </span>
            <div className="min-w-0 flex-1">
              <p className="font-display text-micro uppercase text-text-muted">
                LIVE ACTIVITY · {current.ago}
              </p>
              <p className="mt-0.5 truncate text-caption font-bold text-text-strong">
                {current.name} baru saja pesan {current.label}
              </p>
              <p className="truncate text-caption text-text-muted">{current.route}</p>
            </div>
            <button
              type="button"
              aria-label="Tutup notifikasi aktivitas"
              onClick={() => {
                setCurrent(null);
                setMuted(true);
              }}
              className="ce-focus -mr-1 -mt-1 grid h-7 w-7 place-items-center rounded-full text-text-muted hover:bg-lav-200"
            >
              <Icon name="close" size={16} />
            </button>
          </motion.div>
        ) : null}
      </AnimatePresence>
    </div>
  );
}
