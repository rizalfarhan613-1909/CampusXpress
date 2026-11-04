'use client';

import Link from 'next/link';
import { useState } from 'react';
import { Badge } from '@/components/ui/Badge';
import { Icon } from '@/components/ui/Icon';
import { Toggle } from '@/components/ui/Toggle';
import { Panel, PanelHeader, TonalCard } from '@/components/ui/Panel';
import { KITCHEN_STATS } from '@/lib/demo-menu';
import { MERCHANT_ORDERS, MERCHANT_STORE, type MerchantOrder } from '@/lib/demo';
import { persen, rupiah } from '@/lib/format';

interface StockItem {
  id: string;
  name: string;
  sold: number;
  quota: number;
  available: boolean;
}

const STOK_AWAL: StockItem[] = [
  {
    id: 'MNU-001',
    name: 'Ayam Geprek Sambal Matah Spesial',
    sold: 32,
    quota: 50,
    available: true,
  },
  {
    id: 'MNU-002',
    name: 'Soto Bening Spesial Ayam Kampung',
    sold: 30,
    quota: 30,
    available: false,
  },
  {
    id: 'MNU-003',
    name: 'Paket Hemat UKT (Geprek + Es Teh)',
    sold: 18,
    quota: 40,
    available: true,
  },
];

/** Dasbor merchant — Design.md §C.12 (gambar 14). */
export default function MerchantDashboardPage() {
  const [tokoBuka, setTokoBuka] = useState(true);
  const [modeSibuk, setModeSibuk] = useState(true);
  const [orders, setOrders] = useState<MerchantOrder[]>(MERCHANT_ORDERS);
  const [stok, setStok] = useState<StockItem[]>(STOK_AWAL);

  const perluRespon = orders.filter((order) => order.status === 'HOT').length;
  const antrean = orders.filter(
    (order) => order.status === 'HOT' || order.status === 'COOKING',
  ).length;
  const siapPickup = orders.filter((order) => order.status === 'READY');

  const tandaiSiap = (id: string) =>
    setOrders((prev) =>
      prev.map((order) => (order.id === id ? { ...order, status: 'READY' } : order)),
    );

  const ubahStok = (id: string, available: boolean) =>
    setStok((prev) => prev.map((item) => (item.id === id ? { ...item, available } : item)));

  return (
    <div className="grid gap-4 lg:grid-cols-3">
      <div className="flex flex-col gap-4 lg:col-span-2">
        {/* Kartu toko */}
        <Panel className="flex items-center gap-3">
          <span className="grid h-14 w-14 shrink-0 place-items-center rounded-md bg-mint-100 font-display text-h2 text-primary">
            BS
          </span>
          <div className="min-w-0 flex-1">
            <p className="flex items-center gap-1.5 font-display text-h3 leading-tight">
              {MERCHANT_STORE.name}
              <Icon name="check_circle" size={16} className="text-primary" />
            </p>
            <p className="text-body-s text-text-muted">{MERCHANT_STORE.specialist}</p>
            <p className="mt-0.5 text-caption text-text-muted">{MERCHANT_STORE.location}</p>
          </div>
          <Link
            href="/merchant/settings/"
            aria-label="Buka pengaturan toko"
            className="ce-focus grid h-10 w-10 shrink-0 place-items-center rounded-md bg-lav-200 text-text-strong hover:bg-lav-300"
          >
            <Icon name="tune" size={20} />
          </Link>
        </Panel>

        {/* Status toko */}
        <section className="rounded-bento bg-primary p-4">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="flex items-center gap-2 font-display text-h3 text-white">
                <span className="h-2.5 w-2.5 animate-pulse-soft rounded-full bg-mint-300" />
                {tokoBuka ? 'TOKO BUKA' : 'TOKO TUTUP'}
              </p>
              <p className="mt-1 text-body-s text-white/80">
                {tokoBuka
                  ? 'Pesanan mahasiswa langsung diterima dapur pada jam operasional.'
                  : 'Etalase kantin disembunyikan dari katalog sampai dibuka kembali.'}
              </p>
            </div>
            <Toggle
              checked={tokoBuka}
              onChange={setTokoBuka}
              label="Buka atau tutup toko"
              tone="mint"
            />
          </div>

          <div
            className="mt-3 flex items-center justify-between gap-3 rounded-md p-3"
            style={{ backgroundColor: 'rgba(255,255,255,0.14)' }}
          >
            <label htmlFor="mode-sibuk" className="text-body-s text-white/90">
              <span className="font-semibold">Mode Sibuk Istirahat Kuliah</span>
              <span className="block text-caption text-white/70">
                Estimasi masak +5 menit otomatis saat kelas sedang padat.
              </span>
            </label>
            <input
              id="mode-sibuk"
              type="checkbox"
              checked={modeSibuk}
              onChange={(event) => setModeSibuk(event.target.checked)}
              className="ce-focus h-4 w-4 shrink-0 rounded-xs accent-white"
            />
          </div>
        </section>

        {/* Ringkasan dapur */}
        <Panel>
          <PanelHeader
            icon="restaurant"
            title="Ringkasan Dapur"
            description="Perhitungan sesi berjalan, tersinkron dengan kasir"
            badge={<Badge tone="mint">{KITCHEN_STATS.session}</Badge>}
          />

          <div className="rounded-bento bg-primary p-4">
            <p className="font-display text-micro uppercase text-white/70">Omzet sesi siang</p>
            <div className="mt-1 flex items-end justify-between gap-3">
              <p className="font-display text-h1 text-white">{rupiah(KITCHEN_STATS.revenue)}</p>
              <Badge tone="mint">+{persen(KITCHEN_STATS.revenueDeltaPersen)}</Badge>
            </div>
            <div className="mt-3 grid grid-cols-2 gap-2">
              <div
                className="rounded-md p-3"
                style={{ backgroundColor: 'rgba(255,255,255,0.14)' }}
              >
                <p className="text-caption text-white/70">Porsi terjual</p>
                <p className="font-display text-h3 text-white">{KITCHEN_STATS.portionsSold}</p>
              </div>
              <div
                className="rounded-md p-3"
                style={{ backgroundColor: 'rgba(255,255,255,0.14)' }}
              >
                <p className="text-caption text-white/70">Pembayaran non-tunai</p>
                <p className="font-display text-h3 text-white">
                  {KITCHEN_STATS.cashlessPersen}%
                </p>
              </div>
            </div>
          </div>

          <div className="mt-3 grid grid-cols-2 gap-3">
            <TonalCard className="flex items-center gap-3 bg-lav-100">
              <span className="grid h-10 w-10 shrink-0 place-items-center rounded-md bg-danger-container text-danger">
                <Icon name="notifications" size={22} />
              </span>
              <span>
                <span className="block text-caption text-text-muted">Perlu Respon</span>
                <span className="block font-display text-h1 text-text-strong">
                  {perluRespon}
                </span>
              </span>
            </TonalCard>
            <TonalCard className="flex items-center gap-3 bg-lav-100">
              <span className="grid h-10 w-10 shrink-0 place-items-center rounded-md bg-mint-100 text-primary">
                <Icon name="receipt_long" size={22} />
              </span>
              <span>
                <span className="block text-caption text-text-muted">Antrean</span>
                <span className="block font-display text-h1 text-text-strong">{antrean}</span>
              </span>
            </TonalCard>
          </div>
        </Panel>

        {/* Siap di-pickup */}
        <Panel className="flex items-center gap-3">
          <span className="grid h-12 w-12 shrink-0 place-items-center rounded-md bg-mint-100 text-primary">
            <Icon name="store" size={24} />
          </span>
          <div className="min-w-0 flex-1">
            <p className="font-display text-h5">Siap Di-pickup</p>
            <p className="text-caption text-text-muted">
              {siapPickup.length} pesanan menunggu diambil di etalase Stand 12
            </p>
          </div>
          <Link
            href="/merchant/orders/"
            className="ce-focus inline-flex h-9 shrink-0 items-center gap-1 rounded-md bg-lav-300 px-3 font-display text-caption font-semibold text-text-strong"
          >
            Lihat
            <Icon name="chevron_right" size={16} />
          </Link>
        </Panel>
      </div>

      <div className="flex flex-col gap-4">
        {/* Pesanan aktif dapur */}
        <Panel>
          <PanelHeader
            icon="restaurant"
            title="Pesanan Aktif Dapur"
            badge={
              <span className="flex items-center gap-1.5 whitespace-nowrap text-caption text-text-muted">
                <span className="h-2 w-2 rounded-full bg-danger" />
                Auto-refresh · 5s
              </span>
            }
          />

          <div className="space-y-3">
            {orders
              .filter((order) => order.status === 'HOT' || order.status === 'COOKING')
              .map((order) => (
                <article
                  key={order.id}
                  className="rounded-lg border border-line-subtle p-3 shadow-card"
                >
                  <header className="flex items-center justify-between gap-2">
                    <div>
                      <p className="font-mono text-micro text-text-muted">#{order.id}</p>
                      <p className="font-display text-h5">{order.customer}</p>
                    </div>
                    <Badge tone={order.status === 'HOT' ? 'danger' : 'lav'}>
                      {order.status === 'HOT' ? 'Baru' : 'Dimasak'}
                    </Badge>
                  </header>

                  <ul className="mt-2 space-y-1">
                    {order.items.map((item) => (
                      <li
                        key={`${order.id}-${item.name}`}
                        className="flex items-baseline justify-between gap-2 rounded-sm bg-lav-100 px-2 py-1.5"
                      >
                        <span className="text-body-s text-text-strong">
                          <span className="font-display font-bold text-primary">{item.qty}×</span>{' '}
                          {item.name}
                          {item.note ? (
                            <span className="block text-caption text-primary">{item.note}</span>
                          ) : null}
                        </span>
                        <span className="shrink-0 font-display text-h5">
                          {rupiah(item.price * item.qty)}
                        </span>
                      </li>
                    ))}
                  </ul>

                  <p className="mt-2 text-caption text-text-muted">Tujuan: {order.destination}</p>

                  {order.driver ? (
                    <div className="mt-2 flex items-center gap-3 rounded-md bg-lav-100 p-2.5">
                      <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-lav-300 font-display text-caption font-bold text-[#2F3B8F]">
                        BP
                      </span>
                      <span className="min-w-0">
                        <span className="block font-display text-h5">{order.driver.name}</span>
                        <span className="block text-caption text-text-muted">
                          {order.driver.note}
                        </span>
                      </span>
                    </div>
                  ) : null}

                  <button
                    type="button"
                    onClick={() => tandaiSiap(order.id)}
                    className="ce-focus mt-3 flex h-11 w-full items-center justify-center gap-2 rounded-md bg-lav-300 font-display text-body-m font-semibold text-text-strong transition duration-fast ease-emphasis hover:bg-lav-400 active:scale-[.98]"
                  >
                    <Icon name="check_circle" size={20} />
                    Tandai Siap Diambil Driver
                  </button>
                </article>
              ))}

            {orders.filter(
              (order) => order.status === 'HOT' || order.status === 'COOKING',
            ).length === 0 ? (
              <p className="rounded-md bg-lav-100 p-3 text-body-s text-text-muted">
                Tidak ada pesanan aktif. Semua pesanan sudah siap diambil.
              </p>
            ) : null}
          </div>
        </Panel>

        {/* Kontrol stok */}
        <Panel>
          <PanelHeader
            icon="tune"
            title="Kontrol Stok"
            description="Status ketersediaan tersinkron ke katalog mahasiswa"
            action={
              <Link
                href="/merchant/menu/"
                className="ce-focus shrink-0 rounded font-display text-caption font-semibold text-primary"
              >
                Kelola
              </Link>
            }
          />

          <ul className="space-y-3">
            {stok.map((item) => (
              <li
                key={item.id}
                className="flex items-center gap-3 rounded-md border border-line-subtle p-3"
              >
                <span
                  className={`grid h-12 w-12 shrink-0 place-items-center rounded-md bg-lav-200 font-display text-caption font-bold text-text-strong ${
                    item.available ? '' : 'opacity-60 grayscale'
                  }`}
                >
                  {item.id.slice(-3)}
                </span>
                <div className="min-w-0 flex-1">
                  <p
                    className={`text-body-s font-semibold text-text-strong ${
                      item.available ? '' : 'line-through decoration-danger'
                    }`}
                  >
                    {item.name}
                  </p>
                  <p
                    className={`text-caption ${
                      item.available ? 'text-primary' : 'text-danger'
                    }`}
                  >
                    {item.available
                      ? `Tersedia · Sisa ${item.quota - item.sold} porsi`
                      : 'Habis (tertutup di aplikasi)'}
                  </p>
                </div>
                <Toggle
                  checked={item.available}
                  onChange={(next) => ubahStok(item.id, next)}
                  label={`Ketersediaan ${item.name}`}
                />
              </li>
            ))}
          </ul>
        </Panel>
      </div>
    </div>
  );
}
