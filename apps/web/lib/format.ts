/**
 * Format angka & mata uang untuk seluruh UI web.
 * Aturan `docs/Design.md` §A.2: locale `id-ID` (titik ribuan, koma desimal),
 * awalan `Rp` + nilai, mis. `Rp 21.000`.
 */

const RUPIAH = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  maximumFractionDigits: 0,
});

const ANGKA = new Intl.NumberFormat('id-ID');

/** `19500` → `Rp 19.500` */
export function rupiah(value: number): string {
  return RUPIAH.format(Math.round(value));
}

/** `10000` → `10.000` */
export function angka(value: number): string {
  return ANGKA.format(value);
}

/** `0.5` → `0,5%` */
export function persen(value: number, fractionDigits = 1): string {
  const formatted = new Intl.NumberFormat('id-ID', {
    minimumFractionDigits: fractionDigits,
    maximumFractionDigits: fractionDigits,
  }).format(value);
  return `${formatted}%`;
}

/** Label waktu relatif untuk toast aktivitas & baris riwayat. */
export function waktuRelatif(detik: number): string {
  if (detik < 60) return `${detik} detik lalu`;
  const menit = Math.floor(detik / 60);
  if (menit < 60) return `${menit} menit lalu`;
  const jam = Math.floor(menit / 60);
  return `${jam} jam lalu`;
}

/** `07:30` → `07.30 WIB` (gaya waktu pada kartu jadwal, Design.md §B.5). */
export function waktuWib(hhmm: string): string {
  return `${hhmm.replace(':', '.')} WIB`;
}
