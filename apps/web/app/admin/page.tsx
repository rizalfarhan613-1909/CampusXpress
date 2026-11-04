'use client';

import { useEffect, useState } from 'react';
import { Badge, Chip } from '@/components/ui/Badge';
import { Icon } from '@/components/ui/Icon';
import { Toggle } from '@/components/ui/Toggle';
import { Callout, Panel, PanelHeader } from '@/components/ui/Panel';
import {
  BROADCAST_DRAFT,
  BROADCAST_TARGET,
  OPS_METRICS,
  TARIFF_ZONES,
  VERIFICATION_QUEUE,
  type TariffZone,
  type VerificationApplicant,
} from '@/lib/demo-admin';
import { rupiah } from '@/lib/format';

const WARNA_TITIK: Record<string, string> = {
  primary: 'bg-primary',
  info: 'bg-info',
  glow: 'bg-primary-glow',
};

/** Admin Master Control Panel — Design.md §C.15 (gambar 18 & 19). */
export default function AdminControlPanelPage() {
  const [operasional, setOperasional] = useState(true);
  const [konfirmasiKill, setKonfirmasiKill] = useState(false);
  const [antrean, setAntrean] = useState<VerificationApplicant[]>(VERIFICATION_QUEUE);
  const [zones, setZones] = useState<TariffZone[]>(TARIFF_ZONES);
  const [zoneEdit, setZoneEdit] = useState<string | null>(null);
  const [pesanBroadcast, setPesanBroadcast] = useState(BROADCAST_DRAFT);
  const [konfirmasiBroadcast, setKonfirmasiBroadcast] = useState(false);
  const [jam, setJam] = useState('--.--.--');
  const [latensi, setLatensi] = useState(0);
  const [catatan, setCatatan] = useState<string | null>(null);

  useEffect(() => {
    const tick = () => {
      setJam(new Date().toLocaleTimeString('id-ID', { hour12: false }));
      setLatensi(28 + Math.floor(Math.random() * 40));
    };
    tick();
    const timer = window.setInterval(tick, 2000);
    return () => window.clearInterval(timer);
  }, []);

  const putuskanPengajuan = (id: string) =>
    setAntrean((prev) => prev.filter((item) => item.id !== id));

  const ubahTarif = (id: string, patch: Partial<TariffZone>) =>
    setZones((prev) => prev.map((zone) => (zone.id === id ? { ...zone, ...patch } : zone)));

  return (
    <div className="mx-auto max-w-5xl space-y-4">
      {/* Pill identitas + indikator latensi */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <span className="inline-flex h-7 items-center rounded-full bg-lav-300 px-3 font-display text-micro uppercase text-text-strong">
          ADMIN: BIRO LOGISTIK BEM
        </span>
        <span className="text-caption text-text-muted">
          <span className="font-mono">{jam}</span> · latensi{' '}
          <span className="font-mono">{latensi} ms</span>
        </span>
      </div>

      {catatan ? (
        <p role="status" className="rounded-md bg-mint-100 p-3 text-body-s text-mint-on">
          {catatan}
        </p>
      ) : null}

      {/* Status operasional kampus (kill switch) */}
      <Panel className="flex items-start gap-3">
        <span className="grid h-12 w-12 shrink-0 place-items-center rounded-md bg-mint-300 text-primary">
          <Icon name="power" size={24} />
        </span>
        <div className="min-w-0 flex-1">
          <h1 className="font-display text-h4">Status Operasional Kampus</h1>
          <p className="mt-0.5 text-body-s font-semibold text-primary">
            {operasional
              ? 'Semua layanan berjalan normal'
              : 'Kill switch aktif — seluruh pesanan baru ditahan'}
          </p>
          <p className="mt-1 text-caption text-text-muted">
            Mengubah sakelar ini selalu meminta konfirmasi dialog sebelum diterapkan.
          </p>
        </div>
        <Toggle
          checked={operasional}
          onChange={() => setKonfirmasiKill(true)}
          label="Status operasional kampus"
        />
      </Panel>

      {/* Grid metrik 2 × 2 */}
      <div className="grid gap-3 sm:grid-cols-2">
        {OPS_METRICS.map((metric) => {
          const gelap = metric.tone === 'primary';
          return (
            <section
              key={metric.id}
              className={`rounded-lg p-4 shadow-card ${
                gelap ? 'bg-primary' : 'border border-line-subtle bg-surface'
              }`}
            >
              <div className="flex items-start justify-between gap-3">
                <p
                  className={`font-display text-micro uppercase ${
                    gelap ? 'text-white/70' : 'text-text-muted'
                  }`}
                >
                  {metric.label}
                </p>
                {metric.badge ? (
                  <Badge tone={gelap || metric.id === 'driver' ? 'mint' : 'lav'}>
                    {metric.badge}
                  </Badge>
                ) : null}
              </div>
              <p
                className={`mt-2 font-display text-h1 ${gelap ? 'text-white' : 'text-text-strong'}`}
              >
                {metric.value}
              </p>
              <p className={`mt-1 text-caption ${gelap ? 'text-white/70' : 'text-text-muted'}`}>
                {metric.caption}
              </p>
            </section>
          );
        })}
      </div>
      {/* Antrean verifikasi */}
      <Panel id="verifikasi" className="scroll-mt-32">
        <PanelHeader
          icon="verified_user"
          title="Antrean Verifikasi"
          description="KTM/SIM driver dan pendaftaran merchant baru"
          badge={<Badge tone="danger">{antrean.length} Menunggu</Badge>}
          action={
            <button
              type="button"
              className="ce-focus shrink-0 rounded font-display text-caption font-semibold text-primary"
            >
              Lihat Arsip
            </button>
          }
        />

        <div className="space-y-3">
          {antrean.map((item) => {
            const inisial = item.name
              .split(' ')
              .slice(0, 2)
              .map((kata) => kata.charAt(0))
              .join('')
              .toUpperCase();

            return (
              <article key={item.id} className="rounded-lg border border-line-subtle p-3">
                <header className="flex flex-wrap items-start gap-3">
                  <span className="grid h-14 w-14 shrink-0 place-items-center rounded-md bg-lav-200 font-display text-h4 text-text-strong">
                    {inisial}
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="font-display text-h4">{item.name}</p>
                    <p className="mt-0.5 flex flex-wrap items-center gap-2">
                      <Chip tone="lav">{item.cohort}</Chip>
                      <span className="text-caption text-text-muted">{item.identity}</span>
                    </p>
                    <p className="mt-1 text-caption text-primary">Menunggu verifikasi admin</p>
                  </div>
                  <Badge tone="info">{item.role}</Badge>
                </header>

                <div className="mt-3 grid gap-2 sm:grid-cols-2">
                  {item.documents.map((doc) => (
                    <div key={doc.id} className="rounded-md bg-lav-100 p-2.5">
                      <p className="font-display text-micro uppercase text-text-muted">
                        {doc.label}
                      </p>
                      <p className="font-mono text-caption text-text-strong">{doc.value}</p>
                    </div>
                  ))}
                </div>

                <div className="mt-3 grid gap-2 sm:grid-cols-[1fr_1.5fr]">
                  <button
                    type="button"
                    onClick={() => {
                      putuskanPengajuan(item.id);
                      setCatatan(
                        `Pengajuan ${item.id} (${item.name}) ditolak dan dikembalikan untuk perbaikan berkas.`,
                      );
                    }}
                    className="ce-focus inline-flex h-12 items-center justify-center gap-2 rounded-md bg-danger-container font-display text-body-m font-bold text-danger transition duration-fast ease-emphasis active:scale-[.98]"
                  >
                    <Icon name="close" size={20} />
                    Tolak
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      putuskanPengajuan(item.id);
                      setCatatan(
                        `Pengajuan ${item.id} (${item.name}) disetujui dan akun diaktifkan.`,
                      );
                    }}
                    className="ce-btn-primary h-12"
                  >
                    <Icon name="verified_user" size={20} />
                    Setujui &amp; Aktifkan
                  </button>
                </div>
              </article>
            );
          })}

          {antrean.length === 0 ? (
            <p className="rounded-md bg-lav-100 p-3 text-body-s text-text-muted">
              Antrean bersih. Semua pengajuan hari ini sudah ditinjau.
            </p>
          ) : null}
        </div>
      </Panel>
      {/* Matriks tarif ongkir */}
      <Panel id="tarif" className="scroll-mt-32">
        <PanelHeader
          icon="tune"
          title="Matriks Tarif Ongkir"
          description="Tarif mahasiswa dan subsidi kas BEM per zona"
          action={
            <button
              type="button"
              aria-label="Filter zona"
              className="ce-focus grid h-10 w-10 shrink-0 place-items-center rounded-md bg-lav-200 text-text-strong"
            >
              <Icon name="tune" size={20} />
            </button>
          }
        />

        <div className="space-y-2">
          {zones.map((zone) => {
            const sedangEdit = zoneEdit === zone.id;
            return (
              <article key={zone.id} className="rounded-lg border border-line-subtle p-3">
                <header className="flex flex-wrap items-center justify-between gap-2">
                  <p className="flex items-center gap-2 font-display text-h4">
                    <span
                      aria-hidden="true"
                      className={`h-2.5 w-2.5 rounded-full ${WARNA_TITIK[zone.dot]}`}
                    />
                    {zone.name}
                  </p>
                  <button
                    type="button"
                    onClick={() => setZoneEdit(sedangEdit ? null : zone.id)}
                    className="ce-focus rounded font-display text-caption font-semibold text-primary"
                  >
                    {sedangEdit ? 'Selesai' : 'Ubah'}
                  </button>
                </header>
                <p className="mt-0.5 text-caption text-text-muted">{zone.description}</p>

                <div className="mt-2 grid gap-2 sm:grid-cols-2">
                  <div className="rounded-md bg-lav-100 p-2.5">
                    <p className="font-display text-micro uppercase text-text-muted">
                      Tarif Mahasiswa
                    </p>
                    {sedangEdit ? (
                      <input
                        aria-label={`Tarif mahasiswa ${zone.name}`}
                        type="number"
                        min={0}
                        step={500}
                        value={zone.studentFee}
                        onChange={(event) =>
                          ubahTarif(zone.id, { studentFee: Number(event.target.value) || 0 })
                        }
                        className="mt-1 h-9 w-full rounded-sm bg-surface px-2 font-display text-body-m font-bold text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                      />
                    ) : (
                      <p className="font-display text-h5 text-text-strong">
                        {rupiah(zone.studentFee)}
                      </p>
                    )}
                  </div>

                  <div className="rounded-md bg-lav-100 p-2.5">
                    <p className="font-display text-micro uppercase text-text-muted">
                      Subsidi Kas BEM
                    </p>
                    {sedangEdit ? (
                      <input
                        aria-label={`Subsidi kas BEM ${zone.name}`}
                        type="number"
                        min={0}
                        step={100}
                        value={zone.bemSubsidy}
                        onChange={(event) =>
                          ubahTarif(zone.id, { bemSubsidy: Number(event.target.value) || 0 })
                        }
                        className="mt-1 h-9 w-full rounded-sm bg-surface px-2 font-display text-body-m font-bold text-primary focus:outline-none focus:ring-2 focus:ring-primary"
                      />
                    ) : (
                      <p className="font-display text-h5 text-text-strong">
                        {rupiah(zone.bemSubsidy)}
                      </p>
                    )}
                  </div>
                </div>
              </article>
            );
          })}
        </div>

        <div className="mt-3">
          <Callout icon="trending_up">
            Iuran pemeliharaan 0,5% dihitung dari total pesanan; 5% bagian dialokasikan ke
            kas BEM dan subsidi UKT mahasiswa.
          </Callout>
        </div>
      </Panel>
      {/* Broadcast darurat */}
      <Panel id="broadcast" className="scroll-mt-32">
        <div className="flex items-start gap-3">
          <span className="grid h-12 w-12 shrink-0 place-items-center rounded-md bg-danger-container text-danger">
            <Icon name="emergency" size={24} />
          </span>
          <div className="min-w-0 flex-1">
            <h2 className="font-display text-h4">Broadcast Darurat BEM</h2>
            <p className="mt-0.5 text-body-s text-text-muted">
              Pengumuman dikirim ke seluruh mahasiswa aktif dan selalu meminta konfirmasi
              dialog sebelum siaran.
            </p>
          </div>
        </div>

        <label className="ce-label mt-3" htmlFor="pesan-broadcast">
          Isi pesan siaran
        </label>
        <textarea
          id="pesan-broadcast"
          rows={3}
          maxLength={280}
          value={pesanBroadcast}
          onChange={(event) => setPesanBroadcast(event.target.value)}
          className="ce-focus w-full rounded-md border-2 border-transparent bg-lav-100 p-3 font-sans text-body-m text-text-strong focus:border-primary"
        />
        <p className="mt-1 text-right text-caption text-text-muted">
          {pesanBroadcast.length} / 280 karakter
        </p>

        <div className="mt-2 flex flex-wrap items-center justify-between gap-3">
          <span className="flex items-center gap-1.5 text-caption text-text-muted">
            <Icon name="group" size={16} />
            Target: {BROADCAST_TARGET}
          </span>
          <button
            type="button"
            disabled={pesanBroadcast.trim().length < 10}
            onClick={() => setKonfirmasiBroadcast(true)}
            className="ce-btn-primary h-14 px-6 disabled:cursor-not-allowed disabled:bg-lav-400 disabled:text-text-muted disabled:shadow-none"
          >
            <Icon name="emergency" size={20} />
            Siarkan Sekarang
          </button>
        </div>
      </Panel>

      {konfirmasiKill || konfirmasiBroadcast ? (
        <div
          role="dialog"
          aria-modal="true"
          aria-label="Konfirmasi tindakan admin"
          className="fixed inset-0 z-50 grid place-items-center bg-ink-800/60 p-4"
        >
          <div className="w-full max-w-sm rounded-lg bg-surface p-4 shadow-float">
            <h2 className="font-display text-h4">
              {konfirmasiKill ? 'Konfirmasi kill switch' : 'Konfirmasi siaran darurat'}
            </h2>
            <p className="mt-2 text-body-s text-text-body">
              {konfirmasiKill
                ? `Status operasional kampus akan diubah menjadi ${
                    operasional ? 'TUTUP' : 'BUKA'
                  }. Pesanan baru ${
                    operasional ? 'tidak dapat dibuat' : 'mulai diterima'
                  } selama status berlaku.`
                : `Pesan akan dikirim ke ${BROADCAST_TARGET}. Pastikan isi pesan sudah final.`}
            </p>
            <div className="mt-4 flex gap-2">
              <button
                type="button"
                onClick={() => {
                  setKonfirmasiKill(false);
                  setKonfirmasiBroadcast(false);
                }}
                className="ce-btn-tonal flex-1"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={() => {
                  if (konfirmasiKill) {
                    const berikutnya = !operasional;
                    setOperasional(berikutnya);
                    setCatatan(
                      berikutnya
                        ? 'Status operasional kampus dibuka kembali.'
                        : 'Kill switch aktif: pesanan baru ditahan di seluruh kampus.',
                    );
                    setKonfirmasiKill(false);
                  } else {
                    setCatatan(`Siaran darurat terkirim ke ${BROADCAST_TARGET}.`);
                    setKonfirmasiBroadcast(false);
                  }
                }}
                className="ce-btn-primary flex-1"
              >
                Ya, lanjutkan
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
