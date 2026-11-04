'use client';

import { Badge } from '@/components/ui/Badge';
import { Icon } from '@/components/ui/Icon';
import { Panel, PanelHeader } from '@/components/ui/Panel';
import { MENU_RULES } from '@/lib/demo-menu';

export interface FormOption {
  id: string;
  name: string;
  extra: number;
  isDefault?: boolean;
}

export interface FormGroup {
  id: string;
  title: string;
  rule: 'WAJIB_1' | 'OPSIONAL';
  options: FormOption[];
}

interface Props {
  groups: FormGroup[];
  onUbahJudulGrup: (groupId: string, title: string) => void;
  onTambahGrup: () => void;
  onHapusGrup: (groupId: string) => void;
  onTambahOpsi: (groupId: string) => void;
  onHapusOpsi: (groupId: string, optionId: string) => void;
  onUbahOpsi: (groupId: string, optionId: string, patch: Partial<FormOption>) => void;
  onJadikanDefault: (groupId: string, optionId: string) => void;
}

/**
 * Editor Variasi & Kustomisasi Rasa — Design.md §C.17 blok 5.
 * Aturan: maksimal 6 grup dan 12 opsi per grup; grup "Wajib Pilih 1" harus
 * memiliki tepat satu opsi bawaan.
 */
export function VariasiEditor({
  groups,
  onUbahJudulGrup,
  onTambahGrup,
  onHapusGrup,
  onTambahOpsi,
  onHapusOpsi,
  onUbahOpsi,
  onJadikanDefault,
}: Props) {
  return (
    <Panel>
      <PanelHeader
        icon="tune"
        title="Variasi & Kustomisasi Rasa"
        description="Atur pilihan kepedasan, topping, dan paket tambahan"
        badge={<Badge tone="lav">{groups.length} Grup</Badge>}
      />

      <div className="space-y-3">
        {groups.map((group) => {
          const wajib = group.rule === 'WAJIB_1';
          return (
            <section
              key={group.id}
              className={`rounded-lg p-3 ${wajib ? 'bg-lav-100' : 'border border-line-subtle'}`}
            >
              <header className="flex flex-wrap items-start justify-between gap-2">
                <div className="flex min-w-0 items-start gap-2">
                  <Icon
                    name={wajib ? 'trending_up' : 'add'}
                    size={20}
                    className="mt-0.5 shrink-0 text-primary"
                  />
                  <div className="min-w-0">
                    <input
                      aria-label="Judul grup variasi"
                      value={group.title}
                      onChange={(event) => onUbahJudulGrup(group.id, event.target.value)}
                      className="w-full rounded-sm bg-transparent font-display text-h5 text-text-strong focus:bg-surface focus:outline-none focus:ring-1 focus:ring-primary"
                    />
                    <p className="text-caption text-text-muted">
                      {wajib
                        ? 'Mahasiswa memilih tepat satu opsi sebelum menambah ke keranjang.'
                        : 'Mahasiswa boleh memilih beberapa opsi sekaligus.'}
                    </p>
                  </div>
                </div>
                <span className="flex shrink-0 items-center gap-2">
                  <Badge tone={wajib ? 'danger' : 'lav'}>
                    {wajib ? 'Wajib Pilih 1' : 'Bisa Pilih Banyak'}
                  </Badge>
                  <button
                    type="button"
                    aria-label={`Hapus grup ${group.title}`}
                    onClick={() => onHapusGrup(group.id)}
                    className="ce-focus grid h-7 w-7 place-items-center rounded-full text-text-muted hover:bg-lav-200"
                  >
                    <Icon name="close" size={16} />
                  </button>
                </span>
              </header>
              <div className="mt-3 grid gap-2 sm:grid-cols-2">
                {group.options.map((option) => (
                  <div
                    key={option.id}
                    className={`rounded-md border p-2 ${
                      option.isDefault
                        ? 'border-primary-bright bg-mint-100'
                        : 'border-line-subtle bg-surface'
                    }`}
                  >
                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        role="radio"
                        aria-checked={Boolean(option.isDefault)}
                        aria-label={`Jadikan ${option.name} opsi bawaan`}
                        onClick={() => onJadikanDefault(group.id, option.id)}
                        className={`ce-focus grid h-5 w-5 shrink-0 place-items-center rounded-full border-2 ${
                          option.isDefault ? 'border-primary' : 'border-lav-400'
                        }`}
                      >
                        {option.isDefault ? (
                          <span className="h-2.5 w-2.5 rounded-full bg-primary" />
                        ) : null}
                      </button>
                      <input
                        aria-label="Nama opsi"
                        value={option.name}
                        onChange={(event) =>
                          onUbahOpsi(group.id, option.id, { name: event.target.value })
                        }
                        className="w-full rounded-sm bg-transparent text-caption font-semibold text-text-strong focus:bg-surface focus:outline-none"
                      />
                      <button
                        type="button"
                        aria-label={`Hapus opsi ${option.name}`}
                        onClick={() => onHapusOpsi(group.id, option.id)}
                        className="ce-focus grid h-6 w-6 shrink-0 place-items-center rounded-full text-text-muted hover:bg-lav-200"
                      >
                        <Icon name="close" size={14} />
                      </button>
                    </div>

                    <div className="mt-1.5 flex items-center gap-2 pl-7">
                      <span className="text-caption text-text-muted">+Rp</span>
                      <input
                        aria-label={`Tambahan harga ${option.name}`}
                        type="number"
                        min={0}
                        step={MENU_RULES.priceStep}
                        value={option.extra}
                        onChange={(event) =>
                          onUbahOpsi(group.id, option.id, {
                            extra: Number(event.target.value) || 0,
                          })
                        }
                        className="h-8 w-24 rounded-sm bg-lav-200 px-2 text-caption font-semibold text-primary focus:outline-none focus:ring-1 focus:ring-primary"
                      />
                      {option.isDefault ? (
                        <span className="text-caption font-semibold text-primary">Bawaan</span>
                      ) : null}
                    </div>
                  </div>
                ))}
              </div>

              <button
                type="button"
                disabled={group.options.length >= MENU_RULES.maxOptionsPerGroup}
                onClick={() => onTambahOpsi(group.id)}
                className="ce-focus mt-3 flex h-11 w-full items-center justify-center gap-2 rounded-md bg-lav-300 font-display text-body-s font-semibold text-primary disabled:cursor-not-allowed disabled:opacity-50"
              >
                <Icon name="add" size={16} />
                Tambah Opsi
              </button>
            </section>
          );
        })}
      </div>
      <button
        type="button"
        disabled={groups.length >= MENU_RULES.maxGroups}
        onClick={onTambahGrup}
        className="ce-focus mt-3 flex h-11 w-full items-center justify-center gap-2 rounded-md border border-line-subtle bg-surface font-display text-body-s font-semibold text-primary disabled:cursor-not-allowed disabled:opacity-50"
      >
        <Icon name="add" size={16} />
        Tambah Grup Variasi Baru
      </button>

      <p className="mt-2 text-caption text-text-muted">
        Maksimal {MENU_RULES.maxGroups} grup dan {MENU_RULES.maxOptionsPerGroup} opsi per grup.
      </p>
    </Panel>
  );
}
