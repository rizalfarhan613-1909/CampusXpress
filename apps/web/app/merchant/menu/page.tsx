'use client';

import { useMemo, useState } from 'react';
import { Badge } from '@/components/ui/Badge';
import { Icon } from '@/components/ui/Icon';
import { Toggle } from '@/components/ui/Toggle';
import { Callout, Panel, PanelHeader, TonalCard } from '@/components/ui/Panel';
import { FotoUtamaMenu, type FotoMenu } from '@/components/merchant/FotoUtamaMenu';
import { VariasiEditor, type FormGroup } from '@/components/merchant/VariasiEditor';
import { MERCHANT_MENUS, MENU_CATEGORIES, MENU_RULES, STORE_SCHEDULE } from '@/lib/demo-menu';
import { MERCHANT_STORE } from '@/lib/demo';
import { rupiah, waktuWib } from '@/lib/format';

type Mode = 'ADD' | 'EDIT';
type Opsi = FormGroup['options'][number];

function buatId(prefix: string): string {
  return `${prefix}-${Math.random().toString(36).slice(2, 8).toUpperCase()}`;
}

/** Salin variasi menu demo ke bentuk yang dapat diedit. */
function grupDariMenu(menuId: string): FormGroup[] {
  const menu = MERCHANT_MENUS.find((item) => item.id === menuId) ?? MERCHANT_MENUS[0];
  return menu.variants.map((group) => ({
    id: group.id,
    title: group.title,
    rule: group.rule,
    options: group.options.map((option) => ({
      id: option.id,
      name: option.name,
      extra: option.extra,
      isDefault: option.isDefault,
    })),
  }));
}

