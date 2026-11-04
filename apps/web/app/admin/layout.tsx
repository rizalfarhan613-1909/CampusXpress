import type { ReactNode } from 'react';
import { ConsoleNav, type ConsoleNavItem } from '@/components/shell/ConsoleNav';

const ADMIN_NAV: ConsoleNavItem[] = [
  { href: '/admin/', label: 'Panel Kontrol', icon: 'power' },
  { href: '/admin/#verifikasi', label: 'Antrean Verifikasi', icon: 'verified_user' },
  { href: '/admin/#tarif', label: 'Matriks Tarif', icon: 'tune' },
  { href: '/admin/#broadcast', label: 'Broadcast Darurat', icon: 'emergency' },
];

/** Kerangka panel admin BEM (Design.md §C.15, gambar 18 & 19). */
export default function AdminLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen bg-bg">
      <ConsoleNav
        items={ADMIN_NAV}
        rolePill="Admin · Biro Logistik BEM"
        homeHref="/admin/"
      />
      <main className="ce-container py-6">{children}</main>
    </div>
  );
}
