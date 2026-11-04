import type { ReactNode } from 'react';
import { SiteNav } from '@/components/shell/SiteNav';
import { SiteFooter } from '@/components/shell/SiteFooter';
import { SalesPings } from '@/components/landing/SalesPings';

/** Kerangka halaman pemasaran: navbar sticky + footer + toast aktivitas (Design.md §C.23). */
export default function MarketingLayout({ children }: { children: ReactNode }) {
  return (
    <>
      <a
        href="#konten"
        className="sr-only rounded-md bg-primary px-4 py-2 text-white focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-[60]"
      >
        Lewati ke konten utama
      </a>
      <SiteNav />
      <main id="konten">{children}</main>
      <SiteFooter />
      <SalesPings />
    </>
  );
}