/** Kelola Menu & Tambah/Edit Produk — Design.md §C.17 (gambar 22). */
export default function MerchantMenuPage() {
  const [mode, setMode] = useState<Mode>('EDIT');
  const [menuId, setMenuId] = useState<string>(MERCHANT_MENUS[0].id);
  const [nama, setNama] = useState(MERCHANT_MENUS[0].name);
  const [kategori, setKategori] = useState<string>(MERCHANT_MENUS[0].category);
  const [deskripsi, setDeskripsi] = useState(MERCHANT_MENUS[0].description);
  const [harga, setHarga] = useState<number>(MERCHANT_MENUS[0].price);
  const [kuota, setKuota] = useState<number>(MERCHANT_MENUS[0].dailyQuota);
  const [tersedia, setTersedia] = useState(true);
  const [foto, setFoto] = useState<FotoMenu | null>(null);
  const [groups, setGroups] = useState<FormGroup[]>(() => grupDariMenu(MERCHANT_MENUS[0].id));
  const [pesan, setPesan] = useState<string | null>(null);

  const validasi = useMemo(() => {
    const namaOk =
      nama.trim().length >= MENU_RULES.nameMin && nama.trim().length <= MENU_RULES.nameMax;
    const deskripsiOk = deskripsi.length <= MENU_RULES.descriptionMax;
    const hargaOk =
      harga >= MENU_RULES.priceMin &&
      harga <= MENU_RULES.priceMax &&
      harga % MENU_RULES.priceStep === 0;
    const kuotaOk = kuota >= MENU_RULES.quotaMin && kuota <= MENU_RULES.quotaMax;
    const grupOk = groups.length > 0 && groups.length <= MENU_RULES.maxGroups;
    const opsiOk = groups.every(
      (group) =>
        group.options.length > 0 && group.options.length <= MENU_RULES.maxOptionsPerGroup,
    );
    const bawaanOk = groups.every(
      (group) =>
        group.rule !== 'WAJIB_1' ||
        group.options.filter((option) => option.isDefault).length === 1,
    );
    const fotoOk = foto !== null;
    return { namaOk, deskripsiOk, hargaOk, kuotaOk, grupOk, opsiOk, bawaanOk, fotoOk };
  }, [deskripsi.length, foto, groups, harga, kuota, nama]);

  const siapTerbit = Object.values(validasi).every(Boolean);

  const muatMenu = (id: string) => {
    const menu = MERCHANT_MENUS.find((item) => item.id === id);
    if (!menu) return;
    setMode('EDIT');
    setMenuId(id);
    setNama(menu.name);
    setKategori(menu.category);
    setDeskripsi(menu.description);
    setHarga(menu.price);
    setKuota(menu.dailyQuota);
    setTersedia(menu.availability === 'READY');
    setGroups(grupDariMenu(id));
    setFoto(null);
    setPesan(null);
  };

  const mulaiTambah = () => {
    setMode('ADD');
    setNama('');
    setKategori(MENU_CATEGORIES[0]);
    setDeskripsi('');
    setHarga(15000);
    setKuota(30);
    setTersedia(true);
    setFoto(null);
    setGroups([
      {
        id: buatId('GRP'),
        title: 'Tingkat Kepedasan',
        rule: 'WAJIB_1',
        options: [{ id: buatId('OPT'), name: 'Level 1 (Standar)', extra: 0, isDefault: true }],
      },
    ]);
    setPesan(null);
  };

  const ubahJudulGrup = (groupId: string, title: string) =>
    setGroups((prev) =>
      prev.map((group) => (group.id === groupId ? { ...group, title } : group)),
    );

  const tambahGrup = () =>
    setGroups((prev) =>
      prev.length >= MENU_RULES.maxGroups
        ? prev
        : [
            ...prev,
            {
              id: buatId('GRP'),
              title: `Grup Variasi ${prev.length + 1}`,
              rule: 'OPSIONAL' as const,
              options: [{ id: buatId('OPT'), name: 'Opsi baru', extra: 0 }],
            },
          ],
    );

  const hapusGrup = (groupId: string) =>
    setGroups((prev) => prev.filter((group) => group.id !== groupId));

  const tambahOpsi = (groupId: string) =>
    setGroups((prev) =>
      prev.map((group) =>
        group.id === groupId && group.options.length < MENU_RULES.maxOptionsPerGroup
          ? {
              ...group,
              options: [...group.options, { id: buatId('OPT'), name: 'Opsi baru', extra: 0 }],
            }
          : group,
      ),
    );

  const hapusOpsi = (groupId: string, optionId: string) =>
    setGroups((prev) =>
      prev.map((group) =>
        group.id === groupId
          ? { ...group, options: group.options.filter((option) => option.id !== optionId) }
          : group,
      ),
    );

  const ubahOpsi = (groupId: string, optionId: string, patch: Partial<Opsi>) =>
    setGroups((prev) =>
      prev.map((group) =>
        group.id === groupId
          ? {
              ...group,
              options: group.options.map((option) =>
                option.id === optionId ? { ...option, ...patch } : option,
              ),
            }
          : group,
      ),
    );

  const jadikanDefault = (groupId: string, optionId: string) =>
    setGroups((prev) =>
      prev.map((group) =>
        group.id === groupId
          ? {
              ...group,
              options: group.options.map((option) => ({
                ...option,
                isDefault: option.id === optionId,
              })),
            }
          : group,
      ),
    );

  return (
    <div className="mx-auto max-w-3xl space-y-4">
      {/* Strip merchant + pemilih mode */}
      <Panel className="bg-lav-300">
        <div className="flex flex-wrap items-center gap-3">
          <span className="grid h-10 w-10 shrink-0 place-items-center rounded-md bg-mint-100 text-primary">
            <Icon name="store" size={22} />
          </span>
          <div className="min-w-0 flex-1">
            <p className="flex flex-wrap items-center gap-2 font-display text-h5">
              {MERCHANT_STORE.name}
              <Badge tone="mint">{MERCHANT_STORE.stand}</Badge>
            </p>
            <p className="text-caption text-text-muted">{MERCHANT_STORE.location}</p>
          </div>
          <div className="flex shrink-0 gap-1 rounded-full bg-surface p-1">
            <button
              type="button"
              aria-pressed={mode === 'ADD'}
              onClick={mulaiTambah}
              className={`ce-focus rounded-full px-3 py-1.5 font-display text-caption font-bold transition duration-fast ${
                mode === 'ADD' ? 'bg-primary text-on-primary' : 'text-text-body'
              }`}
            >
              Mode Tambah
            </button>
            <button
              type="button"
              aria-pressed={mode === 'EDIT'}
              onClick={() => muatMenu(menuId)}
              className={`ce-focus rounded-full px-3 py-1.5 font-display text-caption font-bold transition duration-fast ${
                mode === 'EDIT' ? 'bg-primary text-on-primary' : 'text-text-body'
              }`}
            >
              Mode Edit
            </button>
          </div>
        </div>

        {mode === 'EDIT' ? (
          <div className="mt-3">
            <label className="ce-label" htmlFor="pilih-menu">
              Menu yang diedit
            </label>
            <select
              id="pilih-menu"
              value={menuId}
              onChange={(event) => muatMenu(event.target.value)}
              className="ce-focus h-12 w-full rounded-md bg-surface px-3 font-sans text-body-m text-text-strong"
            >
              {MERCHANT_MENUS.map((menu) => (
                <option key={menu.id} value={menu.id}>
                  {menu.name} · {rupiah(menu.price)}
                </option>
              ))}
            </select>
          </div>
        ) : (
          <p className="mt-3 rounded-md bg-surface p-2 text-caption text-text-muted">
            Mode tambah aktif: seluruh formulir dikosongkan dan wajib melewati validasi
            sebelum menu dapat diterbitkan.
          </p>
        )}
      </Panel>

      <FotoUtamaMenu foto={foto} onPilih={setFoto} onHapus={() => setFoto(null)} />
      {/* Informasi & detail */}
      <Panel>
        <PanelHeader
          icon="receipt_long"
          title="Informasi &amp; Detail Menu"
          description={`Nama maks. ${MENU_RULES.nameMax} karakter, deskripsi maks. ${MENU_RULES.descriptionMax}`}
        />

        <label className="ce-label" htmlFor="nama-menu">
          Nama Menu
        </label>
        <div className="relative">
          <input
            id="nama-menu"
            value={nama}
            maxLength={MENU_RULES.nameMax}
            onChange={(event) => setNama(event.target.value)}
            placeholder="Contoh: Ayam Geprek Sambal Matah Spesial"
            className="ce-field pr-12"
          />
          {validasi.namaOk ? (
            <Icon
              name="check_circle"
              size={20}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-primary"
            />
          ) : null}
        </div>
        <p className={`mt-1 text-caption ${validasi.namaOk ? 'text-primary' : 'text-danger'}`}>
          {nama.trim().length}/{MENU_RULES.nameMax} karakter · minimal {MENU_RULES.nameMin}
        </p>

        <p className="ce-label mt-4">Kategori Menu Kantin</p>
        <div className="flex flex-wrap gap-2">
          {MENU_CATEGORIES.map((item) => (
            <button
              key={item}
              type="button"
              aria-pressed={kategori === item}
              onClick={() => setKategori(item)}
              className={`ce-focus inline-flex h-9 items-center rounded-full px-3 font-display text-body-s transition duration-fast ease-emphasis ${
                kategori === item
                  ? 'bg-primary text-on-primary'
                  : 'border border-line-subtle bg-surface text-text-body hover:border-lav-400'
              }`}
            >
              {item}
            </button>
          ))}
        </div>

        <label className="ce-label mt-4" htmlFor="deskripsi-menu">
          Deskripsi
        </label>
        <textarea
          id="deskripsi-menu"
          rows={4}
          value={deskripsi}
          maxLength={MENU_RULES.descriptionMax}
          onChange={(event) => setDeskripsi(event.target.value)}
          placeholder="Jelaskan bahan utama, porsi, dan ciri khas menu."
          className="ce-focus w-full rounded-md border-2 border-transparent bg-lav-200 p-3 font-sans text-body-m text-text-strong focus:border-primary"
        />
        <p className="mt-1 text-right text-caption text-text-muted">
          {deskripsi.length} / {MENU_RULES.descriptionMax} karakter
        </p>

        <label className="ce-label mt-4" htmlFor="harga-menu">
          Harga Mahasiswa (Rp)
        </label>
        <div className="flex items-center gap-3">
          <div className="relative flex-1">
            <span className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 font-display text-body-m text-text-muted">
              Rp
            </span>
            <input
              id="harga-menu"
              type="number"
              min={MENU_RULES.priceMin}
              max={MENU_RULES.priceMax}
              step={MENU_RULES.priceStep}
              value={harga}
              onChange={(event) => setHarga(Number(event.target.value) || 0)}
              className="ce-field pl-10"
            />
          </div>
          <span className="shrink-0 text-caption font-semibold text-primary">
            Bebas potongan komisi
          </span>
        </div>
        <p className={`mt-1 text-caption ${validasi.hargaOk ? 'text-text-muted' : 'text-danger'}`}>
          Rentang {rupiah(MENU_RULES.priceMin)} – {rupiah(MENU_RULES.priceMax)} dan kelipatan Rp
          {' '}{MENU_RULES.priceStep}.
        </p>

        <div className="mt-3">
          <Callout>
            Komisi stan 0% (Subsidi Mitra BEM Kampus) — harga yang kamu isi adalah harga
            yang dibayar mahasiswa tanpa markup tambahan.
          </Callout>
        </div>

        <TonalCard className="mt-3 bg-lav-300">
          <div className="flex items-start justify-between gap-3">
            <div>
              <p className="font-display text-h5">Status Ketersediaan</p>
              <p className="text-caption text-text-muted">
                Matikan bila bahan hari ini habis; menu tetap tampil dengan label habis.
              </p>
            </div>
            <Toggle checked={tersedia} onChange={setTersedia} label="Ketersediaan menu" />
          </div>

          <div className="mt-3 flex flex-wrap items-center justify-between gap-3">
            <span className="text-body-s text-text-strong">
              Kuota Masak Harian
              <span className="block text-caption text-text-muted">
                Dipakai sebagai batas porsi otomatis di katalog mahasiswa.
              </span>
            </span>
            <span className="flex items-center gap-2">
              <input
                aria-label="Kuota masak harian"
                type="number"
                min={MENU_RULES.quotaMin}
                max={MENU_RULES.quotaMax}
                value={kuota}
                onChange={(event) => setKuota(Number(event.target.value) || 0)}
                className="h-11 w-24 rounded-md bg-surface px-3 text-right font-display text-body-m font-bold text-text-strong focus:outline-none focus:ring-2 focus:ring-primary"
              />
              <span className="text-caption text-text-muted">Porsi</span>
            </span>
          </div>

          {!validasi.kuotaOk || !validasi.hargaOk ? (
            <p className="mt-2 text-caption text-danger">
              Periksa kembali harga dan kuota harian agar sesuai rentang yang diizinkan.
            </p>
          ) : null}
        </TonalCard>
      </Panel>
      <VariasiEditor
        groups={groups}
        onUbahJudulGrup={ubahJudulGrup}
        onTambahGrup={tambahGrup}
        onHapusGrup={hapusGrup}
        onTambahOpsi={tambahOpsi}
        onHapusOpsi={hapusOpsi}
        onUbahOpsi={ubahOpsi}
        onJadikanDefault={jadikanDefault}
      />

      {/* Callout kebijakan + jam operasional */}
      <section className="rounded-lg bg-lav-300 p-3">
        <p className="flex items-center gap-2 font-display text-h5">
          <Icon name="verified_user" size={22} className="text-primary" />
          Kebijakan Menu Halal &amp; Higienis UKM Kampus
        </p>
        <p className="mt-1 text-body-s text-text-body">
          Menu yang diterbitkan langsung tampil di etalase mahasiswa pada jam operasional
          stan. Perubahan jadwal dilakukan dari halaman Pengaturan Toko.
        </p>
        <ul className="mt-2 space-y-1">
          {STORE_SCHEDULE.map((row) => (
            <li
              key={row.id}
              className="flex flex-wrap items-center justify-between gap-2 rounded-sm bg-surface p-2 text-caption"
            >
              <span className="text-text-strong">
                {row.day} · {row.note}
              </span>
              <span className="font-mono text-primary">
                {row.ranges.map((jam) => waktuWib(jam)).join(' – ')}
              </span>
            </li>
          ))}
        </ul>
      </section>

      {/* CTA bar */}
      <div className="sticky bottom-0 grid gap-2 rounded-bento border border-line-subtle bg-surface p-3 shadow-bar-top sm:grid-cols-[1fr_2fr]">
        <button
          type="button"
          onClick={() => setPesan('Draf menu tersimpan di perangkat stan.')}
          className="ce-btn-tonal h-12"
        >
          <Icon name="save" size={20} />
          Simpan Draf
        </button>
        <button
          type="button"
          disabled={!siapTerbit}
          onClick={() =>
            setPesan(`Menu "${nama.trim()}" diterbitkan dan tampil di katalog mahasiswa.`)
          }
          className="ce-btn-primary h-12 disabled:cursor-not-allowed disabled:bg-lav-400 disabled:text-text-muted disabled:shadow-none"
        >
          <Icon name="check_circle" size={20} />
          Terbitkan Menu
        </button>

        <p role="status" className="text-caption text-text-muted sm:col-span-2">
          {pesan
            ? pesan
            : siapTerbit
              ? 'Semua validasi lolos. Menu siap diterbitkan ke etalase mahasiswa.'
              : `Lengkapi dulu: ${[
                  [validasi.namaOk, 'nama menu'],
                  [validasi.deskripsiOk, 'deskripsi'],
                  [validasi.hargaOk, 'harga'],
                  [validasi.kuotaOk, 'kuota harian'],
                  [validasi.fotoOk, 'foto utama'],
                  [validasi.grupOk, 'jumlah grup variasi'],
                  [validasi.opsiOk, 'opsi tiap grup'],
                  [validasi.bawaanOk, 'opsi bawaan grup wajib'],
                ]
                  .filter(([ok]) => !ok)
                  .map(([, label]) => label)
                  .join(', ')}.`}
        </p>
      </div>
    </div>
  );
}
