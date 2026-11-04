import type { Metadata } from 'next';
import Link from 'next/link';
import { HeroReferralBanner } from '@/components/landing/HeroReferralBanner';
import { WordRotator } from '@/components/landing/WordRotator';
import { StatsStrip } from '@/components/landing/StatsStrip';
import { BentoShowcase } from '@/components/landing/BentoShowcase';
import { ProcessDraw } from '@/components/landing/ProcessDraw';
import { PriceRoll } from '@/components/landing/PriceRoll';
import { CursorTour } from '@/components/landing/CursorTour';
import { ReviewShuffle } from '@/components/landing/ReviewShuffle';
import { Icon, type IconName } from '@/components/ui/Icon';

export const metadata: Metadata = {
  title: 'Satu Aplikasi Terpadu untuk Ekosistem Kampus',
  description:
    'Jastip kantin, nebeng kampus, dan kirim berkas dalam satu aplikasi. Ongkir flat Rp 4.000, komisi stan 0%, dan iuran pemeliharaan BEM hanya 0,5%.',
};

const TRUST: { id: string; icon: IconName; text: string }[] = [
  { id: 'rating', icon: 'star', text: '4,9/5 dari 10.000+ mahasiswa (ilustrasi)' },
  { id: 'sso', icon: 'verified_user', text: 'Terintegrasi SSO kampus resmi (NIM valid)' },
  { id: 'kampus', icon: 'school', text: 'Direncanakan aktif di UIN, UI, ITB, & UGM' },
];

/** Kata Word Rotator hero (Design.md §D.2): Jastip Kantin, Nebeng Kampus, Kirim Berkas. */
const HERO_WORDS = ['Jastip Kantin', 'Nebeng Kampus', 'Kirim Berkas'];

const MERCHANT_BENEFITS = [
  'Komisi stan 0% — harga etalase kantin tidak pernah dinaikkan',
  'Kuota harian, varian rasa, dan status buka diatur dari dasbor',
  'Pencairan otomatis ke rekening BSI stan setiap 18.00 WIB',
];

const DRIVER_METRICS = [
  { id: 'income', label: 'Pendapatan hari ini', value: 'Rp 84.500' },
  { id: 'claim', label: 'Waktu klaim order', value: '< 5 detik' },
  { id: 'route', label: 'Jarak rata-rata rute', value: '800 m' },
  { id: 'rating', label: 'Rating rider', value: '4,9 / 5' },
];

