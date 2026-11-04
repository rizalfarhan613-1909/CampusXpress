'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { Brand } from './Brand';
import { Icon } from '@/components/ui/Icon';

/** 5 tautan tengah navbar (Design.md §C.23). */
export const NAV_LINKS = [
  { href: '/#fitur', label: 'Fitur Utama' },
  { href: '/#mitra', label: 'Mitra UMKM' },
  { href: '/#driver', label: 'Driver Kampus' },
  { href: '/#komisi', label: 'Simulasi Komisi' },
  { href: '/#cara-kerja', label: 'Cara Kerja' },
] as const;

/**
 * Navbar sticky tinggi 64 `surface` dengan border bawah `divider`;
 * `shadow-card` muncul setelah scroll 8 px dalam 150 ms (Design.md §D.7).
 */
export function SiteNav() {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  return (
    <header
      className={`sticky top-0 z-50 h-16 border-b border-line-divider bg-surface transition-shadow duration-fast ${
        scrolled ? 'shadow-card' : 'shadow-none'
      }`}
    >
      <nav className="ce-container flex h-16 items-center justify-between gap-4">
        <Brand />

        <ul className="hidden items-center gap-6 lg:flex">
          {NAV_LINKS.map((link) => (
            <li key={link.href}>
              <Link
                href={link.href}
                className="ce-focus rounded text-body-s font-medium text-text-body transition-colors duration-fast hover:text-primary"
              >
                {link.label}
              </Link>
            </li>
          ))}
        </ul>

        <div className="flex items-center gap-2">
          <Link href="/#hero" className="ce-btn-primary h-10 px-4 text-body-m" style={{ boxShadow: 'none' }}>
            <Icon name="download" size={20} />
            <span className="hidden sm:inline">Download APK / Web App</span>
            <span className="sm:hidden">Unduh</span>
          </Link>
          <Link
            href="/merchant/"
            aria-label="Masuk akun merchant"
            className="ce-focus grid h-9 w-9 place-items-center rounded-full bg-primary font-display text-caption font-bold text-white"
          >
            RZ
          </Link>
          <button
            type="button"
            aria-expanded={open}
            aria-label={open ? 'Tutup menu' : 'Buka menu'}
            onClick={() => setOpen((v) => !v)}
            className="ce-focus grid h-10 w-10 place-items-center rounded-md bg-lav-200 text-text-strong lg:hidden"
          >
            <Icon name={open ? 'close' : 'menu'} size={22} />
          </button>
        </div>
      </nav>

      {open ? (
        <div className="border-b border-line-divider bg-surface shadow-card lg:hidden">
          <ul className="ce-container flex flex-col gap-1 py-3">
            {NAV_LINKS.map((link) => (
              <li key={link.href}>
                <Link
                  href={link.href}
                  onClick={() => setOpen(false)}
                  className="ce-focus block rounded-md px-3 py-2 text-body-m font-medium text-text-body hover:bg-lav-100"
                >
                  {link.label}
                </Link>
              </li>
            ))}
            <li className="mt-1 flex gap-2 border-t border-line-divider pt-3">
              <Link
                href="/merchant/"
                onClick={() => setOpen(false)}
                className="ce-btn-tonal flex-1"
              >
                <Icon name="store" size={20} /> Dasbor Merchant
              </Link>
              <Link href="/admin/" onClick={() => setOpen(false)} className="ce-btn-tonal flex-1">
                <Icon name="power" size={20} /> Panel Admin
              </Link>
            </li>
          </ul>
        </div>
      ) : null}
    </header>
  );
}
