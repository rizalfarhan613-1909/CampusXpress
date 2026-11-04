'use client';

import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { useEffect, useState } from 'react';

/**
 * Word Rotator — Design.md §D.2 dan tech.md §6.2.
 *
 * Chip `primary` dengan teks putih, radius 12, padding 4/12, ukuran font sama
 * dengan `web-h1`. Lebar dikunci ke kata terpanjang (elemen `invisible`) agar
 * tidak ada layout shift saat kata berganti. Siklus 2400 ms, keluar/masuk 250 ms.
 */
export function WordRotator({
  words,
  interval = 2400,
  className = '',
}: {
  words: string[];
  interval?: number;
  className?: string;
}) {
  const reduce = useReducedMotion();
  const [index, setIndex] = useState(0);

  useEffect(() => {
    if (reduce || words.length < 2) return;
    const timer = window.setInterval(
      () => setIndex((value) => (value + 1) % words.length),
      interval,
    );
    return () => window.clearInterval(timer);
  }, [interval, reduce, words.length]);

  const widest = words.reduce((a, b) => (b.length > a.length ? b : a), '');

  return (
    <span
      aria-live="off"
      className={`relative inline-grid overflow-hidden rounded-md bg-primary px-3 py-1 align-middle font-display text-web-h1 text-on-primary max-lg:text-[32px] max-lg:leading-[38px] ${className}`}
    >
      {/* Lebar dikunci ke kata terpanjang supaya chip tidak berubah ukuran. */}
      <span className="invisible col-start-1 row-start-1 whitespace-nowrap" aria-hidden="true">
        {widest}
      </span>
      <span className="sr-only">{words[0]}</span>
      <AnimatePresence mode="wait" initial={false}>
        <motion.span
          key={words[index]}
          aria-hidden="true"
          className="col-start-1 row-start-1 whitespace-nowrap"
          initial={reduce ? false : { y: '100%', opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          exit={reduce ? undefined : { y: '-100%', opacity: 0 }}
          transition={{ duration: 0.25, ease: [0.2, 0, 0, 1] }}
        >
          {words[index]}
        </motion.span>
      </AnimatePresence>
    </span>
  );
}
