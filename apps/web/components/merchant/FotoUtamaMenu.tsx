'use client';

import { useEffect, useRef, useState } from 'react';
import { Badge } from '@/components/ui/Badge';
import { Icon } from '@/components/ui/Icon';
import { Panel, PanelHeader } from '@/components/ui/Panel';
import { MENU_RULES } from '@/lib/demo-menu';

export interface FotoMenu {
  name: string;
  kb: number;
}

/**
 * Kartu Foto Utama Menu — Design.md §C.17 blok 3.
 *
 * Preset unggah: kompresi WebP ≤ 80 KB di klien (label batas file sumber 2 MB).
 * Di web, ukuran berkas hanya diperiksa dan dilaporkan; pemampatan sebenarnya
 * dilakukan oleh modul gambar aplikasi (tech.md §3.6).
 */
export function FotoUtamaMenu({
  foto,
  onPilih,
  onHapus,
}: {
  foto: FotoMenu | null;
  onPilih: (foto: FotoMenu) => void;
  onHapus: () => void;
}) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);

  useEffect(
    () => () => {
      if (previewUrl) URL.revokeObjectURL(previewUrl);
    },
    [previewUrl],
  );

  const terlaluBesar = foto ? foto.kb > MENU_RULES.photoMaxKb : false;

  return (
    <Panel>
      <PanelHeader
        icon="camera_alt"
        title="Foto Utama Menu"
        description="Pratinjau 1:1 dipakai pada kartu katalog mahasiswa"
        badge={<Badge tone="mint">Wajib</Badge>}
      />

      <div className="mx-auto h-40 w-40 overflow-hidden rounded-md border border-line-subtle bg-lav-200">
        {previewUrl ? (
          // eslint-disable-next-line @next/next/no-img-element -- pratinjau berkas lokal (blob URL), bukan aset situs
          <img
            src={previewUrl}
            alt="Pratinjau foto utama menu"
            className="h-full w-full object-cover"
          />
        ) : (
          <div className="grid h-full w-full place-items-center text-center">
            <span className="px-4 font-display text-caption text-text-muted">
              1:1
              <span className="mt-1 block font-sans text-micro uppercase text-text-muted">
                Pratinjau aplikasi
              </span>
            </span>
          </div>
        )}
      </div>

      <p className="mt-2 text-center text-caption text-text-muted">
        Pratinjau aplikasi · rasio 1:1 siap tampil
      </p>

      <div className="mt-3 flex flex-wrap items-center justify-center gap-2">
        <label
          htmlFor="foto-menu"
          className="ce-focus inline-flex h-10 cursor-pointer items-center gap-2 rounded-md bg-primary px-4 font-display text-body-m font-bold text-on-primary shadow-cta"
        >
          <Icon name="camera_alt" size={20} />
          {foto ? 'Ganti Foto Menu' : 'Pilih Foto Menu'}
        </label>
        <input
          id="foto-menu"
          ref={inputRef}
          type="file"
          accept="image/webp,image/jpeg,image/png"
          className="sr-only"
          onChange={(event) => {
            const file = event.target.files?.[0];
            if (!file) return;
            if (previewUrl) URL.revokeObjectURL(previewUrl);
            setPreviewUrl(URL.createObjectURL(file));
            onPilih({ name: file.name, kb: Math.round(file.size / 1024) });
          }}
        />
        {foto ? (
          <button
            type="button"
            onClick={() => {
              if (previewUrl) URL.revokeObjectURL(previewUrl);
              setPreviewUrl(null);
              if (inputRef.current) inputRef.current.value = '';
              onHapus();
            }}
            className="ce-focus inline-flex h-10 items-center gap-2 rounded-md bg-lav-300 px-3 font-display text-body-s font-semibold text-text-strong"
          >
            <Icon name="close" size={16} />
            Hapus
          </button>
        ) : null}
      </div>

      <div className="mt-3 flex flex-wrap items-center justify-between gap-2 text-caption">
        <span className="flex items-center gap-1.5 text-primary">
          <Icon name="bolt" size={14} filled />
          Otomatis kompresi kampus WebP ≤ {MENU_RULES.photoMaxKb} KB
        </span>
        <span className="text-text-muted">Rekomendasi rasio 1:1 · maksimal file 2 MB</span>
      </div>

      {foto ? (
        <p
          className={`mt-2 rounded-md p-2 text-caption ${
            terlaluBesar ? 'bg-danger-container text-danger' : 'bg-mint-100 text-mint-on'
          }`}
        >
          {foto.name} · {foto.kb} KB{' '}
          {terlaluBesar
            ? '— di atas preset 80 KB, mockup akan mengompres ulang saat diunggah.'
            : '— siap diunggah ke Cloudflare R2.'}
        </p>
      ) : (
        <p className="mt-2 rounded-md bg-lav-100 p-2 text-caption text-text-muted">
          Foto wajib diunggah sebelum menu dapat diterbitkan.
        </p>
      )}
    </Panel>
  );
}
