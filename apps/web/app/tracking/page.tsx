import type { Metadata } from 'next';
import Link from 'next/link';
import { BiddingBoard } from '@/components/bidding/BiddingBoard';
import { Brand } from '@/components/shell/Brand';

export const metadata: Metadata = {
  title: 'Lacak Order & Pilih Penawaran',
  description:
    'Papan Reverse Auction Campus Express: konsumen memilih penawaran driver berdasarkan harga, ETA, dan rating dengan rekomendasi jarak OSRM.',
};

/** Halaman status order + bidding (Fase 5). */
export default function TrackingPage() {
  return (
    <div className="min-h-screen bg-bg">
      <header className="sticky top-0 z-40 h-16 border-b border-line-divider bg-surface">
        <div className="ce-container flex h-16 items-center justify-between gap-3">
          <Brand href="/tracking/" />
          <Link href="/" className="ce-btn-tonal h-9 px-3 text-body-s">
            Beranda
          </Link>
        </div>
      </header>

      <main className="ce-container space-y-4 py-6">
        <div>
          <p className="ce-eyebrow">Reverse Auction</p>
          <h1 className="ce-title-section">Order &amp; Penawaran Driver</h1>
          <p className="mt-1 max-w-measure text-body-m text-text-body">
            Saat order berstatus <code className="font-mono text-mono">SEARCHING_BIDS</code>,
            penawaran driver tampil realtime. Konsumen bebas memilih harga, ETA,
            dan rating, lalu menekan <strong>TERIMA PENAWARAN</strong> untuk
            mengunci harga final dan memotong komisi 0,5% dari deposit driver.
          </p>
        </div>

        <BiddingBoard />
      </main>
    </div>
  );
}