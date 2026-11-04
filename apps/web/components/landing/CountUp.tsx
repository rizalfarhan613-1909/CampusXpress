'use client';

import { useReducedMotion } from 'framer-motion';
import { useEffect, useRef, useState } from 'react';

/**
 * Count-Up — Design.md §D.6 & §D.7, tech.md §6.3.
 *
 * Animasi `0 → n` selama 1200 ms `ease-out-cubic`, dipicu sekali saat 40% kartu
 * terlihat (IntersectionObserver). Akhiran (`+`, `%`) ditambahkan setelah angka
 * selesai dihitung. `prefers-reduced-motion` menampilkan angka akhir langsung.
 */
export function CountUp({
  to,
  duration = 1200,
  suffix = '',
  decimals = 0,
  className = '',
}: {
  to: number;
  duration?: number;
  suffix?: string;
  decimals?: number;
  className?: string;
}) {
  const ref = useRef<HTMLSpanElement>(null);
  const reduce = useReducedMotion();
  const [value, setValue] = useState(0);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry?.isIntersecting) return;
        observer.disconnect();

        if (reduce) {
          setValue(to);
          return;
        }

        const start = performance.now();
        const tick = (now: number) => {
          const progress = Math.min((now - start) / duration, 1);
          setValue(to * (1 - Math.pow(1 - progress, 3)));
          if (progress < 1) window.requestAnimationFrame(tick);
        };
        window.requestAnimationFrame(tick);
      },
      { threshold: 0.4 },
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, [decimals, duration, reduce, to]);

  const formatted = new Intl.NumberFormat('id-ID', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(value);

  return (
    <span ref={ref} className={className}>
      {formatted}
      {suffix}
    </span>
  );
}
