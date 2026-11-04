'use client';

import { useState } from 'react';
import { Badge, Chip } from '@/components/ui/Badge';
import { Icon } from '@/components/ui/Icon';
import { Toggle } from '@/components/ui/Toggle';
import { Callout, Panel, PanelHeader } from '@/components/ui/Panel';
import { MERCHANT_ORDERS, MERCHANT_STORE } from '@/lib/demo';
import { rupiah } from '@/lib/format';

type Method = 'SELF' | 'BROADCAST';

const MITRA_STANDBY = [
  { id: 'bayu', name: 'Bayu Pratama', meta: 'FST 2022 · 50 m', initial: 'BP' },
  { id: 'nadia', name: 'Nadia Puspa', meta: 'FIKES 2023 · 180 m', initial: 'NP' },
];

/** Dispatcher pesanan merchant — Design.md §C.13 (gambar 16). */
export default function MerchantOrdersPage() {
  const [orderId, setOrderId] = useState<string>(MERCHANT_ORDERS[0].id);
  const [method, setMethod] = useState<Method>('BROADCAST');
  const [tip, setTip] = useState(true);
  const [broadcasted, setBroadcasted] = useState(false);

  const order = MERCHANT_ORDERS.find((item) => item.id === orderId) ?? MERCHANT_ORDERS[0];
  const jumlahMenu = order.items.reduce((sum, item) => sum + item.qty, 0);

  return (
    <div className="mx-auto max-w-3xl space-y-4">
      {/* Kartu header */}
      <Panel>
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div className="min-w-0">
            <p className="font-display text-micro uppercase text-text-muted">
              #{order.id} · {MERCHANT_STORE.name}
            </p>
            <h1 className="mt-1 font-display text-h4">{order.destination}</h1>
            <p className="text-body-s text-text-muted">
              Dipesan {order.placedAgo} oleh {order.customer}
            </p>
          </div>
          <div className="flex flex-col items-end gap-2">
            <Badge tone="mint">Siap Dispatch</Badge>
            <span className="rounded-md bg-lav-300 px-3 py-1.5 text-caption text-text-strong">
              Selesai masak 3 menit lalu
            </span>
          </div>
        </div>

        <label htmlFor="pilih-order" className="ce-label mt-4">
          Pilih tiket pesanan
        </label>
        <select
          id="pilih-order"
          value={orderId}
          onChange={(event) => {
            setOrderId(event.target.value);
            setBroadcasted(false);
          }}
          className="ce-focus h-12 w-full rounded-md bg-lav-200 px-3 font-sans text-body-m text-text-strong"
        >
          {MERCHANT_ORDERS.map((item) => (
            <option key={item.id} value={item.id}>
              #{item.id} · {item.customer} · {rupiah(item.total)}
            </option>
          ))}
        </select>
      </Panel>

      {/* Rincian paket */}
      <Panel>
        <PanelHeader
          icon="restaurant"
          title="Rincian Paket"
          badge={<Chip tone="lav">{jumlahMenu} menu</Chip>}
        />

        <ul className="space-y-2">
          {order.items.map((item) => (
            <li
              key={`${order.id}-${item.name}`}
              className="flex items-start justify-between gap-3 rounded-md bg-lav-100 p-3"
            >
              <span className="flex min-w-0 items-start gap-3">
                <span className="font-display text-h3 text-primary">{item.qty}×</span>
                <span className="min-w-0">
                  <span className="block font-display text-h5">{item.name}</span>
                  {item.note ? (
                    <span className="block text-caption text-primary">{item.note}</span>
                  ) : null}
                </span>
              </span>
              <span className="shrink-0 font-display text-h5">
                {rupiah(item.price * item.qty)}
              </span>
            </li>
          ))}
        </ul>

        <div className="mt-3 grid gap-2 sm:grid-cols-2">
          <div className="rounded-md bg-lav-100 p-3">
            <p className="text-caption text-text-muted">Segel higienis</p>
            <p className="font-display text-h5 text-primary">Tersegel · Dikunci rider</p>
          </div>
          <div className="rounded-md bg-lav-100 p-3">
            <p className="text-caption text-text-muted">Total &amp; pembayaran</p>
            <p className="font-display text-h5">
              {rupiah(order.total)}{' '}
              <span className={order.paid ? 'text-primary' : 'text-danger'}>
                · {order.paid ? 'Lunas QRIS' : 'Belum dibayar'}
              </span>
            </p>
          </div>
        </div>

        <div className="mt-3">
          <Callout>
            Pesanan aman untuk diantar karena pembayaran sudah diterima penuh sebelum
            driver berangkat dari etalase.
          </Callout>
        </div>
      </Panel>

      {/* Metode dispatch */}
      <Panel>
        <PanelHeader
          icon="my_location"
          title="Pilih Metode Dispatch"
          description="Tentukan siapa yang mengantar pesanan ini"
        />

        <div className="grid gap-3 sm:grid-cols-2">
          <button
            type="button"
            aria-pressed={method === 'BROADCAST'}
            onClick={() => setMethod('BROADCAST')}
            className={`ce-focus relative rounded-lg p-4 text-left transition duration-fast ease-emphasis ${
              method === 'BROADCAST'
                ? 'border-2 border-primary'
                : 'border-2 border-line-subtle hover:border-lav-400'
            } bg-surface`}
          >
            {method === 'BROADCAST' ? (
              <Icon
                name="check_circle"
                size={28}
                filled
                className="absolute right-3 top-3 text-primary"
              />
            ) : (
              <span
                aria-hidden="true"
                className="absolute right-3 top-3 h-6 w-6 rounded-full border-2 border-lav-400"
              />
            )}
            <span className="grid h-14 w-14 place-items-center rounded-md bg-mint-100 text-primary">
              <Icon name="my_location" size={28} />
            </span>
            <span className="mt-3 flex flex-wrap items-center gap-2">
              <span className="font-display text-h4">Siarkan ke Driver Kampus</span>
              <Badge tone="mint">Rekomendasi</Badge>
            </span>
            <span className="mt-1 block text-body-s text-text-muted">
              Radar 1-klik menyiarkan pesanan ke driver mahasiswa yang sedang online.
            </span>
            <span className="mt-3 grid grid-cols-3 gap-1.5">
              {[
                { id: 'driver', label: 'Driver online', value: '38' },
                { id: 'eta', label: 'ETA rata-rata', value: '4 mnt' },
                { id: 'fee', label: 'Ongkir flat', value: 'Rp 4.000' },
              ].map((metric) => (
                <span key={metric.id} className="rounded-sm bg-lav-100 p-2">
                  <span className="block font-display text-micro uppercase text-text-muted">
                    {metric.label}
                  </span>
                  <span className="block font-display text-h5">{metric.value}</span>
                </span>
              ))}
            </span>
          </button>

          <button
            type="button"
            aria-pressed={method === 'SELF'}
            onClick={() => setMethod('SELF')}
            className={`ce-focus relative rounded-lg p-4 text-left transition duration-fast ease-emphasis ${
              method === 'SELF'
                ? 'border-2 border-primary'
                : 'border-2 border-line-subtle hover:border-lav-400'
            } bg-surface`}
          >
            {method === 'SELF' ? (
              <Icon
                name="check_circle"
                size={28}
                filled
                className="absolute right-3 top-3 text-primary"
              />
            ) : (
              <span
                aria-hidden="true"
                className="absolute right-3 top-3 h-6 w-6 rounded-full border-2 border-lav-400"
              />
            )}
            <span className="grid h-14 w-14 place-items-center rounded-md bg-lav-200 text-text-strong">
              <Icon name="store" size={28} />
            </span>
            <span className="mt-3 block font-display text-h4">Antar Sendiri (Ambil Sendiri)</span>
            <span className="mt-1 block text-body-s text-text-muted">
              Mahasiswa mengambil langsung di etalase stand sesuai PIN pesanan.
            </span>
            <span className="mt-3 block rounded-sm bg-lav-100 p-2 text-caption text-text-muted">
              Tanpa biaya ongkir · tetap gunakan PIN serah terima di etalase
            </span>
          </button>
        </div>
      </Panel>

      {/* Opsi siaran */}
      <Panel>
        <PanelHeader
          icon="sync"
          title="Opsi Siaran Radar"
          description="Pengaturan yang dipakai saat menyiarkan pesanan"
        />

        <div className="space-y-2">
          <div className="flex items-center justify-between gap-3 rounded-md bg-lav-100 p-3">
            <span className="flex items-center gap-2 text-body-s font-semibold text-text-strong">
              <Icon name="my_location" size={20} className="text-primary" />
              Radius siaran
            </span>
            <span className="text-caption font-semibold text-primary">
              Aktif · 1,2 km dari Stand 12
            </span>
          </div>

          <div className="flex items-center justify-between gap-3 rounded-md bg-lav-100 p-3">
            <span className="text-body-s font-semibold text-text-strong">
              Tawarkan tip jam padat
              <span className="block font-normal text-caption text-text-muted">
                Menambah daya tarik saat jam istirahat kuliah.
              </span>
            </span>
            <span className="flex shrink-0 items-center gap-2">
              <Badge tone="mint">Jam Padat</Badge>
              <Toggle checked={tip} onChange={setTip} label="Tawarkan tip jam padat" />
            </span>
          </div>
        </div>
      </Panel>

      {/* Rider standby */}
      <Panel>
        <PanelHeader
          icon="two_wheeler"
          title="Rider Standby Terdekat"
          badge={
            <span className="whitespace-nowrap text-caption font-semibold text-primary">
              Terdekat: 50 m
            </span>
          }
        />
        <div className="grid gap-3 sm:grid-cols-2">
          {MITRA_STANDBY.map((mitra) => (
            <div key={mitra.id} className="flex items-center gap-3 rounded-md bg-lav-100 p-3">
              <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-lav-300 font-display text-caption font-bold text-[#2F3B8F]">
                {mitra.initial}
              </span>
              <span className="min-w-0">
                <span className="block font-display text-h5">{mitra.name}</span>
                <span className="block text-caption text-text-muted">{mitra.meta}</span>
              </span>
            </div>
          ))}
        </div>
      </Panel>

      {/* CTA bar */}
      <div className="sticky bottom-0 space-y-2 rounded-bento border border-line-subtle bg-surface p-3 shadow-bar-top">
        <button
          type="button"
          disabled={method !== 'BROADCAST'}
          onClick={() => setBroadcasted(true)}
          className="ce-btn-primary h-14 w-full text-body-m disabled:cursor-not-allowed disabled:bg-lav-400 disabled:text-text-muted disabled:shadow-none"
        >
          <Icon name="bolt" size={20} filled />
          Siarkan ke Driver Kampus (Radar ⚡)
        </button>
        <button type="button" className="ce-btn-tonal h-12 w-full">
          <Icon name="receipt_long" size={20} />
          Cetak Struk Dapur / Thermal
        </button>

        <p role="status" className="text-center text-caption text-text-muted">
          {broadcasted
            ? `Pesanan #${order.id} tersiar ke 38 driver online pada radius 1,2 km.`
            : method === 'BROADCAST'
              ? 'Tekan tombol siaran untuk mengirim pesanan ke radar driver.'
              : 'Metode antar sendiri aktif: tidak ada siaran ke driver.'}
        </p>
      </div>
    </div>
  );
}
