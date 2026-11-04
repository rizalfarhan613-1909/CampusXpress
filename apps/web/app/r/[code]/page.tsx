import type { Metadata } from 'next';
import Link from 'next/link';
import { SimpanReferral } from '@/components/referral/SimpanReferral';
import { Icon } from '@/components/ui/Icon';

export const metadata: Metadata = {
  title: 'Undangan Referral Kampus',
  description:
    'Simpan kode undangan referral Campus Express lalu unduh aplikasi untuk mengaktifkan bebas ongkir.',
};

/** Kode pola `^[A-Z0-9]{6}$` (tech.md §6.8). */
const CODE_PATTERN = /^[A-Z0-9]{6}$/;

/**
 * Static export hanya membuat halaman untuk kode contoh di bawah.
 * Di produksi, kode arbitrer ditangani lewat Worker/CDN rewrite (tech.md §6.11).
 */
export const dynamicParams = false;

export function generateStaticParams() {
  return ['DEMO12', 'UIN201', 'FST112'].map((code) => ({ code }));
}

export default async function ReferralPage({
  params,
}: {
  params: Promise<{ code: string }>;
}) {
  const { code: rawCode } = await params;
  const code = rawCode.toUpperCase();
  const valid = CODE_PATTERN.test(code);

  return (
    <main className="ce-container flex min-h-screen items-center justify-center py-12">
      <div className="ce-panel w-full max-w-lg p-6 text-center">
        <span className="mx-auto grid h-12 w-12 place-items-center rounded-lg bg-primary text-white">
          <Icon name="bolt" size={26} filled />
        </span>
        <h1 className="mt-4 font-display text-h1">Undangan Referral Kampus</h1>

        {valid ? (
          <>
            <p className="mt-2 text-body-m text-text-body">
              Kamu diundang memakai kode{' '}
              <span className="font-mono text-body-m font-bold text-primary">{code}</span>.
              Ajak 3 teman kuliah dan dapatkan bebas ongkir 100% untuk pesanan berikutnya.
            </p>
            <SimpanReferral code={code} />
          </>
        ) : (
          <p role="alert" className="mt-2 text-body-m text-danger">
            Kode referral tidak dikenali. Kode harus terdiri dari 6 karakter huruf kapital
            atau angka.
          </p>
        )}

        <div className="mt-6 flex flex-col items-center gap-3 sm:flex-row sm:justify-center">
          <Link href="/#hero" className="ce-btn-primary w-full sm:w-auto">
            <Icon name="download" size={20} />
            Unduh Aplikasi (PWA)
          </Link>
          <Link href="/" className="ce-btn-tonal w-full sm:w-auto">
            Kembali ke Beranda
          </Link>
        </div>
      </div>
    </main>
  );
}
