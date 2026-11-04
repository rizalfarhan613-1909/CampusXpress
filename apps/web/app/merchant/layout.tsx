import type { ReactNode } from 'react';
import { ConsoleNav, type ConsoleNavItem } from '@/components/shell/ConsoleNav';

const MERCHANT_NAV: ConsoleNavItem[] = [
  { href: '/merchant/', label: 'Ringkasan Toko', icon: 'store' },
  { href: '/merchant/orders/', label: 'Dispatcher Pesanan', icon: 'restaurant' },
  { href: '/merchant/menu/', label: 'Kelola Menu', icon: 'receipt_long' },
  { href: '/merchant/settings/', label: 'Pengaturan Toko', icon: 'schedule' },
];

/** Kerangka dasbor merchant (Design.md §C.12, §C.13, §C.17, §C.21). */
export default function MerchantLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen bg-bg">
      <ConsoleNav
        items={MERCHANT_NAV}
        rolePill="Merchant · Stan #12 FST"
        homeHref="/merchant/"
      />
      <main className="ce-container py-6">{children}</main>
    </div>
  );
}
