import Link from 'next/link';
import { Brand } from './Brand';

const COLUMNS = [
  {
    title: 'Layanan',
    links: [
      { href: '/#cara-kerja', label: 'Jastip Kantin' },
      { href: '/#cara-kerja', label: 'Nebeng Kampus' },
      { href: '/#cara-kerja', label: 'Kirim Berkas' },
      { href: '/#mitra', label: 'Katalog UMKM' },
    ],
  },
  {
    title: 'Untuk Sivitas',
    links: [
      { href: '/#driver', label: 'Daftar Driver Kampus' },
      { href: '/merchant/', label: 'Dasbor Merchant' },
      { href: '/admin/', label: 'Panel Admin BEM' },
      { href: '/r/DEMO12/', label: 'Program Referral' },
    ],
  },
] as const;

export function SiteFooter() {
  return (
    <footer className="border-t border-line-divider bg-surface">
      <div className="ce-container grid gap-8 py-8 md:grid-cols-3">
        <div>
          <Brand href="/" />
          <p className="mt-3 max-w-xs text-body-s text-text-muted">
            Satu aplikasi terpadu untuk jastip kantin, nebeng kampus, dan kirim berkas
            antar gedung. Ongkir flat Rp 4.000, iuran pemeliharaan BEM 0,5%.
          </p>
        </div>

        {COLUMNS.map((column) => (
          <div key={column.title}>
            <h4 className="text-h4">{column.title}</h4>
            <ul className="mt-3 space-y-2">
              {column.links.map((link) => (
                <li key={link.label}>
                  <Link
                    href={link.href}
                    className="ce-focus rounded text-body-s text-text-body transition-colors duration-fast hover:text-primary"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      <div className="border-t border-line-divider">
        <div className="ce-container flex flex-col gap-1 py-4 text-caption text-text-muted md:flex-row md:items-center md:justify-between">
          <p>© 2026 Campus Express · Biro Logistik BEM Kampus.</p>
          <p>
            Seluruh angka pada halaman ini adalah ilustrasi dan sedang menunggu verifikasi
            data resmi kampus.
          </p>
        </div>
      </div>
    </footer>
  );
}