export default function LandingPage() {
  return (
    <>
      {/* ---------------- Hero ---------------- */}
      <section id="hero" className="ce-container scroll-mt-20 pb-12 pt-8">
        <div className="flex flex-col items-center text-center">
          <HeroReferralBanner />

          <h1 className="mx-auto mt-5 max-w-4xl font-display text-web-h1 text-text-strong">
            Satu Aplikasi Terpadu untuk <WordRotator words={HERO_WORDS} />
          </h1>

          <p className="mx-auto mt-4 max-w-measure text-web-body text-text-body">
            Pesan makanan kantin, titip beli antar kelas, atau kirim berkas ke gedung
            sebelah tanpa keluar dari ruang kuliah. Ongkir dihitung flat dari landmark
            kampus dan diteruskan ke rider mahasiswa terverifikasi.
          </p>

          <div className="mt-6 flex w-full flex-col items-center gap-3 sm:w-auto sm:flex-row">
            <Link href="/#hero" className="ce-btn-primary w-full sm:w-auto">
              Mulai Pakai Sekarang (PWA)
              <Icon name="arrow_forward" size={20} />
            </Link>
            <Link
              href="#driver"
              className="ce-focus inline-flex h-12 w-full items-center justify-center gap-2 rounded-lg border border-line-subtle bg-surface px-4 font-display text-h4 text-text-strong transition duration-fast ease-emphasis hover:bg-lav-100 sm:w-auto"
            >
              <Icon name="two_wheeler" size={20} />
              Daftar Driver Kampus
            </Link>
          </div>

          <ul className="mt-6 flex flex-wrap items-center justify-center gap-x-6 gap-y-2">
            {TRUST.map((item) => (
              <li
                key={item.id}
                className="flex items-center gap-1.5 text-caption text-text-muted"
              >
                <Icon name={item.icon} size={14} className="text-primary" />
                {item.text}
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* ---------------- Statistik count-up ---------------- */}
      <section id="statistik" aria-label="Statistik ekosistem" className="ce-container pb-12">
        <StatsStrip />
        <p className="mt-2 text-caption text-text-muted">
          Angka di atas adalah target ilustratif peluncuran perdana dan belum
          diverifikasi lembaga resmi kampus.
        </p>
      </section>

      {/* ---------------- Bento Build Showcase ---------------- */}
      <section className="ce-container scroll-mt-20 border-t border-line-divider py-10">
        <BentoShowcase />
      </section>

      {/* ---------------- Mitra UMKM ---------------- */}
      <section id="mitra" className="ce-container scroll-mt-20 border-t border-line-divider py-10">
        <div className="grid gap-6 lg:grid-cols-2 lg:items-center">
          <div>
            <p className="ce-eyebrow">UNTUK MITRA UMKM</p>
            <h2 className="ce-title-section mt-2">
              Etalase digital tanpa biaya komisi stan
            </h2>
            <p className="mt-3 max-w-measure text-web-body text-text-body">
              Kantin tidak perlu menaikkan harga atau memotong porsi. Pesanan masuk ke
              tiket dapur, lalu dipilih apakah diantar driver kampus atau diambil sendiri.
            </p>
            <ul className="mt-4 space-y-2">
              {MERCHANT_BENEFITS.map((benefit) => (
                <li
                  key={benefit}
                  className="flex items-start gap-2 text-web-small text-text-body"
                >
                  <Icon name="check_circle" size={18} className="mt-0.5 shrink-0 text-primary" />
                  <span>{benefit}</span>
                </li>
              ))}
            </ul>
            <Link href="/merchant/" className="ce-btn-primary mt-5">
              <Icon name="store" size={20} />
              Buka Dasbor Merchant
            </Link>
          </div>

          <div className="ce-panel p-4">
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="font-display text-h4">Kantin Bu Siti</p>
                <p className="text-caption text-text-muted">Pujasera FST · Stan No. 12</p>
              </div>
              <span className="inline-flex h-7 shrink-0 items-center gap-1.5 rounded-full bg-mint-300 px-3 font-display text-caption font-bold text-mint-on">
                <span className="h-2 w-2 rounded-full bg-primary-pressed" />
                TOKO BUKA
              </span>
            </div>

            <div className="mt-3 grid grid-cols-2 gap-2">
              <div className="rounded-md bg-lav-300 p-3">
                <p className="font-display text-micro uppercase text-text-muted">
                  Omzet sesi siang
                </p>
                <p className="mt-1 font-display text-h2 text-text-strong">Rp 1.875.000</p>
              </div>
              <div className="rounded-md bg-lav-300 p-3">
                <p className="font-display text-micro uppercase text-text-muted">Perlu respon</p>
                <p className="mt-1 font-display text-h2 text-danger">3</p>
              </div>
            </div>

            <ul className="mt-3 space-y-2">
              {[
                { id: 'CX-9092', detail: '2 menu · Jastip → Lab Komputer 3', label: 'Baru' },
                { id: 'CX-9089', detail: '5 menu · Driver standby di loket', label: 'Dimasak' },
              ].map((order) => (
                <li
                  key={order.id}
                  className="flex items-center justify-between gap-3 rounded-md border border-line-subtle p-3"
                >
                  <div className="min-w-0">
                    <p className="font-mono text-micro text-text-muted">#{order.id}</p>
                    <p className="truncate text-body-s text-text-strong">{order.detail}</p>
                  </div>
                  <span className="inline-flex h-6 shrink-0 items-center rounded-full bg-lav-200 px-2.5 font-display text-micro uppercase text-text-strong">
                    {order.label}
                  </span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {/* ---------------- Driver Kampus ---------------- */}
      <section id="driver" className="ce-container scroll-mt-20 border-t border-line-divider py-10">
        <div className="ce-panel grid gap-6 p-5 lg:grid-cols-2 lg:items-center">
          <div>
            <p className="ce-eyebrow">UNTUK DRIVER KAMPUS</p>
            <h2 className="ce-title-section mt-2">
              Penghasilan tambahan tanpa mengganggu jadwal kelas
            </h2>
            <p className="mt-3 max-w-measure text-web-body text-text-body">
              Ambil pesanan hanya pada jeda kuliah. Radar 1-klik menampilkan jarak,
              tujuan, dan nilai ongkir sebelum rider memutuskan mengambil order.
            </p>
            <ul className="mt-4 space-y-2">
              {[
                'Verifikasi KTM, SIM C, dan kendaraan oleh admin BEM',
                'Komisi 0% untuk rider — 100% ongkir cair ke Dompet Kampus',
                'Batas maksimal 3 order aktif agar kuliah tetap prioritas',
              ].map((point) => (
                <li key={point} className="flex items-start gap-2 text-web-small text-text-body">
                  <Icon name="check_circle" size={18} className="mt-0.5 shrink-0 text-primary" />
                  <span>{point}</span>
                </li>
              ))}
            </ul>
            <div className="mt-5 flex flex-wrap gap-3">
              <Link href="#hero" className="ce-btn-primary">
                <Icon name="download" size={20} />
                Unduh & Ajukan Verifikasi
              </Link>
              <Link href="/admin/" className="ce-btn-tonal">
                <Icon name="verified_user" size={20} />
                Lihat Antrean Verifikasi
              </Link>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-2">
            {DRIVER_METRICS.map((metric) => (
              <div key={metric.id} className="rounded-md bg-lav-300 p-3">
                <p className="font-display text-micro uppercase text-text-muted">
                  {metric.label}
                </p>
                <p className="mt-1 font-display text-h2 text-text-strong">{metric.value}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ---------------- Simulasi Komisi (Price Roll) ---------------- */}
      <section id="komisi" className="ce-container scroll-mt-20 border-t border-line-divider py-10">
        <header className="mx-auto max-w-measure text-center">
          <p className="ce-eyebrow">PERBANDINGAN NYATA</p>
          <h2 className="ce-title-section mt-2">Hitung Penghematan Uang Saku Mahasiswa</h2>
          <p className="mt-3 text-web-body text-text-body">
            Pilih skenario pesanan untuk melihat selisih biaya antara aplikasi komersial
            umum dan Campus Express.
          </p>
        </header>
        <div className="mt-6">
          <PriceRoll />
        </div>
      </section>

      {/* ---------------- Workflow (Process Draw) ---------------- */}
      <section
        id="cara-kerja"
        className="ce-container scroll-mt-20 border-t border-line-divider py-10"
      >
        <header className="mx-auto max-w-measure text-center">
          <p className="ce-eyebrow">WORKFLOW CEPAT</p>
          <h2 className="ce-title-section mt-2">
            Empat langkah dari pesan sampai diterima
          </h2>
          <p className="mt-3 text-web-body text-text-body">
            Setiap langkah tercatat sebagai event order sehingga dapat diaudit bila terjadi
            dispute antara mahasiswa, driver, dan mitra kantin.
          </p>
        </header>
        <div className="mt-6">
          <ProcessDraw />
        </div>
      </section>

      {/* ---------------- Cursor Tour ---------------- */}
      <section id="tur" className="ce-container scroll-mt-20 border-t border-line-divider py-10">
        <header className="mx-auto mb-6 max-w-measure text-center">
          <p className="ce-eyebrow">PREVIEW ANTARMUKA</p>
          <h2 className="ce-title-section mt-2">Kenali layar aplikasi sebelum mengunduh</h2>
        </header>
        <CursorTour />
      </section>

      {/* ---------------- Testimoni ---------------- */}
      <section
        id="testimoni"
        className="ce-container scroll-mt-20 border-t border-line-divider py-10"
      >
        <header className="mx-auto mb-6 max-w-measure text-center">
          <p className="ce-eyebrow">TESTIMONI OTENTIK</p>
          <h2 className="ce-title-section mt-2">
            Cerita mahasiswa, rider, dan pemilik kantin
          </h2>
          <p className="mt-3 text-web-body text-text-body">
            Ulasan dikumpulkan setelah pesanan berstatus selesai sehingga hanya pembeli
            sungguhan yang dapat memberi penilaian.
          </p>
        </header>
        <ReviewShuffle />
      </section>

      {/* ---------------- Ajakan akhir ---------------- */}
      <section className="ce-container pb-12">
        <div className="rounded-xl bg-primary px-5 py-8 text-center">
          <h2 className="font-display text-web-h2 text-white">
            Siap memindahkan antrean kantin ke ruang kelas?
          </h2>
          <p className="mx-auto mt-3 max-w-measure text-web-body text-white/80">
            Unduh PWA, verifikasi NIM sekali lewat SSO kampus, lalu nikmati ongkir flat
            Rp 4.000 untuk seluruh rute intra-kampus.
          </p>
          <div className="mt-5 flex flex-col items-center justify-center gap-3 sm:flex-row">
            <Link
              href="#hero"
              className="ce-focus inline-flex h-12 items-center gap-2 rounded-lg bg-surface px-5 font-display text-h4 text-primary transition duration-fast ease-emphasis hover:bg-mint-100"
            >
              Mulai Pakai Sekarang (PWA)
              <Icon name="arrow_forward" size={20} />
            </Link>
            <Link
              href="/admin/"
              className="ce-focus inline-flex h-12 items-center gap-2 rounded-lg border border-white/40 px-5 font-display text-h4 text-white transition duration-fast ease-emphasis hover:bg-white/10"
            >
              <Icon name="power" size={20} />
              Panel Admin BEM
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}
