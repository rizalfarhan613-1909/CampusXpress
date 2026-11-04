import type { Metadata } from 'next';
import { Inter, JetBrains_Mono, Plus_Jakarta_Sans } from 'next/font/google';
import './globals.css';

/**
 * Tipografi `docs/Design.md` §A.2: Plus Jakarta Sans (heading),
 * Inter (body), JetBrains Mono (ID order/plat/timer).
 */
const display = Plus_Jakarta_Sans({
  subsets: ['latin'],
  weight: ['600', '700', '800'],
  variable: '--font-display',
  display: 'swap',
});

const sans = Inter({
  subsets: ['latin'],
  variable: '--font-sans',
  display: 'swap',
});

const mono = JetBrains_Mono({
  subsets: ['latin'],
  weight: ['500', '700'],
  variable: '--font-mono',
  display: 'swap',
});

export const metadata: Metadata = {
  title: {
    default: 'Campus Express — Satu Aplikasi Terpadu untuk Ekosistem Kampus',
    template: '%s · Campus Express',
  },
  description:
    'Jastip kantin, nebeng kampus, dan kirim berkas dengan ongkir flat intra-kampus Rp 4.000 serta iuran pemeliharaan BEM hanya 0,5%.',
  applicationName: 'Campus Express',
  keywords: [
    'jastip kampus',
    'nebeng kampus',
    'kirim berkas kampus',
    'kantin kampus',
    'driver rider mahasiswa',
    'UMKM kampus',
  ],
  formatDetection: { telephone: false },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="id" className={`${display.variable} ${sans.variable} ${mono.variable}`}>
      <body>{children}</body>
    </html>
  );
}
