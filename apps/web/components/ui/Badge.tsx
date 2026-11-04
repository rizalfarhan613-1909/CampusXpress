import type { ReactNode } from 'react';

type Tone = 'mint' | 'lav' | 'danger' | 'info' | 'ink' | 'outline';

const TONES: Record<Tone, string> = {
  mint: 'bg-mint-300 text-mint-on',
  lav: 'bg-lav-300 text-text-strong',
  danger: 'bg-danger-container text-danger',
  info: 'bg-info-100 text-info',
  ink: 'bg-ink-800 text-white',
  outline: 'border border-line-subtle bg-surface text-text-body',
};

/** Pill/badge kecil — Design.md §B.1/B.5 (`mint-300`, `lav-300`, `danger-container`). */
export function Badge({
  children,
  tone = 'mint',
  className = '',
}: {
  children: ReactNode;
  tone?: Tone;
  className?: string;
}) {
  return (
    <span
      className={`inline-flex h-6 shrink-0 items-center gap-1 rounded-full px-2.5 font-sans text-micro uppercase ${TONES[tone]} ${className}`}
    >
      {children}
    </span>
  );
}

/** Chip informasi tanpa huruf kapital (mis. "Flat Rp 4.000", "Titik Akurat"). */
export function Chip({
  children,
  tone = 'lav',
  className = '',
}: {
  children: ReactNode;
  tone?: Tone;
  className?: string;
}) {
  return (
    <span
      className={`inline-flex h-7 shrink-0 items-center gap-1 rounded-full px-3 font-sans text-caption ${TONES[tone]} ${className}`}
    >
      {children}
    </span>
  );
}
