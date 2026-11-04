'use client';

import { useState } from 'react';
import { Badge, Chip } from '@/components/ui/Badge';
import { Icon } from '@/components/ui/Icon';
import { Toggle } from '@/components/ui/Toggle';
import { Callout, Panel, PanelHeader, TonalCard } from '@/components/ui/Panel';
import { MERCHANT_STORE } from '@/lib/demo';
import { STORE_SCHEDULE } from '@/lib/demo-menu';
import { waktuWib } from '@/lib/format';

const WARNA_TITIK: Record<string, string> = {
  primary: 'bg-primary',
  info: 'bg-info',
  glow: 'bg-primary-glow',
};

/** Pengaturan Toko merchant — Design.md §C.21 (gambar 26). */
export default function MerchantSettingsPage() {
  const [namaStan, setNamaStan] = useState(MERCHANT_STORE.name);
  const [deskripsi, setDeskripsi] = useState(
    'Menyediakan aneka olahan ayam geprek fresh ulek dadakan dan soto kuah bening sejak 2018.',
  );
  const [lokasiJemput, setLokasiJemput] = useState(MERCHANT_STORE.pickupPoint);
  const [ikutKampus, setIkutKampus] = useState(true);
  const [autoBuka, setAutoBuka] = useState(true);
  const [jadwalAktif, setJadwalAktif] = useState<Record<string, boolean>>({
    'SEN-KAM': true,
    JUM: true,
    SAB: false,
  });
  const [rekeningBaru, setRekeningBaru] = useState(false);
  const [preferensi, setPreferensi] = useState({ jastip: true, pickup: true });
  const [ditutupAdmin, setDitutupAdmin] = useState(false);
  const [status, setStatus] = useState<'bersih' | 'tersimpan' | 'gagal'>('bersih');

  const layananValid = preferensi.jastip || preferensi.pickup;
  const profilValid = namaStan.trim().length >= 3 && deskripsi.length <= 120;

  const jadwalTerkunci = ditutupAdmin || !ikutKampus;

  return (
    <div className="mx-auto max-w-3xl space-y-4">
      {/* Banner toko + strip identitas */}
      {ditutupAdmin ? (
        <p
          role="alert"
          className="flex items-start gap-2 rounded-md bg-danger-container p-3 text-body-s text-danger"
        >
          <Icon name="error" size={20} className="mt-0.5 shrink-0" />
          Toko ditutup sementara oleh admin BEM. Seluruh jadwal dan toggle layanan
          dinonaktifkan sampai peninjauan selesai.
        </p>
      ) : null}

      <section className="rounded-lg border border-line-subtle bg-surface shadow-card">
        <div className="relative h-[150px] overflow-hidden rounded-t-lg bg-wallet">
          <div className="absolute inset-0 bg-photo-fade" />
          <button
            type="button"
            disabled={ditutupAdmin}
            className="ce-focus absolute right-3 top-3 inline-flex h-8 items-center gap-1.5 rounded-full bg-surface/90 px-3 font-display text-caption font-bold text-text-strong disabled:opacity-60"
          >
            <Icon name="camera_alt" size={16} />
            Ubah Banner Stan (16:9)
          </button>
          <span className="absolute bottom-3 left-3 inline-flex h-7 items-center rounded-full bg-surface/90 px-3 text-caption text-text-strong">
            {MERCHANT_STORE.location}
          </span>
        </div>

        <div className="relative px-4 pb-3">
          <span className="absolute -top-8 left-4 grid h-16 w-16 place-items-center rounded-lg border-[3px] border-surface bg-mint-100 font-display text-h2 text-primary">
            BS
            <span className="absolute -bottom-1 -right-1 grid h-6 w-6 place-items-center rounded-full bg-primary text-white">
              <Icon name="camera_alt" size={14} />
            </span>
          </span>
          <p className="pt-11 text-caption text-text-muted">
            Banner 16:7 dipakai pada kartu katalog dan halaman detail kantin.
          </p>
        </div>

        <div className="flex flex-wrap items-center justify-between gap-3 rounded-b-lg bg-lav-300 px-4 py-3">
          <div className="min-w-0">
            <p className="font-display text-h3">Kantin Bu Siti</p>
            <p className="text-body-s text-text-muted">{MERCHANT_STORE.specialist}</p>
          </div>
          <Badge tone="mint">{MERCHANT_STORE.verified}</Badge>
        </div>
      </section>

      {/* Informasi & profil operasional */}
      <Panel>
        <PanelHeader
          icon="store"
          title="Informasi &amp; Profil Operasional"
          description="Data ini tampil pada katalog mahasiswa"
          badge={<span className="shrink-0 text-caption text-text-muted">Publik</span>}
        />

        <label className="ce-label" htmlFor="nama-stan">
          Nama Stan Resmi *
        </label>
        <div className="relative">
          <Icon
            name="store"
            size={20}
            className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-text-muted"
          />
          <input
            id="nama-stan"
            value={namaStan}
            onChange={(event) => {
              setNamaStan(event.target.value);
              setStatus('bersih');
            }}
            className="ce-field pl-11"
          />
        </div>

        <label className="ce-label mt-4" htmlFor="deskripsi-stan">
          Deskripsi Singkat Stan
        </label>
        <textarea
          id="deskripsi-stan"
          rows={3}
          maxLength={120}
          value={deskripsi}
          onChange={(event) => {
            setDeskripsi(event.target.value);
            setStatus('bersih');
          }}
          className="ce-focus w-full rounded-md border-2 border-transparent bg-lav-200 p-3 font-sans text-body-m text-text-strong focus:border-primary"
        />
        <p className="mt-1 text-right text-caption text-text-muted">
          {deskripsi.length} / 120 karakter
        </p>

        <div className="mt-2 flex flex-wrap items-center justify-between gap-2">
          <label className="ce-label mb-0" htmlFor="lokasi-jemput">
            Lokasi Penjemputan Pesanan (Driver Jastip) *
          </label>
          <Chip tone="mint">Titik Akurat</Chip>
        </div>
        <div className="relative">
          <Icon
            name="location_on"
            size={20}
            className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-text-muted"
          />
          <input
            id="lokasi-jemput"
            value={lokasiJemput}
            onChange={(event) => {
              setLokasiJemput(event.target.value);
              setStatus('bersih');
            }}
            className="ce-field pl-11"
          />
        </div>
        <p className="mt-1 text-caption text-text-muted">
          Driver kampus membaca instruksi ini saat tiba di area pujasera.
        </p>
      </Panel>
      {/* Jadwal buka otomatis */}
      <Panel>
        <PanelHeader
          icon="schedule"
          title="Jadwal Buka Otomatis"
          description="Sinkron dengan kalender akademik kampus"
          badge={<Badge tone="mint">Akademik V2</Badge>}
        />

        <TonalCard className="flex items-center gap-3 bg-lav-300">
          <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-primary text-white">
            <Icon name="school" size={22} />
          </span>
          <span className="min-w-0 flex-1">
            <span className="block font-display text-h5">Ikuti Jam Operasional Kampus</span>
            <span className="block text-caption text-text-muted">
              Senin – Sabtu (menyesuaikan kalender BEM)
            </span>
          </span>
          <Toggle
            checked={ikutKampus}
            onChange={(next) => {
              setIkutKampus(next);
              setStatus('bersih');
            }}
            label="Ikuti jam operasional kampus"
            disabled={ditutupAdmin}
          />
        </TonalCard>

        <ul className="mt-3 space-y-2">
          {STORE_SCHEDULE.map((row) => {
            const aktif = jadwalAktif[row.id] ?? false;
            return (
              <li
                key={row.id}
                className={`flex flex-wrap items-center justify-between gap-3 rounded-md bg-lav-100 p-3 transition-opacity duration-fast ${
                  jadwalTerkunci ? 'opacity-50' : ''
                }`}
              >
                <span className="flex min-w-0 items-start gap-2.5">
                  <span
                    aria-hidden="true"
                    className={`mt-1.5 h-2 w-2 shrink-0 rounded-full ${WARNA_TITIK[row.dot]}`}
                  />
                  <span className="min-w-0">
                    <span className="block font-display text-h5">{row.day}</span>
                    <span className="block text-caption text-text-muted">{row.note}</span>
                  </span>
                </span>

                <span className="flex items-center gap-3">
                  <span className="flex flex-col items-end gap-1">
                    <span className="rounded-sm bg-surface px-2 py-1 font-mono text-caption font-bold text-primary">
                      {waktuWib(row.ranges[0])} – {waktuWib(row.ranges[1])}
                    </span>
                    <span className="text-caption text-primary">
                      {aktif ? 'Aktif' : 'Nonaktif'}
                    </span>
                  </span>
                  <Toggle
                    checked={aktif}
                    onChange={(next) => {
                      setJadwalAktif((prev) => ({ ...prev, [row.id]: next }));
                      setStatus('bersih');
                    }}
                    label={`Aktifkan jadwal ${row.day}`}
                    disabled={jadwalTerkunci}
                  />
                </span>
              </li>
            );
          })}
        </ul>

        <div className="mt-3 flex items-center justify-between gap-3 rounded-md border border-line-subtle p-3">
          <span className="text-body-s font-semibold text-text-strong">
            Otomatis Buka Saat Kuliah Dimulai
            <span className="block font-normal text-caption text-text-muted">
              Stan aktif sinkron dengan presensi kelas pada kalender akademik.
            </span>
          </span>
          <Toggle
            checked={autoBuka}
            onChange={(next) => {
              setAutoBuka(next);
              setStatus('bersih');
            }}
            label="Otomatis buka saat kuliah dimulai"
            disabled={jadwalTerkunci}
          />
        </div>

        <div className="mt-3">
          <Callout icon="sync">
            Jadwal Jumat dan Sabtu memakai dua rentang waktu terpisah. Skema satu rentang
            per hari belum cukup untuk menampung jeda sholat Jumat.
          </Callout>
        </div>
      </Panel>
      {/* Pencairan harian + QRIS */}
      <Panel>
        <PanelHeader
          icon="receipt_long"
          title="Pencairan Harian"
          description="Dana penjualan dikirim otomatis ke rekening stan"
          badge={
            <span className="shrink-0 whitespace-nowrap text-caption font-semibold text-primary">
              Tiap 18.00 WIB
            </span>
          }
        />

        <Callout icon="sync">
          <span className="block font-display text-h5 text-mint-on">
            Auto-Withdrawal Harian Otomatis
          </span>
          Penjualan cair ke rekening utama setiap jam 18.00 WIB tanpa biaya admin bank.
        </Callout>

        <TonalCard className="mt-3 bg-lav-300">
          <div className="flex items-center gap-3">
            <span className="grid h-8 w-8 shrink-0 place-items-center rounded-sm bg-surface font-display text-micro text-primary">
              BSI
            </span>
            <span className="min-w-0 flex-1">
              <span className="block font-display text-h5">{MERCHANT_STORE.bank.name}</span>
              <span className="block text-caption text-text-muted">
                {MERCHANT_STORE.bank.label}
              </span>
            </span>
            <button
              type="button"
              onClick={() => setRekeningBaru(true)}
              className="ce-focus h-8 shrink-0 rounded-sm bg-surface px-3 font-display text-caption font-semibold text-text-strong"
            >
              Ubah
            </button>
          </div>

          <div className="mt-2 flex flex-wrap items-center justify-between gap-2 rounded-md bg-surface px-3 py-2">
            <span className="font-mono text-body-m text-text-strong">
              {MERCHANT_STORE.bank.masked}
            </span>
            <span className="text-caption text-text-muted">{MERCHANT_STORE.bank.holder}</span>
          </div>

          {rekeningBaru ? (
            <p className="mt-2 inline-flex items-center gap-1.5 rounded-full bg-lav-200 px-2.5 py-1 text-caption text-text-strong">
              <Icon name="schedule" size={14} />
              Menunggu verifikasi 24 jam
            </p>
          ) : null}
        </TonalCard>

        <div className="mt-3 flex flex-wrap items-center justify-between gap-3 rounded-md border border-line-subtle p-3">
          <span className="flex min-w-0 items-center gap-3">
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-md bg-lav-200 text-text-strong">
              <Icon name="qr_code" size={22} />
            </span>
            <span className="min-w-0">
              <span className="flex items-center gap-1.5 font-display text-h5">
                QRIS Dinamis Merchant
                <Icon name="check_circle" size={16} className="text-primary" />
              </span>
              <span className="block font-mono text-caption text-text-muted">
                NMID: {MERCHANT_STORE.qris.nmid}
              </span>
            </span>
          </span>
          <Badge tone="mint">{MERCHANT_STORE.qris.status}</Badge>
        </div>
      </Panel>

      {/* Preferensi layanan */}
      <Panel>
        <PanelHeader
          icon="tune"
          title="Preferensi Layanan"
          description="Minimal satu metode harus aktif"
        />

        <div className="space-y-2">
          {[
            {
              id: 'jastip' as const,
              label: 'Pesanan Driver Kampus (Jastip)',
              caption: 'Rider mahasiswa mengambil di etalase lalu mengantar ke titik tujuan.',
            },
            {
              id: 'pickup' as const,
              label: 'Ambil Sendiri (Pick-up Express)',
              caption: 'Pembeli mengambil mandiri di etalase stan dengan PIN pesanan.',
            },
          ].map((layanan) => (
            <div
              key={layanan.id}
              className="flex items-center gap-3 rounded-md bg-lav-300 p-3"
            >
              <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-primary text-white">
                <Icon name={layanan.id === 'jastip' ? 'two_wheeler' : 'store'} size={22} />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block font-display text-h5">{layanan.label}</span>
                <span className="block text-caption text-text-muted">{layanan.caption}</span>
              </span>
              <input
                type="checkbox"
                aria-label={layanan.label}
                checked={preferensi[layanan.id]}
                disabled={ditutupAdmin}
                onChange={(event) => {
                  setPreferensi((prev) => ({ ...prev, [layanan.id]: event.target.checked }));
                  setStatus('bersih');
                }}
                className="ce-focus h-4 w-4 shrink-0 rounded-xs accent-[#006C4A]"
              />
            </div>
          ))}
        </div>

        {!layananValid ? (
          <p role="alert" className="mt-2 text-caption text-danger">
            Minimal satu metode layanan harus aktif agar stan tetap tampil di katalog.
          </p>
        ) : null}

        <div className="mt-3 flex items-center justify-between gap-3 rounded-md border border-line-subtle p-3">
          <span className="text-body-s font-semibold text-text-strong">
            Simulasi status admin BEM
            <span className="block font-normal text-caption text-text-muted">
              Dipakai untuk menguji state &quot;toko ditutup admin&quot; pada dasbor.
            </span>
          </span>
          <Toggle
            checked={ditutupAdmin}
            onChange={setDitutupAdmin}
            label="Simulasikan toko ditutup admin"
          />
        </div>
      </Panel>
      {/* CTA simpan */}
      <div className="sticky bottom-0 space-y-2 rounded-bento border border-line-subtle bg-surface p-3 shadow-bar-top">
        <button
          type="button"
          disabled={!layananValid || !profilValid}
          onClick={() => setStatus('tersimpan')}
          className="ce-btn-primary h-12 w-full disabled:cursor-not-allowed disabled:bg-lav-400 disabled:text-text-muted disabled:shadow-none"
        >
          <Icon name="save" size={20} />
          Simpan Perubahan Stan
        </button>
        <p
          role="status"
          className={`text-center text-caption ${
            status === 'tersimpan'
              ? 'text-primary'
              : !layananValid || !profilValid
                ? 'text-danger'
                : 'text-text-muted'
          }`}
        >
          {status === 'tersimpan'
            ? 'Perubahan tersimpan dan langsung aktif di katalog mahasiswa.'
            : !layananValid
              ? 'Minimal satu metode layanan harus aktif sebelum menyimpan.'
              : !profilValid
                ? 'Nama stan minimal 3 karakter dan deskripsi maksimal 120 karakter.'
                : 'Perubahan langsung aktif di katalog mahasiswa setelah disimpan.'}
        </p>
      </div>
    </div>
  );
}
