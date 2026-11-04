# Design.md — Campus Express Design System & UI Specification

| Item | Isi |
|---|---|
| Sumber | 27 tangkapan layar mockup (Stitch): 20 layar mobile pada kiriman pertama (gambar 1–20); 6 layar mobile dan 1 Web Landing Page pada kiriman kedua (gambar 21–27) |
| Target implementasi | Flutter (mobile), Next.js 15 + Tailwind (web) |
| Cakupan layar | Semua 22 layar pada `PRD.md` §9 dan Web Landing Page. Layar 1–16 = gambar 1–20. Layar 17 = gambar 22, layar 18 = gambar 23, layar 19 = gambar 24, layar 20 = gambar 21, layar 21 = gambar 26, layar 22 = gambar 25. Web Landing Page = gambar 27 |
| Duplikat/varian | Gambar 18 dan 19 identik. Gambar 1 dan 12 = Live Tracking (versi awal dan versi dengan peta isometrik). Gambar 3 dan 6 = Beranda (versi awal dan revisi). Gambar 2 dan 15 = Detail Kantin/Customizer. Versi yang dipakai sebagai acuan: 12, 6, 15. Gambar 21–27 tidak memiliki duplikat |
| Akurasi nilai | Hex dan dimensi diestimasi secara visual dari gambar (lebar gambar 388–706 px, skala berbeda per gambar). Toleransi ±2 dp. Ganti dengan token ekspor Stitch bila berkas aslinya tersedia |
| Akurasi gambar 21–27 | Gambar 22 berlebar 285 px (skala 0,73 px/dp) dan gambar 27 adalah tangkapan halaman penuh berlebar 627 px. Untuk gambar 27, viewport diasumsikan 1280 px (skala ±0,49). Dimensi dari kedua gambar kurang presisi (±4 dp/px) dan harus dicek ulang terhadap mockup beresolusi penuh |
| Verifikasi ulang (5 Nov 2026) | Gambar 21, 22, 23, 24, 25, 26, dan 27 dibandingkan ulang dengan bagian C.17–C.23, B.5, dan Bagian F; semua blok, label, dan angka utama cocok dan tidak ada yang diubah. Hanya data contoh dan temuan yang belum tercatat yang ditambahkan (C.17, C.19, C.21, C.23, T-31 sampai T-35) |
| Satuan | `dp` = Flutter logical pixel = `px` CSS pada viewport 390 px |
| Bahasa UI | Bahasa Indonesia. Format angka `id-ID` (titik ribuan, koma desimal) |

---

## A. Design Tokens

### A.1 Color Palette

Mockup memakai tema terang. Warna hijau tua dipakai untuk aksi, kartu hero, dan teks aktif. Latar halaman putih kebiruan. Permukaan sekunder berwarna lavender. Ini berbeda dari tema gelap pada `PRD.md` §9.2 (lihat Bagian F, temuan T-01).

#### Brand

| Token | Hex | Pemakaian pada mockup |
|---|---|---|
| `primary` | `#006C4A` | Tombol utama, kartu hero Ride Kampus, kartu Dompet, bubble chat keluar, ikon dan teks nav aktif, link teks, avatar profil di app bar |
| `primary-pressed` | `#00553A` | State tekan tombol utama, teks pada chip mint |
| `primary-bright` | `#059669` | Ikon status selesai di stepper, indikator rute pada peta, aksen 4 dp pada kartu |
| `primary-glow` | `#10B981` | Titik status online, garis rute progres |
| `on-primary` | `#FFFFFF` | Teks dan ikon di atas `primary` |
| `on-primary-muted` | `rgba(255,255,255,0.78)` | Teks deskripsi di atas kartu hero |

#### Mint (container hijau muda)

| Token | Hex | Pemakaian |
|---|---|---|
| `mint-300` | `#8DF3CE` | Chip "Aktif", "Online", "Rekomendasi", "Tip", tombol Top-Up di atas kartu hijau, bubble event sistem di chat |
| `mint-100` | `#CFF8E8` | Tile ikon layanan, baris terpilih (lokasi, opsi), badge rating, kotak "Verifikasi Otomatis" |
| `on-mint` | `#00553A` | Teks dan ikon di atas mint |

#### Surface dan Background

| Token | Hex | Pemakaian |
|---|---|---|
| `bg` | `#F8F9FF` | Latar semua halaman, latar app bar |
| `surface` | `#FFFFFF` | Kartu, bottom nav, sheet, input pencarian |
| `lav-100` | `#F1F3FF` | Kotak info dalam kartu, baris opsi tidak terpilih |
| `lav-200` | `#E9EDFF` | Field input (NIM, OTP, catatan), tombol sekunder, tile ikon netral |
| `lav-300` | `#E2E7FF` | Kartu tonal (PIN, Katalog UMKM, statistik, Ambil Sendiri), bubble chat masuk, tombol keypad, baris opsi terpilih |
| `lav-400` | `#D5DBF5` | Lingkaran radio kosong, track toggle mati, tombol hapus di input |
| `ink-800` | `#1F2A3C` | Bar keranjang melayang, placeholder peta |

#### Text

| Token | Hex | Pemakaian |
|---|---|---|
| `text-strong` | `#0F1A2B` | Judul, harga, angka besar |
| `text-body` | `#3E4A5A` | Paragraf, deskripsi kartu |
| `text-muted` | `#5B6676` | Label sekunder, waktu, placeholder, ikon nonaktif. Pada mockup tampak lebih terang (±`#6B7686`, kontras 3,75:1 di atas `lav-300`); nilai ini dipakai agar lolos 4,5:1 di atas `surface`, `bg`, `lav-200`, dan `lav-300` |
| `text-link` | `#006C4A` | Link teks (Ubah, Lihat Semua, Detail, Kelola) |

#### Border

| Token | Nilai | Pemakaian |
|---|---|---|
| `border-subtle` | `1px solid #E3E7F4` | Kartu putih di atas `bg`, field pencarian |
| `border-selected` | `2px solid #006C4A` | Kartu peran terpilih (Onboarding) |
| `divider` | `1px solid #ECEFFA` | Pemisah baris mutasi, dalam kartu |

#### Semantic

| Token | Hex | Pemakaian |
|---|---|---|
| `danger` | `#BA1A1A` | "Stok Kritis", "Habis", nominal potongan (`- Rp 300`), timer kedaluwarsa, tombol Keluar, ikon cabai |
| `danger-container` | `#FFDAD6` | Tombol Tolak, ikon "Perlu Respon", ikon Bantuan |
| `info` | `#00639B` | Angka statistik biru ("1.482", "6.4"), ikon bintang di profil, status Pre-Order |
| `info-100` | `#D2EBFF` | Tile ikon layanan Nebeng pada daftar riwayat (gambar 23) |
| `star` | `#F59E0B` | Bintang rating pada kartu menu |
| `warning-text` | `#B45309` | Catatan khusus pesanan pada tiket dapur ("Catatan: Kol Goreng, Sambal Terpisah") |

#### Peta isometrik (gambar 12)

| Token | Hex | Elemen |
|---|---|---|
| `map-bg` | `#F2F4FF` | Latar peta |
| `map-road` | `#DDE3FB` | Jalan, lebar 24 dp |
| `map-bldg-top` | `#FFFFFF` | Atap bangunan netral |
| `map-bldg-left` | `#E3E7F0` | Sisi kiri bangunan |
| `map-bldg-right` | `#CBD2DD` | Sisi kanan bangunan |
| `map-dest-top` | `#CFF8E8` | Atap bangunan tujuan |
| `map-dest-side` | `#006C4A` | Sisi bangunan tujuan |
| `map-flag` | `#BA1A1A` | Bendera tujuan |
| `map-route` | `#059669` | Garis rute putus-putus |
| `map-label` | `#3E4A5A` | Label bangunan, 11 sp / 500 |

#### Gradien dan overlay

| Token | Nilai | Pemakaian |
|---|---|---|
| `grad-wallet` | `linear-gradient(135deg, #006C4A 0%, #047857 100%)` | Kartu Dompet, kartu promo MABAEXPRESS |
| `overlay-photo` | `linear-gradient(to top, rgba(0,0,0,0.65), rgba(0,0,0,0) 60%)` | Teks putih di atas foto hero kantin |
| `deco-circle` | `rgba(255,255,255,0.08)` | Lingkaran dekoratif pojok kanan bawah kartu hero |

#### Pemetaan warna status

| Status | Background | Teks | Contoh |
|---|---|---|---|
| Sukses/aktif | `mint-300` | `on-mint` | Aktif, Online, Siap Dispatch, Selesai |
| Info/netral | `lav-300` | `#2F3B8F` | Paling Populer, Pre-Order, Zona 1, Hub, Internal |
| Peringatan stok | `danger-container` | `danger` | Sisa 4 Porsi, Habis |
| Bahaya | `danger-container` | `danger` | Perlu Respon, Tolak |
| Mati | `lav-200` | `text-muted` | Kehabisan, nonaktif |

### A.2 Typography

Font heading: Plus Jakarta Sans (hasil identifikasi visual). Font body: Inter. Font monospace untuk ID order, plat, timer: JetBrains Mono. Ketiga font dibundel di aset aplikasi (tanpa unduh saat runtime).

| Token | Font | Size / Line | Weight | Letter-spacing | Pemakaian |
|---|---|---|---|---|---|
| `display` | Plus Jakarta Sans | 40 / 48 | 800 | -0.5 | Saldo Dompet (`14.500`) |
| `h1` | Plus Jakarta Sans | 28 / 34 | 800 | -0.3 | "Masuk Akun Mahasiswa", "Ride Kampus", "Satu Aplikasi untuk" |
| `h2` | Plus Jakarta Sans | 22 / 28 | 700 | -0.2 | Nama kantin pada hero, "Pesanan #CX-8821", total Rp 27.000 |
| `h3` | Plus Jakarta Sans | 18 / 24 | 700 | -0.1 | Judul seksi ("Kantin Favorit Terdekat", "Pesanan Aktif Dapur") |
| `h4` | Plus Jakarta Sans | 16 / 22 | 700 | 0 | Judul kartu, nama menu, nama orang, label tombol |
| `h5` | Plus Jakarta Sans | 15 / 20 | 600 | 0 | Judul baris daftar (lokasi, mutasi) |
| `body-l` | Inter | 16 / 24 | 400 | 0 | Isi field input, teks bubble chat |
| `body-m` | Inter | 14 / 20 | 400 | 0 | Deskripsi kartu, subjudul |
| `body-s` | Inter | 13 / 18 | 400 | 0 | Meta baris (rating, jarak) |
| `caption` | Inter | 12 / 16 | 500 | 0.1 | Label stat, waktu, label stepper |
| `micro` | Inter | 11 / 14 | 700 | 0.4, UPPERCASE | Eyebrow ("CAMPUS EXPRESS AUTH", "KAMPUS UTAMA"), badge |
| `price` | Plus Jakarta Sans | 16 / 22 | 700 | 0 | Harga pada kartu menu dan CTA |
| `price-l` | Plus Jakarta Sans | 20 / 26 | 800 | 0 | Total pada bar checkout |
| `pin` | Plus Jakarta Sans | 32 / 40 | 800 | 0 | Digit PIN |
| `mono` | JetBrains Mono | 12 / 16 | 700 | 0.3 | `#CX-8821`, plat `AB 4921 KM`, timer `00:48` |

Aturan:
- Angka rupiah: awalan `Rp` + spasi tipis + angka, mis. `Rp 21.000`. Di kartu saldo, `Rp` 20 sp / 600 dan angka 40 sp / 800 pada baseline yang sama.
- Teks panjang dipotong satu baris dengan ellipsis kecuali deskripsi (maks. 2 baris).
- Skala font sistem didukung sampai 200%. Komponen berlabel panjang (tombol CTA dengan harga, chip) harus mengizinkan 2 baris atau menyingkat label (lihat F, T-14).

#### Skala Web (Landing Page)

Estimasi dari gambar 27 dengan asumsi viewport 1280 px. Font sama dengan mobile (Plus Jakarta Sans untuk heading, Inter untuk body).

| Token | Size / Line | Weight | Pemakaian |
|---|---|---|---|
| `web-h1` | 40 / 48 (di bawah `lg`: 32 / 38) | 800, letter-spacing -0.5 | Judul hero |
| `web-h2` | 26 / 32 (di bawah `lg`: 22 / 28) | 800, letter-spacing -0.3 | Judul seksi |
| `web-eyebrow` | 11 / 14 | 700, UPPERCASE, letter-spacing 0.6, `primary` | "WORKFLOW CEPAT", "PERBANDINGAN NYATA", "TESTIMONI OTENTIK" |
| `web-stat` | 30 / 36 | 800 | Angka statistik (`10.000+`, `0.5%`) |
| `web-body` | 16 / 24 | 400, `text-body` | Paragraf hero dan seksi, maks. 640 px |
| `web-card-title` | 16 / 22 | 700 | Judul kartu bento dan workflow |
| `web-small` | 13 / 18 | 400 | Deskripsi kartu, label tabel perbandingan |

### A.3 Spacing & Grid

Skala dasar 4 dp (setara Tailwind `1 = 4px`).

| Token | dp | Tailwind | Pemakaian |
|---|---|---|---|
| `sp-1` | 4 | `1` | Jarak ikon–label dalam chip |
| `sp-2` | 8 | `2` | Gap statistik 3 kolom, jarak antar chip |
| `sp-3` | 12 | `3` | Gap antar kartu bento, padding dalam chip besar |
| `sp-4` | 16 | `4` | Margin halaman, padding kartu |
| `sp-5` | 20 | `5` | Padding kartu hero |
| `sp-6` | 24 | `6` | Jarak antar seksi |
| `sp-8` | 32 | `8` | Jarak sebelum footer |

Struktur halaman mobile:

| Aturan | Nilai |
|---|---|
| Margin horizontal halaman | 16 dp |
| Jarak vertikal antar kartu | 12 dp (dalam satu seksi), 24 dp (antar seksi) |
| Padding kartu | 16 dp (hero 20 dp) |
| Padding bawah konten | 24 dp + tinggi bottom nav / CTA bar |
| Grid bento 2 kolom | 2 × `(lebar − 32 − 12) / 2`, gap 12 dp, kartu persegi 171 × 170 dp pada 390 dp |
| Grid statistik 3 kolom | 3 sel sama lebar, gap 8 dp, dalam wadah tonal `lav-300` padding 8 dp |
| Grid nominal top-up | 2 × 2, gap 12 dp |
| Rail horizontal | Kartu 256 dp lebar, gap 12 dp, margin kiri 16 dp, kartu berikutnya terpotong 24–40 dp di kanan |
| Keypad PIN | 3 kolom × 4 baris, tombol 104 × 40 dp, gap 8 dp |

Breakpoint web: `sm 640`, `md 768`, `lg 1024`, `xl 1280`. Kontainer maks. 1280 px (konten 1248 px dengan padding 16), padding sisi 16 / 24 / 32 px. Grid seksi landing: 4 kolom (statistik, workflow), 3 kolom (bento, testimoni), gap 12.

### A.4 Radii

| Token | Nilai | Pemakaian |
|---|---|---|
| `r-xs` | 4 dp | Kotak checkbox |
| `r-sm` | 8 dp | Tombol keypad dalam sel kecil, thumbnail kecil |
| `r-md` | 12 dp | Field input, tile ikon, baris opsi, thumbnail menu, kotak PIN, kotak info |
| `r-lg` | 16 dp | Kartu standar, tombol utama, search field |
| `r-xl` | 24 dp | Kartu hero (Ride Kampus, Dompet, promo) |
| `r-sheet` | 28 dp (sudut atas) | Bottom sheet (landmark picker, panel tracking) |
| `r-pill` | 999 dp | Chip, badge, pill status, toggle |

### A.5 Shadows

| Token | CSS / Flutter | Pemakaian |
|---|---|---|
| `shadow-card` | `0 1px 3px rgba(15,26,43,.06), 0 1px 2px rgba(15,26,43,.04)` | Kartu putih |
| `shadow-bar-top` | `0 -4px 16px rgba(15,26,43,.08)` | CTA bar bawah, bottom nav, bar keranjang |
| `shadow-float` | `0 8px 24px rgba(15,26,43,.14)` | Toast, tombol recenter peta, ETA pill di peta |
| `shadow-cta` | `0 4px 10px rgba(0,108,74,.28)` | Tombol utama berisi ("Lanjutkan SSO Kampus", "Masuk & Verifikasi Akun") |
| `shadow-none` | — | Chip, badge, kartu tonal |

Flutter:

```dart
const shadowCard = [
  BoxShadow(color: Color(0x0F0F1A2B), blurRadius: 3, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x0A0F1A2B), blurRadius: 2, offset: Offset(0, 1)),
];
const shadowBarTop = [BoxShadow(color: Color(0x140F1A2B), blurRadius: 16, offset: Offset(0, -4))];
const shadowFloat = [BoxShadow(color: Color(0x240F1A2B), blurRadius: 24, offset: Offset(0, 8))];
const shadowCta = [BoxShadow(color: Color(0x47006C4A), blurRadius: 10, offset: Offset(0, 4))];
```

### A.6 Ikon dan Gambar

| Aspek | Spesifikasi |
|---|---|
| Set ikon | Material Symbols Outlined, weight 400, optical size 24 |
| Ukuran | 24 dp default, 20 dp di dalam chip dan tombol, 16 dp di dalam badge |
| Tile ikon | 40 × 40 dp (kartu layanan 44 × 44), radius 12, latar `mint-100` atau `lav-200`, ikon `primary` |
| Avatar | Lingkaran 40 dp (app bar), 56 dp (kartu driver), 72 dp (profil), inisial 2 huruf pada avatar chat (32 dp, latar `lav-300`, teks `#2F3B8F` / 700) |
| Foto menu | Radius 12, rasio 1:1 (daftar), 16:9 (rail), WebP ≤ 80 KB |
| Foto hero | Rasio 16:7, radius 12 (auth) atau penuh lebar dengan sudut bawah 16 (kantin), overlay `overlay-photo` |
| Logo | Slot 28 dp tinggi di app bar. Harus ada fallback (`errorBuilder`) ke tile "CE" 40 dp `primary` dengan teks putih 16 sp / 800 (bentuk yang dipakai pada gambar 6) |

---

## B. Atomic Component Library

Semua tinggi minimum target sentuh 44 dp.

### B.1 Buttons

| Varian | Tinggi | Radius | Background | Teks | Ikon | State |
|---|---|---|---|---|---|---|
| Primary | 48 | `r-lg` (16) | `primary` | `on-primary`, `h4` 16 / 700 | 20 dp, kiri atau kanan | pressed `primary-pressed` + scale 0.98; disabled `lav-400` teks `text-muted`; shadow `shadow-cta` |
| Primary CTA berisi (checkout) | 52 | 16 | `primary` | Label kiri + harga kanan, `h4` | Ikon kiri 20 dp | Label tidak boleh membungkus: gunakan `Row` dengan `Flexible` dan harga `FittedBox` |
| **Claim 1-Click** | 52 | 16 | `primary` | `AMBIL ORDER INI (1-Click Claim)`, 14 sp / 700, huruf kapital, spasi 0.2 | `bolt` 20 dp kiri | Setelah ditekan: label diganti spinner 20 dp, tombol nonaktif sampai respons Gateway; gagal `ORDER_TAKEN` → tombol diganti teks "Order sudah diambil" di `lav-200` |
| Primary compact (Ambil Nebeng) | 44 | 14 | `primary` | `h4` + ikon panah kanan | `arrow_forward` 20 dp | Lebar mengikuti konten, di kanan baris "Tarif Bersih" |
| Tonal | 44 | 14 | `lav-300` (tombol Telepon, Bagikan, Ambil Order) | `text-strong` 14 / 600 | 20 dp kiri | pressed `lav-400` |
| Tonal danger | 48 | 14 | `danger-container` | `danger` 14 / 700 | `close` kiri | Tolak order |
| Mint on-dark | 48 | 14 | `mint-300` | `on-mint` 14 / 700 | 20 dp kiri | Top-Up QRIS di kartu Dompet |
| Glass on-dark | 48 | 14 | `rgba(255,255,255,0.16)` | `on-primary` 14 / 600 | 20 dp kiri | Tarik Saldo di kartu Dompet |
| White on-hero | 48 | 14 | `surface` | `primary` 16 / 700 + panah | `arrow_forward` kanan | "Pesan Nebeng Sekarang" di kartu hero |
| Ghost / text | 32 (tinggi sentuh 44) | — | transparan | `text-link` 14 / 600 | opsional `chevron_right` 16 | Ubah, Lihat Semua, Detail, Kelola, Cek Menu |
| Icon button | 40 × 40 | pill | `surface` + `shadow-float` | ikon `text-strong` 22 dp | — | Recenter peta, bell, search |
| Add (+) | 40 × 40 | 12 | `primary` | ikon `add` putih 22 dp | — | Daftar menu |
| Quantity stepper | 36 × 36 per tombol | 10 | `surface` + border `border-subtle` | ikon `remove`/`add` 20 dp, angka 16 / 700 di tengah | — | Dibungkus wadah border 2 px `lav-300` radius 14, padding 4; minimum 1 |
| Keypad | 104 × 40 | 10 | `lav-300` | angka 20 / 600 `primary` | `C` dan `backspace` pada baris terakhir | pressed `lav-400`, haptic ringan |

### B.2 Inputs & Forms

| Komponen | Spesifikasi |
|---|---|
| TextField (NIM, OTP) | Tinggi 56, radius 12, fill `lav-200`, tanpa border. Ikon kiri 20 dp `text-muted` (topi wisuda untuk NIM, gembok untuk OTP), teks `body-l`, aksi kanan: tombol hapus (lingkaran 28 dp `lav-400` + ikon `close` 16) atau ikon mata. Fokus: border 2 px `primary`. Error: border 2 px `danger` + pesan 12 sp `danger` di bawah |
| Label field | Baris di atas field: label `body-s` 13 / 600 kiri, aksi teks kanan (`Kirim OTP WA`) `text-link` 13 / 600 |
| Validasi inline | Chip mint kecil di sisi kanan label ("● Format valid (FST - Teknik)") hanya muncul bila NIM lolos pola; tinggi 28, `micro` |
| Helper OTP | Satu baris: titik mint 6 dp + teks 13 sp (`Terkirim ke WhatsApp +62 812-****-8821`), timer `mono` 13 sp di kanan (`00:48`). Nomor selalu dimasker |
| Search field | Tinggi 48, radius 16, fill `surface`, border `border-subtle`, ikon kiri `search`, placeholder `text-muted`, ikon kanan `mic` (katalog) atau `qr_code_scanner` (beranda) |
| Sort dropdown | Tinggi 48, radius 16, `surface` + border, ikon `tune` kiri, label "Terdekat", `expand_more` kanan |
| Filter chips (scroll horizontal) | Tinggi 36, padding 12, radius pill. Terpilih: fill `primary`, teks putih 14 / 600, ikon 18 dp. Tidak terpilih: fill `surface`, border `border-subtle`, teks `text-body`. Gap 8 dp. Chip terakhir terpotong di tepi kanan sebagai penanda scroll |
| Dropdown Landmark | Bukan dropdown: bottom sheet daftar landmark (lihat C.4). Pemicu: kartu rute dengan dua baris Titik Jemput / Tujuan |
| Textarea catatan | Fill `lav-200`, radius 12, tinggi 3 baris (72), placeholder `text-muted` 14 sp, penghitung `0/100` kanan atas 12 sp. Batas 100 karakter |
| Checkbox | 20 × 20, radius 4. Terpilih fill `primary` + centang putih. Label 14 sp / 500 |
| Radio | Lingkaran 22 dp. Kosong: fill `lav-400` tanpa border. Terpilih: fill `primary` + titik putih 8 dp |
| Baris opsi (radio/checkbox) | Tinggi min. 60, radius 12, padding 12; tidak terpilih fill `lav-100`, terpilih fill `lav-300`. Kiri: kontrol + dua baris teks (judul `h5`, deskripsi `caption` `text-muted`; sub-label bernada khusus pakai warna semantik, mis. "Uji Nyali Ujian Tengah Semester" `danger`). Kanan: harga tambahan `+Rp 1.000` `text-link` 14 / 600 atau "Gratis" `text-muted`. Badge wajib/opsional di header grup |
| Toggle | Track 52 × 32, radius pill. Aktif: track `primary`, thumb putih 24 dp (boleh berisi ikon centang 14 dp). Mati: track `lav-400`, thumb putih |
| PIN 4 digit — tampilan (konsumen) | 4 kotak 70 × 56 dp, gap 12, fill `lav-300` (di atas kartu `lav-100`) atau `surface` (di atas kartu `lav-300`), radius 12, digit `pin` `primary`. Dibaca oleh konsumen, tidak dapat diedit. Label di atas: ikon perisai + `micro` "PIN VERIFIKASI SERAH TERIMA", badge "Aman" kanan |
| PIN 4 digit — input (driver) | 4 slot 52 × 60 dp, gap 12, radius 12, fill `lav-300`. Terisi: digit 28 sp / 800 `primary`. Kosong: titik 10 dp `text-muted`. Slot aktif: border 2 px `primary`. Digit tidak dimasking (driver perlu memeriksa input). Di bawahnya keypad B.1 |

### B.3 Cards (Bento)

Semua kartu: radius `r-lg` (16), padding 16, `shadow-card` kecuali disebut lain.

| Kartu | Struktur | Detail |
|---|---|---|
| Hero layanan (Ride Kampus) | Fill `primary` radius 24, padding 20, tinggi ±188. Baris atas: pill eyebrow (`micro` putih di `rgba(255,255,255,0.16)`) + pill harga ("Rp 4.000 Flat Se-Kampus", fill `mint-300`). Judul `h1` putih. Deskripsi `body-m` `on-primary-muted` maks. 2 baris. Tombol White on-hero. Pojok kanan bawah: `deco-circle` diameter 160 dp terpotong tepi; tumpukan avatar 3 lingkaran (28 dp, overlap −8) + "+12" |
| Kartu layanan (grid 2 kolom) | Tile ikon 44 kiri atas, badge kanan atas (pill `mint-100`/`lav-300`), judul `h4`, deskripsi `body-s` 2 baris, link ghost di dasar kartu dengan panah |
| Kartu tonal banner (Katalog UMKM) | Fill `lav-300`, tanpa shadow, tile ikon `primary` putih 48 dp kiri, judul `h4`, deskripsi 1–2 baris, pill "Pre-Order" mint, tombol panah lingkaran 40 dp `surface` kanan |
| Wadah statistik (Radar Kampus / Lalu Lintas Koridor) | Fill `lav-300` (gambar 6) atau `surface` (gambar 3), radius 16, padding 8. Judul baris di atas `h5` dengan ikon, badge kanan ("Live Sinkron"). 3 sel putih radius 12 tinggi 76: angka `h1`-turunan 26 / 800 (`primary` atau `info`), label `caption` |
| Kartu menu (daftar, gambar 8) | Baris: thumbnail 96 × 96 radius 12 kiri dengan badge overlay kiri atas (pill 22 dp, fill `primary` atau semantik, teks `micro` putih), konten kanan: nama `h4` 1 baris, merchant `body-s` + ikon toko, baris meta: bintang `star` 14 dp + rating + (jumlah ulasan) + titik status. Dasar konten: kotak fill `lav-100` radius 12 berisi harga `price` kiri dan tombol Add 40 dp kanan |
| Kartu menu (rail, gambar 3/6) | Lebar 256, gambar 16:9 tinggi 112 radius atas 16, badge waktu kiri atas (fill putih 90%, ikon jam), badge rating kanan atas. Isi: nama `h4`, lokasi `body-s`, harga `price`, tombol Add 40 dp kanan bawah (atau tombol lebar "+ Titip Beli" fill `mint-300`) |
| Kartu Order Radar | Border-top 3 dp `primary` untuk prioritas tinggi. Baris chip (Prioritas Tinggi `mint-300`, kategori `lav-300`, estimasi waktu kanan dengan ikon jam). Rute dua titik: titik asal bulat `primary` (outline), titik tujuan pin `info`, garis vertikal 2 dp `lav-400` di antaranya; nama titik `h4`, detail `body-s` `text-muted`. Kotak item fill `lav-100`. Kotak penghasilan fill `mint-100`: label `caption`, nilai `h2` `primary`, chip tip kanan. Bar kedaluwarsa (lihat B.4). Tombol Claim |
| Kartu Dompet | `grad-wallet`, radius 24, padding 20. Eyebrow `micro` + pill status "Saldo Aman • Order Aktif" (`mint-300`), saldo `display`, teks penjelas `body-s` `on-primary-muted`, kotak peringatan (fill `rgba(255,255,255,0.12)` radius 12, ikon `warning`), dua tombol berdampingan |
| Kartu Tiket Dapur | Chip status kiri ("BARU MASUK • 1 Menit Lalu" fill `danger-container`/`danger`, atau "SEDANG DIMASAK • Sisa 4 mnt" fill `mint-300`), ID `mono` kanan, kartu nama pemesan + chip "Kurir Kampus", daftar item (`2x` dalam kotak 28 dp fill `lav-300`, nama `h5`, harga kanan), catatan `warning-text` dengan ikon peringatan, dua tombol (Tolak tonal danger 1 bagian, Terima & Masak primary 2 bagian) |
| Kartu Driver | Avatar 56 + nama `h4` + ikon centang verifikasi 16 `primary`, subteks `body-s`, plat chip kanan atas; baris rating (bintang, nilai, jumlah order) + tag "Rider Mahasiswa" kanan; tiga tombol tonal/primary sejajar (lihat catatan T-08 mengenai WA) |
| Kartu Ringkasan Order | Tile ikon 44 `mint-100`, chip merchant + label pembayaran (`mint-100`/`primary`), nama pesanan `h4` 1 baris, tambahan `body-s`, harga kanan `h4` dan porsi `caption`, baris lokasi dengan ikon pin + link "Detail" |
| Kartu Profil Identitas | Baris-baris fill `lav-100` radius 12, tile ikon 40, judul `h5`, subteks `caption`, ikon centang `primary` kanan atau tombol "Top Up" kecil `primary` (tinggi 32) |

### B.4 Micro-components

| Komponen | Spesifikasi |
|---|---|
| Status badge (pill) | Tinggi 24, padding horizontal 10, radius pill, `micro` 11 / 700. Variasi warna: tabel A.1 "Pemetaan warna status". Titik status 6 dp di depan teks bila statusnya "live" |
| Eyebrow | `micro` UPPERCASE, `primary`, di atas judul layar atau kartu ("CAMPUS EXPRESS LIVE", "MITRA CAMPUS") |
| Chip lokasi/zona | Tinggi 22, `micro`, fill `lav-300` teks `#2F3B8F`; "Hub" dan "Cepat Datang" fill `mint-300` |
| Pill header "Online" | Tinggi 44 (app bar driver), fill `mint-300`, titik `primary` 8 dp + teks `h5` `on-mint`; dapat diketuk untuk ganti status |
| Pill ETA di peta | Fill `surface`, radius pill, padding 8 / 16, `shadow-float`. Kiri: indikator melingkar 40 dp (progress 2 dp `primary`, titik tengah), kanan: dua baris ("Tiba ~4 Menit" `h4`, "350 meter menuju FST" `caption`) |
| Stepper status | 4 simpul sejajar, jarak sama, garis penghubung 3 dp. Selesai: lingkaran 36 `primary`, ikon centang putih. Aktif: lingkaran 36 `mint-300`, ikon `on-mint`, label `primary` / 700. Belum: lingkaran 36 `lav-200`, ikon `text-muted`. Garis selesai `primary`, garis belum `lav-300`. Label `caption` 12 / 600, waktu di bawahnya `caption` `text-muted` (`11:42`, `~11:58` untuk estimasi) |
| Bar kedaluwarsa | Track tinggi 6 `danger-container`, isi `danger` menyusut linear dari 100% ke 0% selama sisa waktu; label kiri "Kadaluarsa otomatis:" `caption` `danger`, angka detik `mono` 13 / 700 `danger` kanan |
| Plat chip | Fill `lav-300`, teks `mono` 12 / 700 `text-strong`, radius 8, padding 4 / 8. Pada versi awal (gambar 1): fill `ink-800` teks putih |
| Chip tip | Fill `mint-300`, teks `on-mint` 12 / 700 (`+Tip Rp 2.000`) |
| Live Ping (inline, mobile) | Kartu `surface` radius 16 padding 12: tile ikon bel 44 `mint-100` dengan titik online 10 dp `primary` di pojok, teks 2 baris (nama/menu `body-m`, status `caption`), pill "Live Ping 2m lalu" `lav-300` kanan. Pergantian isi tiap 6 dtk (D.5) |
| Toast sales ping (web) | Kartu `surface`, radius 16, `shadow-float`, border `border-subtle`, lebar maks. 320, kiri bawah, 16 dp dari tepi |
| Bubble chat masuk | Fill `lav-300`, teks `text-strong` `body-l`, radius 20 dengan sudut kiri bawah 6, padding 12 / 16, lebar maks. 78% layar, avatar inisial 32 dp di kiri bawah bubble |
| Bubble chat keluar | Fill `primary`, teks putih, radius 20 dengan sudut kanan bawah 6, rata kanan. Di bawah: waktu `caption` + ikon centang ganda (`primary-bright` bila dibaca, `text-muted` bila terkirim) |
| Bubble gambar | Gambar radius 14 di dalam bubble, label overlay kiri bawah (pill fill `rgba(0,0,0,0.55)` teks putih `caption`, ikon kamera 14) ("Bukti Titik Antar"), keterangan di bawah gambar `body-l` |
| Chip peristiwa sistem | Di tengah daftar chat, fill `mint-300`, teks `on-mint` 13 / 600, ikon `navigation` 16, radius pill, padding 8 / 16 |
| Pemisah tanggal | Pill `lav-300`, `caption` 12 / 600 (`Hari Ini • 11:45 WIB`) |
| Quick reply chip | Tinggi 40, fill `lav-300`, emoji + teks 14 / 500, radius pill, scroll horizontal, padding kiri 16 |
| Titik status stok | Titik 6 dp + teks 12 / 600: `Tersedia` `primary`, `Stok Kritis` `danger`, `Pre-Order 10m` `info` (ikon jam) |
| Verifikasi | Ikon `verified` 16 dp `primary` di kanan nama; chip "SSO Dikti Terverifikasi" `mint-100` / `primary` |
| Grabber sheet | 40 × 4 dp, fill `lav-400`, radius pill, 8 dp dari tepi atas sheet |
| Skeleton | Blok `lav-200` radius sesuai komponen, shimmer `lav-100` → `lav-200` 1.2 dtk linear loop |

### B.5 Komponen Tambahan (gambar 21–27)

| Komponen | Spesifikasi |
|---|---|
| App bar "Node" (layar 17, 18, 21, 22) | Tinggi 72. Kiri: tile 40 × 40 radius 12 fill `mint-300`, ikon truk `primary`. Tengah: baris atas judul `h3` + chip "CAMPUS" (`micro`, fill `mint-300`, teks `on-mint`, tinggi 20), baris bawah "Campus Express Node" `micro` 10 sp `text-muted`. Kanan: ikon bel 40 dan avatar 40. Tanpa tombol kembali (layar tab) |
| App bar alur (layar 19, 20) | Tombol kembali 24, judul `h4` + chip "CX" (`lav-300`, `micro`), avatar 40 |
| Tab status (segmented) | Wadah fill `lav-200`, radius 16, padding 4, 4 segmen sama lebar. Terpilih: fill `surface`, radius 12, `shadow-card`, teks `primary` 14 / 700, garis bawah 2 dp `primary` selebar teks, badge hitungan `mint-300` (tinggi 20, `micro`). Tidak terpilih: teks `text-body` 14 / 500, badge `lav-300` |
| Tab pill (web) | Tinggi 36, radius pill, padding 12 / 16. Terpilih: fill `primary`, teks putih 13 / 600. Tidak terpilih: fill `lav-300`, teks `text-body`. Gap 8, di tengah |
| Chip filter berikon (riwayat) | Tinggi 44, radius 12, fill `surface`, border `border-subtle`, ikon kiri 20 `primary`, label 14 / 500, `expand_more` kanan; teks terpotong dengan ellipsis |
| Input rating bintang | 5 bintang 40 dp, gap 8, tengah. Terpilih: ikon terisi `star`. Belum dipilih: garis luar `lav-400`. Ketuk: `scale 1 → 1.2 → 1` 120 ms. Label dinamis di bawah: `caption` 12 / 600 `primary`, tengah, format "{label} ({nilai}.0)" |
| Tag chip multi-pilih | Tinggi 36, radius pill, padding 12, emoji 16 + teks 14 / 600. Terpilih: fill `primary`, teks putih. Tidak terpilih: fill `lav-300`, teks `text-body`. Susun wrap, gap 8. Ketuk: toggle 150 ms |
| Pemilih tip | 4 sel sama lebar, tinggi 48, radius 12, gap 8. Tidak terpilih: fill `lav-300`, teks `h5`. Terpilih: fill `primary`, teks putih, tag "Best" `mint-300` (`micro`) di pojok kanan atas. Sel ke-4 "Lainnya" membuka input nominal. Di bawahnya baris `lav-100` radius 12 tinggi 44: label dan nominal terpotong `h4` |
| Banner reward | Fill `mint-300`, radius 16, padding 16. Tile 44 `primary` ikon bintang putih, judul `h5` `on-mint`, deskripsi `body-s`, kanan "+50 XP" `h3` `on-mint` |
| Tile unggah foto | 96 × 96, radius 12. Kosong: fill `lav-300`, ikon kamera-tambah 24 `primary`, label `caption` 2 baris tengah ("Tambah Foto +20 Poin"). Terisi: thumbnail, tombol hapus 24 dp lingkaran `ink-800` 70% + ikon `close` putih 14 di pojok kanan atas; overlay kiri bawah pill `mint-300` + ikon centang untuk bukti terlampir |
| Dropzone dokumen | Fill `lav-300`, radius 16, tinggi 160, tengah: lingkaran putih 56 + ikon kamera 24 `primary`, judul `h4`, bantuan `body-s` 2 baris. State: kosong, mengunggah (cincin progres 56 dp `primary`), terisi (diganti baris berkas), galat (border 2 px `danger`, pesan `caption` `danger`) |
| Baris berkas terunggah | Fill `lav-100`, radius 12, padding 8. Thumbnail 48 × 36 radius 8, nama berkas `h5` (ellipsis), baris bawah ikon gembok 14 + "Terhubung SSO Kampus" `caption` `primary`, tombol tonal kecil "Ganti Foto" tinggi 36 |
| Header kartu formulir | Ikon 24 `primary` + judul `h4` + badge kanan (`Wajib` `mint-300`, `Opsional` `lav-300`, `Publik` teks `caption`, `2 Grup` `lav-300`). Kartu `surface` radius 16 padding 16 |
| Label field uppercase | `micro` 11 / 700 UPPERCASE `text-muted`, di atas field. Dipakai pada form driver (NOPOL, TIPE & MERK, KEPEMILIKAN HELM) dan label blok pada e-receipt ("RINCIAN MENU MAHASISWA", "ALOKASI BIAYA TRANSPARAN") |
| Tile opsi variasi (menu) | Grid 2 kolom, tile `surface` radius 12, border `border-subtle`, padding 8, nama `caption` 12 / 600, deskripsi `caption`, harga tambahan kanan `caption` `primary`. Opsi bawaan: fill `mint-100`, border 1 px `primary-bright` |
| Tombol tambah | Tinggi 40–44, lebar penuh, radius 12, fill `lav-300`, teks `primary` 13 / 600, ikon `add` 16 kiri |
| Callout hijau | Fill `mint-100`, radius 12, padding 12, ikon centang-perisai 20 `primary`, teks `body-s` `on-mint` |
| Baris jadwal | Fill `lav-100`, radius 12, padding 12. Kiri: titik 8 dp berwarna (`primary`, `info`, `primary-glow`) + judul `h5` + subteks `caption`. Kanan: chip waktu fill `surface`, radius 8, `mono` 13 / 700 `primary` (`07.30 - 17.00 WIB`); dua rentang (Jumat) ditumpuk vertikal; status "Aktif" `caption` `primary` |
| Kartu bank | Fill `lav-300`, radius 12, padding 12. Logo bank tile 32 `surface`, nama bank `h5`, `caption` jenis rekening, tombol "Ubah" `surface` tinggi 32. Baris nomor rekening dimasker: fill `surface`, radius 12, `mono` 14 kiri (`7120-•••••-8812`), nama pemilik kanan `caption` |
| Banner toko | Foto 16:7 tinggi 150, radius atas 16. Tombol "Ubah Banner Stan (16:9)" pill `surface` 92%, tinggi 32, ikon kamera, kanan atas. Pill "Pujasera FST • Stand No. 12" `surface` 92% kiri bawah. Avatar toko 64 × 64 radius 16, border 3 `surface`, menimpa batas foto, lencana kamera 24 `primary` di pojok kanan bawah avatar. Strip identitas `lav-300`: nama `h3` + badge "Mitra Halal BEM 2025" `mint-100`, subjudul `body-s` |
| Kartu pilihan kategori (dispute) | Baris tinggi 56, radius 16. Tidak terpilih: fill `surface`, `shadow-card`, radio kosong 24 kanan. Terpilih: fill `mint-300`, ikon centang terisi `primary` 24 kanan. Kiri: tile emoji 32 (ikon dari set emoji sistem), judul `h5` 1 baris |
| Kartu opsi penyelesaian | Fill `surface`, radius 16, padding 12. Radio 20 kiri, judul `h5` + badge opsional (`mint-300`, "100% Cepat"), deskripsi `body-s` `text-muted`. Terpilih: radio terisi `primary` |
| Strip darurat | Fill `lav-300`, radius 16, padding 12. Tile ikon headset 40 `surface`, label `caption` + nama kontak `h5` (ellipsis), tombol "Panggil" `surface` tinggi 40 radius 12 ikon telepon |
| Kartu receipt | Lihat C.18. Pola: header (ID `mono`, waktu, badge), kotak rute, baris driver, daftar item, grid biaya 2 × 2, kotak total `lav-300`, callout, tiga tombol |
| Hotspot web | Label pill fill `ink-800`, teks putih `micro` 10 / 700 (`Hotspot 1: Radar Order 1-Klik`), tinggi 24, radius pill, ikon kursor 12 kiri, menempel di pojok elemen target (offset −8). Aktif/hover: ring 4 px `rgba(0,108,74,0.25)`, `scale 1.05` |
| Kartu perbandingan (web) | Dua kartu sejajar. Kiri: `surface`, border `border-subtle`, teks `text-body`. Kanan: fill `primary`, teks putih, badge "BEST VALUE SIVITAS" `mint-300` di sudut kanan atas. Baris: label `body-s` kiri, nilai `h5` kanan, jarak 12. Baris total: label `micro`, nilai `h2`, dipisah garis atas 1 px (`divider` pada kiri, `rgba(255,255,255,0.2)` pada kanan) |
| Toast aktivitas (web) | Kartu `surface`, radius 16, `shadow-float`, border `border-subtle`, lebar 336, padding 12. Avatar inisial 36 `mint-300`, eyebrow `micro` ("LIVE ACTIVITY • 2m yang lalu"), teks `caption` 12 / 700, rute `caption`, tombol tutup `close` 16 kanan atas. Posisi tetap kiri bawah, 16 dp dari tepi |


---

## C. Screen Mapping & Layout Specs

### C.0 Kerangka Global (Mobile)

| Elemen | Spesifikasi |
|---|---|
| Canvas | 360–412 dp lebar. Latar `bg`. Konten scroll vertikal; app bar dan bottom nav/CTA bar tetap |
| App bar | Tinggi 64, fill `bg`, tanpa shadow (shadow `shadow-card` muncul saat konten di-scroll). Kiri: tombol kembali 24 dp (atau tile logo "CE" 40 dp di layar tab). Tengah-kiri: judul layar `h4` 18 / 700, 1 baris. Kanan: avatar profil 40 dp (`primary`, ikon orang putih 22). Layar tab (Beranda, Radar, Dompet, Toko) memakai eyebrow `micro` di atas judul |
| Bottom nav | Tinggi 64, fill `surface`, `shadow-bar-top`, 4 item rata. Item aktif: ikon dan label `primary`, label 12 / 700. Item tidak aktif: `text-muted`, label 12 / 500. Ikon 24 dp, jarak ikon–label 4 dp. Tanpa pill indikator |
| CTA bar bawah | Tinggi 72–88, fill `surface`, `shadow-bar-top`, padding 16. Kiri (opsional): label total `micro` + angka `price-l`. Kanan atau penuh: tombol Primary 48–52 dp. Catatan kaki 12 sp `text-muted` di bawah tombol bila ada |
| Bottom sheet | Radius atas 28, fill `surface`, grabber, tinggi snap 55% / 90% layar. Header sheet: judul `h3` + tombol tutup 40 dp (lingkaran `lav-300`, ikon `close`) |
| State wajib | Skeleton, kosong (ikon 48 dp `lav-400` + teks 14 sp + aksi), galat (ikon + pesan + tombol "Coba lagi"), offline (banner 32 dp `lav-300` di bawah app bar: "Data tersimpan, menunggu koneksi") |

Pada 22 layar mobile terlihat empat susunan nav bawah yang berbeda: (A) `Beranda · Pesanan · Radar · Akun` (gambar 3, 6), (B) `Catalog · Orders · Wallet · Profile` (gambar 8), (C) `Radar · Dompet · Toko · Akun` (gambar 10, 11, 14), (D) `Orders · Products · Store · Support` (gambar 22, 23, 25, 26). Layar konsumen Order History dan Dispute Center memakai susunan D yang berlabel merchant. Lihat T-10.

Varian app bar: layar tab driver/merchant (gambar 10, 11, 14, 22, 23, 25, 26) memakai app bar "Node" (B.5); layar tab konsumen memakai tile "CE" (gambar 6) atau ikon topi (gambar 8); layar alur (Registrasi Driver, Rating) memakai app bar alur (B.5).

Nav per peran yang disarankan (lihat T-10): Konsumen `Beranda · Pesanan · Dompet · Akun`; Driver `Radar · Dompet · Riwayat · Akun`; Merchant `Pesanan · Menu · Dompet · Akun`. Layar Dispute Center dibuka dari menu Akun > Bantuan atau dari detail pesanan, bukan tab sendiri.

### C.1 Layar 1 — Onboarding & Role Selector (gambar 5)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | Eyebrow pill | Fill `mint-300`, ikon roket 16, teks `micro` "EKOSISTEM MAHASISWA TERINTEGRASI", radius pill |
| 2 | Judul | `h1` "Satu Aplikasi untuk" lalu chip Word Rotator di baris berikutnya: fill `primary`, teks putih `h2` 22 / 700, padding 8 / 16, radius 12, lebar mengikuti kata terpanjang |
| 3 | Subjudul | `body-m` `text-body`, 2 baris |
| 4 | Kartu Area Aktif | Fill `lav-300` radius 16 padding 12. Foto 56 × 56 radius 12, eyebrow "● AREA AKTIF" `micro` `primary`, nama zona `h4`; kanan: kotak putih radius 12 berisi `⚡ 28` `h3` dan "Driver" `caption` |
| 5 | Header seksi | "Pilih Peran Akun" `h4`, kanan "Bisa diganti nanti" `caption` `text-muted` |
| 6 | Kartu peran ×3 | Fill `surface`, radius 16, padding 16, tinggi bebas. Terpilih: border `border-selected` + lingkaran centang 28 dp `primary` kanan atas. Tidak terpilih: lingkaran kosong 28 dp `lav-300`. Baris badge (2 pill `mint-100`/`lav-300`), tile ikon 48, judul `h3` 20 / 700, subjudul `body-s` `primary`, deskripsi `body-m` 3 baris, chip layanan (Konsumen saja: Kantin, Nebeng, Print & Lab; tinggi 28 fill `lav-200`) |
| 7 | Info validasi | Kotak `lav-200` radius 16, tile ikon perisai 48 `mint-300`, judul `h5`, teks `body-s` |
| 8 | CTA | Primary penuh 56 dp, label dinamis "Lanjutkan sebagai {Peran} →" |
| 9 | Link masuk | Teks 14 sp `text-body` + link `text-link` 16 / 600 bergaris bawah |
| 10 | Footnote | Ikon gembok 14 + `caption` `text-muted`, tengah |

### C.2 Layar 2 — Auth (gambar 4)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | Pill "CAMPUS EXPRESS AUTH" | Fill `lav-300`, ikon perisai, `micro`, titik status `primary`, tengah |
| 2 | Foto hero | Lebar penuh dikurangi margin, tinggi 140, radius 16. Pill kiri bawah: ikon motor + "Tarif Flat Mahasiswa Rp 4.000" (fill `surface` 92%, `caption` 12 / 700) |
| 3 | Judul + deskripsi | `h1` tengah, `body-m` tengah maks. 2 baris |
| 4 | Kartu Google SSO | Kartu `surface` padding 16. Baris: tile 56 putih berisi logo Google, judul `h3` "Masuk via Google SSO", subteks `body-s`, panah kanan. Chip domain (2 chip `mint-100`). Baris info sinkron data (ikon sync 16 + `body-s`). Tombol Primary 48 "Lanjutkan SSO Kampus ⚡" |
| 5 | Pemisah | Garis `divider` kiri dan kanan + teks `caption` UPPERCASE "ATAU DENGAN NIM RESMI" |
| 6 | Kartu NIM + OTP | Field NIM (B.2) dengan chip validasi, field OTP dengan toggle mata, helper + timer, checkbox "Ingat Akun Kampus" kiri dan link "Lupa Akses Kampus?" kanan, Primary 52 "Masuk & Verifikasi Akun" |
| 7 | Kartu keamanan | Fill `lav-300`, tile ikon perisai 48, judul "Sinkronisasi PD-DIKTI Kemendikbud" `h5` + centang, teks `body-s` 4 baris |
| 8 | Footer | 3 link `caption` `text-body` dipisah titik, baris versi `caption` `text-muted` |

State: `idle`, `sso-loading`, `nim-invalid` (field border `danger`), `otp-sent` (timer jalan), `otp-expired` (tombol "Kirim ulang" aktif), `domain-rejected` (banner `danger-container`: "Gunakan akun @mhs.uin.ac.id").

### C.3 Layar 3 — Beranda Konsumen (gambar 6; gambar 3 versi awal)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | App bar tab | Tile "CE" 40 dp, eyebrow "KAMPUS UTAMA" + judul "Beranda ⌄", bell 40 dp, avatar 40 dp |
| 2 | Kartu lokasi | `surface`, radius 16, tinggi 56, padding 12. Ikon pin `primary`, judul `h5` ("Gedung Terpadu • Zona 1 ⌄"), subteks `caption`; kanan: pill status ("● KAMPUS BUKA" `mint-300`) |
| 3 | Search | B.2, tinggi 48 |
| 4 | Hero Ride Kampus | B.3 Hero layanan, tinggi ±188 |
| 5 | Grid 2 kolom | Kartu Jastip Kantin (badge "Bebas Antre"), Express Doc & Lab (badge "Prioritas Kilat"), masing-masing 171 × 170 |
| 6 | Wadah statistik | "Lalu Lintas Koridor Hari Ini" + badge "Live Sinkron"; sel: Driver Aktif (angka `primary`), Trip Sukses (`info`), Rata-rata Tiba (`info`, satuan `mnt`) |
| 7 | Rail Kantin Favorit | Header `h3` + link "Lihat Semua" + subjudul; kartu menu rail ×N |
| 8 | Live Ping | B.4, 1 kartu |
| 9 | Bottom nav | C.0 |

Gambar 3 menambahkan: banner Katalog UMKM (kartu tonal), kartu promo MABAEXPRESS (kartu `grad-wallet` dengan kode salin dalam wadah `rgba(255,255,255,0.14)` radius 12, tombol "Klaim Promo" `mint-300`), dan ticker teks di bawah kartu lokasi. Ticker pada gambar 3 terpotong di bawah kartu (T-14); bila dipertahankan, beri tinggi tetap 24 dp dan jarak 8 dp dari kartu lokasi.

### C.4 Layar 4 — Landmark & Zone Picker (gambar 7)

Bottom sheet 90% di atas layar "Booking Detail".

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | Header sheet | Judul `h3` "Pilih Titik Jemput / Tujuan Kampus" (2 baris), deskripsi `body-s`, tombol tutup |
| 2 | Search | Fill `lav-200`, tinggi 48, radius 16 |
| 3 | Filter zona | Chip scroll: Semua Zona, Fakultas & Lab, Gerbang & Halte, Area Kost, ... |
| 4 | Kartu rute | Fill `lav-300` radius 16 padding 16. Dua baris titik: ikon lingkaran (jemput) dan pin (tujuan) dihubungkan garis vertikal 2 dp; eyebrow `micro` ("TITIK JEMPUT", "TUJUAN DITUJU"), nama `h4`, pill "Asal" `mint-100` / "Tujuan" `primary` teks putih. Baris metrik 2 sel putih radius 12 (Estimasi Rute `0.8 km • ~4 mnt`; Tarif `Rp 4.000`). Baris ketersediaan driver di kotak `mint-100` ("● 12 Driver Mahasiswa standby di Gate 1") + chip "Cepat Datang" |
| 5 | Grup daftar | Header grup: ikon 20 + `h4` + hitungan "N Lokasi" `caption` kanan. Baris lokasi: tinggi 72, tile ikon 40, judul `h5` 1 baris, subteks `caption`, baris "Drop Point: ..." `caption` `primary`, chip zona kanan atas, chevron. Baris terpilih: fill `mint-100` + lingkaran centang 28 `primary`. Gap antar baris 8 |
| 6 | CTA bar | Primary 52 "Konfirmasi Lokasi Ini (Rp 4.000 Flat) →", catatan kaki 12 sp tengah |

Chip zona pada baris tidak boleh menimpa subteks; beri lebar maksimal 72 dp dan potong dengan ellipsis (T-14).

### C.5 Layar 5 — Katalog (gambar 8)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | App bar tab | Tile ikon topi 40 `primary`, eyebrow "CAMPUS EXPRESS", judul "Campus Catalog", search 40, avatar 40 |
| 2 | Baris search + sort | Search 1 bagian fleksibel dengan ikon mic, Sort 120 dp |
| 3 | Filter kategori | Chip 36 dp: Semua (42) terpilih, Kantin & Makanan Berat, Minuman, ... |
| 4 | Filter cepat | Chip 32 dp bergaris: `⭐ 4.8+`, `< 15 Menit`, `Promo UKT`, `Bebas Antre` |
| 5 | Banner mutu | Fill `primary` radius 20 padding 16; pill eyebrow, judul `h3` putih (2 baris), deskripsi 3 baris, kotak bawah `rgba(255,255,255,0.14)` radius 12 berisi 2 metrik; ikon perisai 64 dp `rgba(255,255,255,0.12)` kanan atas |
| 6 | Header daftar | "Menu Pilihan Mahasiswa" `h3` + badge "Live Stok" `lav-300` + link "Lihat Peta Kantin" |
| 7 | Kartu menu (daftar) ×N | B.3 Kartu menu (daftar) |
| 8 | Bar keranjang melayang | `ink-800`, radius 16, tinggi 64, margin 16 di atas bottom nav, `shadow-float`. Kiri: ikon tas dengan badge hitungan merah (18 dp, `danger`) , dua baris ("2 Menu Dipilih" putih 14 / 600; harga 18 / 800), tengah: nama merchant 12 sp `mint-300`, kanan: tombol `surface` 44 "Lihat Keranjang →" |
| 9 | Bottom nav | Pada mockup berlabel `Catalog · Orders · Wallet · Profile` (T-10) |

### C.6 Layar 6 — Detail Kantin & Item Customizer (gambar 15; gambar 2 varian)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | Hero foto | Tinggi 160, lebar penuh, overlay gradien bawah. Pill kiri atas "● BUKA • PADAT SIANG" (fill `surface` 92%), pill kanan atas jarak (`info`) |
| 2 | Kartu merchant | Menimpa foto 24 dp. Badge "Mitra Halal & Terverifikasi" (ikon centang), nama `h2`, deskripsi `body-s`, badge rating kanan atas (fill `mint-100`, bintang + `h4`, "420+ ulasan" `caption`) |
| 3 | Metode pengambilan | Label `micro`. Dua kartu sejajar, tinggi 88: **Driver Kampus** terpilih (fill `primary`, teks putih, badge "Flat Rp 4.000" `mint-300`), **Ambil Sendiri** (fill `lav-300`, badge "Gratis"). Terpilih/tidak ditandai fill, bukan border |
| 4 | Kartu menu terpilih | Foto 88 × 88 radius 12, badge "Menu Terlaris #1" `mint-100`, nama `h4` 2 baris, deskripsi `body-s`, harga `price` `primary` + harga coret `caption` `text-muted` |
| 5 | Grup opsi "Pilih Tingkat Kepedasan" | Header: judul `h4`, subjudul `caption`, badge "Wajib (1)" `danger-container`/`danger`. Baris radio B.2 ×3, selalu ada satu terpilih (default opsi pertama) |
| 6 | Grup opsi "Tambahan Lauk & Topping" | Badge "Opsional" `lav-300`; baris checkbox ×4; badge kecil di nama ("Renyah" `mint-100`) |
| 7 | Catatan khusus | Header + penghitung, textarea B.2; teks insentif di bawah (ikon daun 16 + `body-s` `primary`) |
| 8 | Ringkasan biaya (gambar 2) | Baris sticky di atas CTA: judul "Rincian Perhitungan Biaya" + total kanan `h4` + chevron; saat dibuka: Harga Dasar, Topping & Kepedasan, Ongkir Mahasiswa Flat (+ badge "Hemat Kampus" `mint-100`) |
| 9 | CTA bar | Stepper jumlah kiri (B.1) + Primary CTA berisi "Tambah Pesanan" + total. Total bertambah mengikuti opsi dan jumlah |

Aturan: total = `(harga dasar + Σ opsi) × jumlah + ongkir`. Pada gambar 15: 15.000 + 2.000 + 4.000 = 21.000.

### C.7 Layar 7 — Cart & Checkout (gambar 9)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | Progres | Baris judul "Ringkasan Pesanan Kampus" + pill "Step 2 dari 3" `lav-300`; progress linear tinggi 4, track `lav-300`, isi `primary` 66% |
| 2 | Kartu Titik Drop | Tile ikon pin `mint-100`, judul `h4`, link "Ubah ✎"; nama lokasi `h3` + chip "Akses Cepat" `mint-300`; eyebrow zona `micro` `primary`; kutipan catatan dalam kotak `lav-100` radius 12 dengan ikon chat; baris ETA ikon jam + "12 – 15 Menit" + chip "Waktu Istirahat Siang" `lav-300` |
| 3 | Kartu Pesanan | Header "Pesanan Dari N Kantin" + link "+ Tambah Menu". Baris item: foto 64 × 64 radius 12, nama `h5`, merchant `caption` `primary`, varian `caption`, label tambahan (ikon + `caption`, mis. "Kemasan Ramah Lingkungan"), harga kanan `h5`, link "Edit" `caption` `text-link` |
| 4 | Kotak promo | Fill `mint-100` radius 12, ikon voucher, judul `h5` `primary`, kode `h5`, ikon centang kanan |
| 5 | Rincian biaya | Header ikon struk + "Rincian Biaya Antar & Layanan" + chip kanan. Baris: label `body-m`, nilai kanan `h5`; baris diskon: teks dan nilai `primary`; ikon `help` 16 `text-muted` menjelaskan tarif. Total: kotak `lav-300` radius 12, label `h4` + teks hemat `caption` `primary`, nilai `h1`-turunan 24 / 800 `primary` |
| 6 | Metode pembayaran | 3 kartu pilihan (radio di kanan). Terpilih: border 2 px `primary` + fill `surface`; tidak: fill `lav-100`. Isi: tile ikon 44, judul `h4` + badge ("Rekomendasi" `mint-300`, "Aktif" `lav-300`), deskripsi `body-s`. Kartu QRIS menyertakan kotak `mint-100` ikon petir + teks verifikasi |
| 7 | Catatan perlindungan | Fill `lav-100`, ikon centang-perisai 20, teks `caption` 2–3 baris |
| 8 | CTA bar | Kiri: eyebrow "TOTAL TAGIHAN", `price-l`, "Hemat Rp 3.000" `caption` `primary`. Kanan: Primary 52 "Bayar & Pesan Sekarang →" dengan ikon gembok |

Perhitungan pada gambar: subtotal 25.000 + ongkir 4.000 + layanan 1.000 − diskon 3.000 = 27.000.

### C.8 Layar 8 — Live 3D Tracking & ETA (gambar 12; gambar 1 versi awal)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | App bar | Kembali, judul "Live Tracking", search, avatar |
| 2 | Area peta | Tinggi 300 dp (±38% viewport), pojok atas tanpa radius. Palet `map-*` (A.1). Pitch 60°, bearing 45°, zoom mengikuti rute (fit bounds + padding 48). Label bangunan di bawah blok |
| 3 | Overlay | Pill ETA kiri atas (B.4), tombol recenter 40 kanan atas. Label `LIVE 3D` kanan bawah (`micro` `primary-bright`) hanya pada mode 3D; pada mode 2D diganti `LIVE 2D` |
| 4 | Sheet panel | Radius atas 28, menimpa peta ±24 dp, grabber, dapat ditarik (snap 40 / 70 / 92%) |
| 5 | Header order | Eyebrow "CAMPUS EXPRESS LIVE", `h2` "Pesanan #CX-8821" (`mono` untuk ID), badge status kanan ("Sedang Diantar" `mint-300` + ikon motor) |
| 6 | Stepper | Kartu `lav-100` radius 16 padding 16, 4 simpul (B.4) |
| 7 | Kartu PIN | Kartu `surface`/`lav-100`: pill `mint-100`/`primary` "PIN Verifikasi Serah Terima" + ikon perisai, badge "Aman" + ikon gembok kanan, 4 kotak PIN, kotak instruksi `lav-300` radius 12 dengan ikon info + teks `body-m` (kata kunci "Lobi Utama Lab FST" `h5`). Teks peringatan tetap tampil |
| 8 | Kartu Driver | B.3 |
| 9 | Kartu ringkasan | B.3 Ringkasan Order, bisa diperluas (chevron) menampilkan item |
| 10 | Footer bantuan | Ikon headset + "Butuh bantuan pesanan?" kiri, link "Pusat Bantuan" kanan |

State: `waiting-driver` (peta menampilkan titik jemput + animasi radar pulse, stepper di langkah 2), `driver-moving`, `arrived` (ETA berganti "Driver sudah tiba", PIN diberi highlight border 2 px `primary`), `completed`, `map-unavailable` (placeholder `ink-800` + teks "Peta tidak tersedia", sheet tetap berfungsi).

### C.9 Layar 9 — Driver Order Radar (gambar 10)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | App bar | Tile ikon truk 40, eyebrow "MITRA CAMPUS", judul "Radar", pill Online 44, avatar |
| 2 | Kartu status | Baris: titik `primary` + "Status: AKTIF" `h4` `primary` + chip "Siap Order"; tombol toggle online kanan (outline `border-subtle`, ikon power). Baris sinkron: "Radar auto-sync: {n} dtk lalu" + ikon sinyal "Area Kampus Barat" kanan. Dua kotak statistik (Sesi Ini, Saldo Mitra) putih radius 12. Chip kategori: Semua Rute 3, Antar Makanan 2, Nebeng Kuliah 1 |
| 3 | Header daftar | Ikon navigasi + "Antrean Radar Aktif" `h3` + "N Permintaan Dekat" `caption` `primary` |
| 4 | Kartu order jastip | B.3 Kartu Order Radar + Claim 1-Click |
| 5 | Kartu nebeng | Chip "Nebeng Searah" (`lav-300`, ikon motor), jadwal kanan; rute dua titik; kotak penumpang `lav-100` (avatar inisial 40, nama + angkatan, catatan "Bawa helm sendiri" + ikon centang); baris dasar: "Tarif Bersih" `caption` + `Rp 4.000 Flat` `h2`, tombol Primary compact "Ambil Nebeng →" |
| 6 | Kartu dokumen | Chip "Dokumen Tugas" + chip "Kering & Rapi" mint; rute; "Penghasilan" + nilai; tombol Tonal "Ambil Order" dengan ikon tap |
| 7 | Tips | Kartu `lav-100`, ikon bohlam 40 `mint-100`, judul `h5`, teks `body-s` |

State: `offline` (kartu daftar diganti ilustrasi kosong + tombol "Online"), `low-balance` (banner `danger-container` di atas daftar, tombol Claim nonaktif, tombol "Top-Up"), `empty`, `claim-failed`. Kartu hilang dengan animasi 200 ms saat kedaluwarsa atau diambil driver lain.

### C.10 Layar 10 — Driver Active Job (gambar 13)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | App bar | Kembali, judul `h4` + subjudul `caption` "Pemberhentian Berikutnya", tombol "Bantuan" (fill `danger-container`, ikon asterisk/SOS `danger`, tinggi 44) |
| 2 | Kartu status | Fill `primary` radius 24 padding 16: badge "SEDANG DIANTAR" (`mint-300`), `mono` ID kanan, `h1` 28 "Antar ke Drop-off", chip "Jastip Kilat" kanan, baris "Tiba sebelum 11:58 WIB • ~4 mnt lagi" (chip `mono` fill `rgba(255,255,255,0.16)`), progress bar tinggi 6 (track `rgba(255,255,255,0.24)`, isi `mint-300`) |
| 3 | Kartu penerima | Avatar 56 dengan lencana verifikasi, nama `h4`, subteks, chip "Penerima" `lav-300`; kotak titik temu `lav-100` radius 12 (ikon navigasi, label `micro`, kutipan `body-m`); dua tombol sejajar: Primary "WhatsApp" dan Tonal "Panggil Telp" (lihat T-08) |
| 4 | Rute | Header "Rute Antar Kampus" + "180 meter lagi" kanan. Langkah selesai: fill `lav-100`, ikon centang `mint-300`, teks dicoret, subteks "Sudah diambil & bayar via QRIS". Langkah tujuan: fill `lav-300`, ikon pin `primary`, chip "TUJUAN", saran rute `body-s`. Area peta mini tinggi 120, tombol "Buka Peta" `surface` kanan bawah, label "Navigasi Aktif: Koridor FST" kiri bawah. Bila peta gagal: placeholder `ink-800` + ikon, jangan tampilkan ikon gambar rusak |
| 5 | Rincian paket | Header + chip jumlah; baris item (`1x` kotak 28 dp, nama `h5`, varian `caption` `danger` untuk tingkat pedas, harga). Kotak "STATUS PEMBAYARAN KONSUMEN" fill `mint-100`, ikon centang, teks `h5` `primary`, nominal kanan |
| 6 | Verifikasi PIN | Tile ikon 56 `mint-300`, judul `h3` tengah, teks `body-s` tengah, 4 slot input (B.2), keypad 3 × 4 |
| 7 | CTA | Primary 56 "Konfirmasi & Selesaikan Order" + chip kanan "+Rp 6.000" (`rgba(255,255,255,0.16)`); dinonaktifkan sampai 4 digit terisi. Catatan kaki `caption` |

Respons PIN: benar → layar sukses (centang 80 dp, nominal dikreditkan); salah → slot bergetar 300 ms, pesan "PIN salah, sisa {n} percobaan"; terkunci → banner `danger-container` "Terkunci 10 menit" + tombol "Hubungi Bantuan".

### C.11 Layar 11 — Driver Wallet (gambar 11)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | App bar | Seperti C.9 dengan judul "Dompet" |
| 2 | Kartu Dompet | B.3 Kartu Dompet. Dua tombol 1:1 (Top-Up QRIS mint, Tarik Saldo glass) |
| 3 | Statistik mingguan | 3 kartu putih radius 12, tinggi 88: ikon kanan atas `primary`, nilai `h2`, label `caption`; selisih "+14% vs lalu" `caption` `primary` |
| 4 | Pilih nominal | Kartu `surface`. Header ikon petir + judul `h4` + badge "Biaya Rp 0" `lav-300`. Grid 2 × 2 sel tinggi 72: tidak terpilih fill `lav-200`, terpilih fill `primary` teks putih + badge "POPULER" `mint-300` di pojok kanan atas. Label kecil `caption` ("Ringan", "Cukup 2 Hari"), nilai `h2`. Baris QRIS: tile QR 40, teks 2 baris, tombol "Bayar" `primary` tinggi 36 |
| 5 | Mutasi | Header "Mutasi Saldo Dompet" + "Terbaru" `caption`. Baris: tile ikon 48 (`mint-100` untuk masuk, `lav-300` untuk potongan), judul `h5`, subteks `caption`, nilai kanan `h5` (`primary` untuk +, `danger` untuk −), status `caption` di bawah nilai. Pemisah `divider` |
| 6 | Bottom nav | Item "Dompet" aktif |

### C.12 Layar 12 — Merchant Dashboard (gambar 14)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | Kartu toko | Foto 56, nama `h3` + centang, spesialisasi `body-s`, tombol pengaturan 40 `lav-200` |
| 2 | Kartu status toko | Fill `primary` radius 20 padding 16: titik `mint-300`, "TOKO BUKA" `h3` putih, deskripsi `body-s`, toggle kanan; kotak "Mode Sibuk Istirahat Kuliah +5 mnt estimasi otomatis" fill `rgba(255,255,255,0.14)` dengan checkbox |
| 3 | Ringkasan dapur | Header + pill sesi "Sesi Siang" `mint-300`. Kartu omzet `primary` radius 20: eyebrow `micro`, nilai `display` 36 sp, badge perubahan, baris 2 metrik (porsi terjual, non-tunai) |
| 4 | Dua kartu hitungan | Grid 2: "Perlu Respon" (tile ikon bel `danger-container`, badge `danger`, angka `display`-turunan 32 / 800), "Antrean" (tile `mint-100`, badge `lav-300`) |
| 5 | Kartu "Siap Di-pickup" | Fill `surface`, tile ikon 48, judul `h5`, subteks, tombol "Lihat ›" `lav-300` |
| 6 | Header "Pesanan Aktif Dapur" | Titik merah 8 dp (live) + "Auto-refresh • 5s" `caption` (T-16) |
| 7 | Tiket dapur | B.3 Kartu Tiket Dapur (varian baru dan varian sedang dimasak). Varian dimasak: kotak driver standby (avatar 40, "Driver Bayu Pratama" `h5`, "Sudah standby di depan loket kantin" `caption`) + tombol Tonal penuh "Tandai Siap Diambil Driver" |
| 8 | Kontrol stok | Header + link "Kelola". Baris: foto 48, nama `h5`, status stok (`Tersedia • Sisa 18 porsi` `primary`, atau `Habis (Tutup di aplikasi)` `danger`), toggle kanan. Baris habis: nama dicoret, foto grayscale 60% |

### C.13 Layar 13 — Merchant Order Dispatcher (gambar 16)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | Kartu header | `mono` ID + nama merchant `caption` UPPERCASE, badge "Siap Dispatch" `mint-300`; titik tujuan `h4` + `body-s`; kotak "Selesai Masak 3 Mnt Lalu" `lav-300` kanan |
| 2 | Rincian paket | Header ikon sendok-garpu + chip jumlah menu. Baris item fill `lav-100` radius 12: `2x` `h3` `primary`, nama `h5`, catatan `caption` `primary`, harga kanan `h5`. Dua kotak kecil `lav-100`: segel higienis, total + status pembayaran |
| 3 | Metode dispatch | Header "Pilih Metode Dispatch" + `caption` kanan. Dua kartu pilihan: terpilih (border 2 px `primary`, centang 28 kanan atas, badge "Rekomendasi" `mint-300`, tile ikon radar 56 `primary`, judul `h4`, deskripsi 2 baris, kotak 3 metrik `lav-100`), tidak terpilih (fill `surface`, radio kosong, tile `lav-200`) |
| 4 | Opsi siaran | Kartu `surface`: baris radius (ikon sinyal, "Aktif" `primary`), baris tip dengan toggle dan badge "Jam Padat" |
| 5 | Mitra standby | Header + "Terdekat: 50m" `primary`. Dua kartu avatar sejajar, nama `h5`, fakultas + jarak `caption` |
| 6 | CTA bar | Primary 56 "Siarkan ke Driver Kampus (Radar ⚡)" dan di bawahnya Tonal 48 "Cetak Struk Dapur / Thermal", gap 8 |

### C.14 Layar 14 — Profil & Ulasan (gambar 17)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | Kartu identitas | Avatar 72, nama `h2`, NIM `mono` 12 (dimasker, lihat T-13), chip "SSO Dikti Terverifikasi" `mint-100`, baris "● Akun Konsumen & Driver Aktif" `caption` `primary`, tombol "Edit Profil" `lav-300` 36 dan tombol pengaturan 36 |
| 2 | Statistik | 3 kartu putih tinggi 88: ikon 24 kiri atas, nilai `h2`, label `caption` (Total Trip, rating + jumlah ulasan, Poin Hemat) |
| 3 | Identitas & Saldo | Header ikon + judul + badge "Aktif Semester Ganjil" `lav-300`; 3 baris (B.3 Kartu Profil Identitas) |
| 4 | Ulasan | Header "Ulasan Mahasiswa & Kantin" + tombol "Shuffle" (`lav-300`, ikon acak, tinggi 36). Chip filter (Semua 98, Bintang 5 94, Driver, Konsumen). Kartu ulasan: avatar inisial 40, nama `h5` + badge peran `mint-100`, angkatan `caption`, 5 bintang kanan atas (terisi `star`, 16 dp), teks ulasan `body-l` maks. 5 baris, baris dasar: ikon toko + sumber `caption` `primary` kiri, waktu kanan. Indikator halaman 4 titik (aktif: pill 20 × 6 `primary`; lain: 6 × 6 `lav-400`) |
| 5 | Lencana | Header + `caption` "3 Lencana Terbuka". 3 kartu `lav-300` radius 16 tinggi 140: lingkaran ikon 48 `mint-100`, nama `h5`, syarat `caption` |
| 6 | Daftar pengaturan | Kartu `surface`, 3 baris tinggi 64 dipisah `divider`: tile ikon 40 `lav-200`, judul `h5`, subteks `caption`, chevron. Baris "Keluar Dari Akun": tile `danger-container`, judul `danger` |

### C.15 Layar 15 — Admin Master Control Panel (gambar 18, 19)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | Pill identitas | "ADMIN: BIRO LOGISTIK BEM" `lav-300` kiri, indikator latensi `caption` kanan |
| 2 | Kartu status operasional | `surface`, tile ikon power 48 `mint-300`, judul `h4`, subteks `primary`, toggle. Mengubah toggle meminta konfirmasi dialog (kill switch) |
| 3 | Grid 2 × 2 | Driver online (badge "Live"), Kios standby (badge "Pujasera"), Volume transaksi, Kas BEM & Subsidi UKT (fill `primary`, badge "5% Bagian" `mint-300`). Angka `h1` 26 / 800 |
| 4 | Antrean verifikasi | Header + badge "3 Menunggu" `danger-container`, link "Lihat Arsip". Kartu pengajuan: foto 56 radius 12, nama `h4`, angkatan chip, NIM `caption`, status verifikasi; baris dokumen 2 sel `lav-100` (SIM, kendaraan); tombol Tonal "Tolak" dan Primary "Setujui & Aktifkan" (1:1,5) |
| 5 | Matriks tarif | Header + tombol filter 40. Kartu per zona: titik zona berwarna + nama `h4` + link "Ubah ✎", deskripsi `caption`, dua sel `lav-100` (Tarif Mahasiswa, Subsidi Kas) |
| 6 | Broadcast | Kartu `surface`, tile ikon 48 `danger-container`, judul + deskripsi, kotak pratinjau pesan `lav-100`, baris bawah: ikon + "Target: 1.420 Mahasiswa Aktif", Primary "Siarkan Sekarang" 56. Siaran meminta dialog konfirmasi |

Mockup ini ditampilkan sebagai layar mobile; `PRD.md` §4 M19 dan `tech.md` menempatkan Admin di web (T-12).

### C.16 Layar 16 — In-App Live Chat (gambar 20)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | App bar | Kembali, "In App Live Chat" `h4` + chip "CX" `lav-300`, avatar |
| 2 | Kartu konteks | `surface` radius 16 padding 12, sticky di atas daftar. Baris 1: tile 44 `mint-100`, `mono` ID + ringkasan item 1 baris, chip "WA Darurat" `mint-100` (lihat T-08). Baris 2: kotak `lav-100` radius 12: avatar driver 48 + titik online, nama `h4` + chip angkatan, kendaraan `body-s`, chip ETA "● ETA 3 mnt" `mint-100` |
| 3 | Daftar pesan | Latar `bg`, padding 16, urut lama ke baru, auto-scroll ke bawah. Pemisah tanggal, bubble (B.4), chip peristiwa sistem. Jarak antar bubble 8 dp (pengirim sama), 16 dp (berganti pengirim) |
| 4 | Quick replies | Rail horizontal di atas input: `👋 Saya sudah di lobi`, `📍 Sesuai titik di peta`, `⏳ Tunggu...` |
| 5 | Composer | Kartu `surface` radius 24, `shadow-float`, margin 16. Tombol kamera 48 (`lav-300`, radius 14), field teks fill `lav-200` radius 16 dengan ikon emoji kanan, tombol kirim 48 `primary` radius 16 |

State: `readonly` (composer diganti banner `lav-300` "Chat ditutup 24 jam setelah pesanan selesai"), `rate-limited` (tombol kirim nonaktif 60 dtk + helper), `image-uploading` (bubble placeholder dengan progress), `failed` (ikon `error` `danger` + "Kirim ulang"), `blocked` (composer nonaktif).

### C.17 Layar 17 — UMKM Menu Management & Add/Edit Product (gambar 22)

Nav aktif: `Products`. Gambar berlebar 285 px, sehingga dimensi bersifat relatif.

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | App bar "Node" | B.5, judul pada mockup "Umkm Menu Management" (2 baris). Gunakan "Kelola Menu" |
| 2 | Strip merchant | Fill `lav-300`, radius 16, padding 12. Tile toko 40 `mint-100`, nama `h5` (ellipsis) + pill "Stan #12 FST" `mint-300`, subteks `caption`. Kanan: chip mode ("● Mode Tambah" / "Mode Edit") `lav-200` |
| 3 | Kartu Foto Utama | Header (ikon kamera, "Foto Utama Menu", badge "Wajib" `mint-300`). Pratinjau 1:1 lebar 160 dp, tengah, radius 12, overlay kiri bawah "Pratinjau Aplikasi / Rasio 1:1 Siap Tampil" (`caption` putih). Tombol Primary compact 40 "Pilih Foto Menu" + ikon kamera. Baris bawah: ikon sparkle 14 + "Otomatis Kompresi Kampus WebP" `caption` `primary`; "Rekomendasi rasio 1:1" `caption` |
| 4 | Kartu Informasi & Detail | Field **Nama Menu** (counter "Maks. 50 Karakter" di label, ikon centang `primary` di dalam field saat valid). **Kategori Menu Kantin**: chip pilih satu (Makanan Berat, Minuman, Snack / Gorengan, Paket Hemat UKT), terpilih fill `primary` teks putih, wrap 2 baris. **Deskripsi**: textarea 4 baris, counter "86 / 200 Karakter". **Harga Mahasiswa (Rp)**: field berawalan `Rp`, nilai berformat `id-ID`, label kanan "Bebas Potongan Komisi" `caption` `primary`. Callout hijau (komisi stan 0%). **Status Ketersediaan**: kartu `lav-300` radius 12 padding 12, judul `h5` + `caption`, toggle kanan; baris **Kuota Masak Harian**: label kiri 2 baris, field angka lebar 96 fill `surface` ("50 Porsi") kanan |
| 5 | Kartu Variasi & Kustomisasi Rasa | Header + badge "2 Grup" `lav-300`. Grup 1 (kartu `lav-100`, radius 16, padding 12): ikon api `danger` + "Tingkat Kepedasan" `h5` + badge "Wajib Pilih 1" `danger-container`; deskripsi `caption`; grid 2 × 2 tile opsi (B.5), opsi bawaan "Level 1 (Standar)"; tombol tambah "+ Tambah Opsi Level Cabe". Grup 2: ikon tambah + "Tambahan Topping / Lauk" + badge "Bisa Pilih Banyak"; baris checkbox card ×3 (centang, nama `h5`, keterangan `caption`, harga kanan `caption` `primary`); tombol tambah "+ Tambah Grup Variasi Baru" |
| 6 | Callout kebijakan | Fill `lav-300`, ikon centang-perisai 24, judul `h5` "Kebijakan Menu Halal & Higienis UKM Kampus", teks `body-s`. Jam operasional diisi dari Pengaturan Toko |
| 7 | CTA bar ganda | Tonal "Simpan Draf" (1 bagian, ikon simpan) + Primary "Terbitkan Menu" (2 bagian, ikon centang-lingkaran), tinggi 48, gap 8, di atas bottom nav |

Aturan formulir: nama 2–50 karakter; deskripsi ≤ 200; harga 500–500.000 dan kelipatan 100; kuota harian 1–999; maks. 6 grup dan 12 opsi per grup; foto wajib untuk menerbitkan; satu opsi bawaan per grup wajib. Foto dikompres di klien ke WebP ≤ 80 KB sebelum diunggah (label "Maks 2MB" pada mockup adalah batas file sumber).

Data contoh pada mockup (gambar 22), untuk seed dan uji UI:

| Elemen | Isi pada mockup |
|---|---|
| Nama menu | `Ayam Geprek Sambal Matah Spesial` (centang valid) |
| Deskripsi | "Ayam paha/dada renyah dengan sambal matah serai segar khas Bali dan lalapan segar timun." (86 / 200) |
| Harga | `Rp 16.000`; callout "Bebas potongan komisi stan (0% Subsidi Mitra BEM Kampus)" |
| Kuota | `50 Porsi` |
| Opsi Tingkat Kepedasan (2 × 2) | Level 0 "Tidak Pedas" `Rp 0`; Level 1 (Standar) "Sedang" `Rp 0` (bawaan, fill `mint-100`); Level 3 "Nampol" `+Rp 1.000`; Level 5 "Pedas Mampus" `+Rp 2.000` |
| Opsi Topping / Lauk | Telur Cepok Balado / Mata Sapi (centang) `+Rp 3.500`; Kol Goreng Crispy (centang) `+Rp 2.000`; Ekstra Sambal Matah 1 Cup, porsi 30 gram (tidak dicentang) `+Rp 1.500` |
| Foto | Pratinjau 1:1 dengan keterangan "Pratinjau Aplikasi / Rasio 1:1 Siap Tampil"; bantuan "Maks 2MB, WebP/JPG" |
| Catatan kaki kebijakan | "Menu yang diterbitkan akan langsung tampil di etalase Mahasiswa pada jam operasional Kantin FST (07:30 - 17:00 WIB)" |

Catatan: nama kategori yang terpilih adalah "Makanan Berat". Harga opsi dibatasi satu baris; pada mockup `+Rp 2.000` dan `+Rp 3.500` membungkus (T-14 l), sehingga lebar kolom harga minimal 72 dp.

State: `mode-tambah`, `mode-edit` (CTA "Simpan Perubahan"), `draft`, `published`, `validasi-gagal` (field border 2 px `danger`, pesan di bawah), `mengunggah-foto`, `batas-150-produk`, `offline` (tombol terbitkan nonaktif).

### C.18 Layar 18 — Order History & E-Receipt (gambar 23)

Nav aktif: `Orders`.

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | App bar "Node" | B.5 |
| 2 | Tab status | Semua, Berjalan (1), Selesai (14) terpilih, Batal (0). Hitungan 0 tidak diberi badge |
| 3 | Baris filter | Dua chip filter berikon: bulan ("November 2024 ⌄") dan layanan ("Semua Layanan (Jastip & Nebeng) ⌄"); baris scroll horizontal, tinggi 44 |
| 4 | Header seksi | Titik `primary` 8 + "E-Receipt Terkini" `h3`; kanan "PIN TERVERIFIKASI" `micro` `text-muted` |
| 5 | Kartu receipt | Kartu `surface` radius 16 `shadow-card` padding 16. **Header**: `mono` 16 / 700 ID + ikon salin 18, waktu `body-s`; badge kanan "Selesai & PIN Valid" `mint-300` dengan ikon centang-perisai. **Kotak rute** (`lav-200`, radius 12, padding 12): tile 40 `lav-300` (ikon toko) dan tile 40 `mint-300` (ikon pin) dihubungkan garis vertikal 2 dp; eyebrow `caption` ("Titik Penjemputan", "Tujuan Pengantaran"), nama `h4`. **Baris driver** (`lav-100`, radius 12, padding 8): avatar 48, nama `h5`, `caption`, chip rating kanan (`surface`, radius 8, bintang + "5.0" `h5`). **RINCIAN MENU MAHASISWA** (`micro`): kotak `lav-100` radius 12; baris `1x {nama}` `h5`, varian `caption`, harga kanan `h5`, pemisah `divider`. **ALOKASI BIAYA TRANSPARAN** (`micro`): grid 2 × 2 sel `lav-100` radius 12 padding 12 (Subtotal Menu, Ongkir Flat + chip "Zona 1" `mint-300`, biaya BEM, Voucher; sel voucher fill `mint-100` teks `primary`). **Total**: kotak `lav-300` radius 16 padding 16, "Total Bayar (Lunas)" `caption`, nominal 28 / 800 `primary`, chip metode kanan (`surface`, radius 12, tinggi 40, ikon QR). **Callout** mint (ikon tunas) penjelasan alokasi iuran. **Tombol**: Primary 48 "Unduh E-Receipt Resmi (PDF)" + ikon unduh; baris 2 tombol 48: Tonal "Beri Ulasan" dan Mint "Pesan Lagi" |
| 6 | Header "Riwayat Pesanan Lainnya" | `h3` + link "Lihat Semua" |
| 7 | Baris riwayat | Kartu `surface` radius 16 padding 12. Tile ikon 56 (Nebeng `info-100`, Print `lav-300`), judul `h4` 1 baris, `mono` ID + waktu `caption`, kanan harga `h4` + status `caption` `primary` |

Hitungan pada gambar: 25.000 + 4.000 + 1.000 − 3.000 = 27.000; daftar item 17.000 + 8.000 = 25.000.

State: kosong per tab (ilustrasi + tombol "Pesan Sekarang"), `berjalan` (kartu dengan status live, ketuk membuka layar 8), receipt dari order berstatus `DISPUTED` (badge `danger-container`, tombol "Lihat Kasus"), paginasi 20, pembuatan PDF (indikator di tombol), gagal unduh.

### C.19 Layar 19 — Post-Order Rating & Review (gambar 24)

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | App bar alur | Kembali, "Post Order Rating" (gunakan "Beri Penilaian"), chip "CX", avatar |
| 2 | Kartu header | `surface` radius 16 padding 16, gradien dekoratif `radial-gradient(circle at top right, #CFF8E8, transparent 60%)`. Pill `mint-300` "✓ Pesanan Telah Tiba di Lobi FST 🎉"; baris `mono` ID + "Kantin Bu Siti & Driver Bayu" `caption`; judul `h2`; deskripsi `body-m` |
| 3 | Kartu penilaian Driver | Avatar 48, nama `h4`, `caption`, badge "Mitra Aktif" `mint-300`. "Beri Nilai Mitra Driver Kampus" `h5` tengah. Input rating (B.5), label dinamis. "Apresiasi Driver (Bisa pilih lebih dari satu):" `caption` 600 + tag chip (Pengantaran Cepat, Driver Ramah, Bawa Helm Bersih, Titik Temu Tepat, Makanan Aman) |
| 4 | Kartu penilaian Merchant | Foto 48 radius 12, nama `h4`, `caption`, badge "UMKM Juara" `mint-300`. "Beri Nilai Makanan & Stan Kantin" `h5`. Input rating, label dinamis. "Kesan Rasa & Porsi:" + tag chip (Sambal Nampol, Masih Panas, Kemasan Rapi & Higienis, Porsi Kenyang) |
| 5 | Kartu Ulasan | Header "Ulasan Mahasiswa" `h4` + badge "+20 Poin Foto" `mint-300`. Textarea `lav-200` radius 12 tinggi 3 baris, counter "72 / 300 Karakter" kanan bawah. Baris foto: tile tambah 96 (B.5) + thumbnail terlampir 96 + teks kanan ("Foto Makanan Terlampir" `h5`, penjelasan `caption`) |
| 6 | Kartu Tip | Header ikon tangan-hati + "Tip Driver Mahasiswa" `h4` + "Opsional" `caption` kanan; teks `body-s`; pemilih tip (Rp 1.000, Rp 2.000 "Best", Rp 5.000, Lainnya); baris "Saldo CXPay Terpotong: Rp 2.000" |
| 7 | Banner reward | B.5: "Klaim Total +50 Poin Hemat", deskripsi, "+50 XP" |
| 8 | CTA | Primary 56 "Kirim Penilaian & Klaim +50 Poin" + ikon kirim; catatan kaki `caption` + ikon perisai ("Ulasanmu akan tampil di profil publik driver & kantin") |

Label dinamis rating: 5 bintang driver = "Luar Biasa Cepat!", 5 bintang merchant = "Rasa Mantap & Nagih!" (terlihat pada gambar). Label untuk 1–4 bintang tidak terlihat dan perlu ditentukan (usulan: 1 "Perlu Perbaikan", 2 "Kurang", 3 "Cukup", 4 "Bagus").

Catatan pemilih tip (gambar 24): sel terpilih "Rp 2.000" memuat tag "Best" `mint-300` di pojok kanan atas dan satu baris teks kedua "Rekomendasi" (`micro`, putih) di bawah nominal, sehingga tinggi sel terpilih lebih besar dari sel lain (±56 dp berbanding 48 dp). Pakai tinggi sama (56 dp) untuk keempat sel agar baris tidak bergeser saat pilihan berpindah. Teks di bawah pemilih: "100% tip langsung masuk saldo e-wallet Bayu untuk biaya bensin & operasional kuliah." (lihat T-27).

State: awal (0 bintang, label "Ketuk bintang untuk menilai", CTA nonaktif sampai driver dan merchant dinilai), terisi, mengunggah foto, mengirim, `terkirim` (layar terima kasih), `sudah-dinilai` (readonly, tombol "Ubah" 24 jam), `gagal-kirim`.

### C.20 Layar 20 — Driver Registration & Document Upload (gambar 21)

Tanpa bottom nav (alur).

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | App bar alur | Kembali, "Driver Registration" (gunakan "Pendaftaran Driver"), chip "CX", avatar |
| 2 | Header langkah | Eyebrow "DRIVER ONBOARDING" `micro` `primary` + pill "Step 2 / 3" `mint-300` kanan; `h1` "Pendaftaran Driver Kampus"; deskripsi `body-m`; progress linear tinggi 6 (track `lav-300`, isi `primary` 66%); baris "Langkah 2 dari 3: Unggah Berkas Mahasiswa" `caption` 700 kiri, "66%" kanan |
| 3 | Kartu identitas | Fill `lav-300`, radius 16, padding 16. Tile 48 `lav-400` ikon perisai-centang; chip `mint-300` "Khusus Mahasiswa Aktif UIN / Kampus Terdaftar" `micro`; nama `h4`; baris NIM (dimasker) • fakultas • "● Aktif PD-DIKTI" `primary` |
| 4 | Header "Kelengkapan Dokumen" | `h3` + "Format: JPG, PNG (Maks 5MB)" `caption` kanan |
| 5 | Kartu KTM | Header (ikon kartu, "Kartu Tanda Mahasiswa (KTM)" 2 baris, badge "Terverifikasi" `mint-300` + ikon centang). Baris berkas terunggah (B.5) |
| 6 | Kartu SIM C | Header + badge "Wajib • Jelas" `lav-300`. Dropzone dokumen (B.5): "Ambil atau Unggah SIM C", "Pastikan nomor SIM dan masa berlaku terbaca terang tanpa pantulan cahaya" |
| 7 | Kartu STNK | Header + badge "Pajak Hidup" `mint-300`. Baris unggah ringkas: fill `lav-300`, radius 12, padding 12; tile 40 `surface` ikon unggah; "Unggah Lembar Pajak STNK" `h5`; "Sesuai plat nomor motor operasional" `caption`; ikon `add_circle` 28 kanan |
| 8 | Kartu Detail Motor | Header ikon motor + "Detail Motor & Identitas Kendaraan". Label uppercase (B.5). Field **Nomor Plat** (ikon plat, nilai 16 / 600). Field **Tipe & Merk Motor** (ikon motor). **Kepemilikan Helm Penumpang (Nebeng)**: kartu radio terpilih fill `lav-300` radius 12 ("Ya, Selalu Tersedia" `h5`, "Standar SNI bersih & siap pakai" `caption`, ikon helm kiri, radio kanan) |
| 9 | Kartu Pakta Integritas | Fill `lav-300`, radius 16, padding 16. Header ikon tanda tangan + "Pakta Integritas Mahasiswa" `h4`; pengantar `body-s`; 3 baris checkbox (kotak 20, teks `body-s`; frasa kunci `20 km/jam` dan `5% per trip` ditebalkan 600 `primary`) |
| 10 | CTA | Primary 56 "Kirim Dokumen untuk Verifikasi BEM →"; catatan kaki `caption` + ikon gembok ("Data dienkripsi dan hanya diverifikasi oleh Biro Logistik BEM") |

State: langkah 1 dan 3 belum ada mockup (F.1). Dokumen: kosong, mengunggah, terisi, galat (buram/terlalu besar), ditolak (border `danger` + alasan admin). CTA nonaktif sampai KTM, SIM, STNK, plat, tipe motor, dan semua persetujuan lengkap. Setelah kirim: status `Menunggu verifikasi`, `Disetujui`, `Ditolak + alasan + tombol "Perbaiki Berkas"`.

### C.21 Layar 21 — UMKM Store Settings & Payout Profile (gambar 26)

Nav aktif: `Store`. Gambar berlebar 366 px (skala 0,94).

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | App bar "Node" | B.5, judul pada mockup "Umkm Store Settings" (gunakan "Pengaturan Toko") |
| 2 | Banner toko | B.5: foto, tombol ubah banner (16:9), pill lokasi, avatar 64 dengan lencana kamera, strip identitas |
| 3 | Kartu Informasi & Profil Operasional | Header + "Publik" `caption` kanan. **Nama Stan Resmi \*** (field berikon toko). **Deskripsi Singkat Stan** (textarea, counter "82 / 120 karakter"). **Lokasi Penjemputan Pesanan (Driver Jastip) \*** (field berikon navigasi, chip "📍 Titik Akurat" `mint-100` di label kanan), bantuan `caption` di bawah: "Driver kampus akan membaca instruksi ini saat tiba di area pujasera" |
| 4 | Kartu Jadwal Buka Otomatis | Header ikon jam + judul + badge "Akademik V2" `mint-300`. Kartu toggle: fill `lav-300`, radius 12, tile 40 `primary` ikon topi, "Ikuti Jam Operasional Kampus" `h5`, "Senin - Sabtu (Menyesuaikan Kalender BEM)" `caption`, toggle kanan. Baris jadwal ×3 (B.5): Senin–Kamis 07.30–17.00 (Reguler Perkuliahan), Jumat 07.30–11.00 dan 13.00–17.00 (Jeda Sholat Jumat), Sabtu 08.00–15.00 (Sesi Praktikum). Baris toggle "Otomatis Buka Saat Kuliah Dimulai" + `caption` "Stan aktif sinkron presensi kelas" |
| 5 | Kartu Pencairan Harian | Header + "Tiap 18.00 WIB" `caption` `primary`. Callout mint: ikon sinkron, "Auto-Withdrawal Harian Otomatis" `h5`, teks `body-s`. Kartu bank (B.5): BSI, "Rekening Operasional Stan", tombol Ubah, nomor dimasker, a/n. Baris QRIS: tile QR 40, "QRIS Dinamis Merchant ✓" `h5`, "NMID: …" `mono` `caption`, badge "Aktif" `mint-300` |
| 6 | Kartu Preferensi Layanan | Dua baris checkbox card (fill `lav-300`, radius 12, padding 12): "Pesanan Driver Kampus (Jastip)" dan "Ambil Sendiri (Pick-up Express)", tile ikon 40 `primary`, judul `h5`, `caption`, checkbox kanan. Minimal satu harus aktif |
| 7 | CTA | Primary 52 "Simpan Perubahan Stan" + ikon simpan; catatan kaki `caption` "Perubahan langsung aktif di katalog mahasiswa." |

State: `tersimpan`, `perubahan-belum-disimpan` (CTA aktif, dialog konfirmasi saat keluar), `validasi-gagal`, `toko-ditutup-admin` (banner `danger-container`, semua toggle jadwal nonaktif), `verifikasi-rekening` (setelah ubah rekening: badge "Menunggu verifikasi" 24 jam).

Data contoh pada mockup (gambar 26), untuk seed dan uji UI:

| Elemen | Isi pada mockup |
|---|---|
| Strip identitas | "Kantin Bu Siti" + badge "Mitra Halal BEM 2025"; subjudul "Spesialis Kuliner Pedas Cepat Saji FST"; pill lokasi "Pujasera FST • Stand No. 12" |
| Nama Stan Resmi | `Kantin Bu Siti - Spesialis Geprek & Soto` |
| Deskripsi | "Menyediakan aneka olahan ayam geprek fresh ulek dadakan dan soto kuah bening sejak 2018." (82 / 120 karakter) |
| Lokasi Penjemputan | `Etalase Stand 12, samping tangga barat FST`, chip "Titik Akurat" |
| Jadwal | Senin–Kamis 07.30 - 17.00 WIB "Reguler Perkuliahan" (Aktif, titik `primary`); Jumat 07.30 - 11.00 dan 13.00 - 17.00 "Jeda Sholat Jumat" (titik `info`); Sabtu 08.00 - 15.00 WIB "Sesi Praktikum" (titik `primary-glow`) |
| Pencairan | "Penjualan cair ke rekening utama setiap jam 18.00 WIB (Bebas Biaya Admin Bank)" |
| Rekening | Bank Syariah Indonesia (BSI), "Rekening Operasional Stan", `7120-•••••-8812`, a/n Siti Aminah |
| QRIS | "QRIS Dinamis Merchant" dengan centang verifikasi, `NMID: ID1020039102931`, badge "Aktif" |
| Preferensi layanan | "Pesanan Driver Kampus (Jastip)", "Rider mahasiswa mengantar langsung ke ruang kelas"; "Ambil Sendiri (Pick-up Express)", "Pembeli mengambil mandiri di etalase stand"; keduanya dicentang |

Catatan: teks "mengantar langsung ke ruang kelas" bertentangan dengan alur serah terima di lobi/dropzone dengan PIN (T-34). Jam Jumat dan Sabtu pada tabel di atas adalah dua rentang per hari; skema `schedule` satu rentang tidak cukup (T-29).

### C.22 Layar 22 — Dispute Center & Safety Help Desk (gambar 25)

Nav aktif: `Support`.

| Urutan | Blok | Spesifikasi |
|---|---|---|
| 1 | App bar "Node" | B.5 |
| 2 | Banner bantuan | Fill gradien `linear-gradient(135deg, #CFF8E8, #F8F9FF)`, radius 16, padding 16. Tile 48 `primary` ikon perisai putih, judul `h4` "Pusat Bantuan & Komplain Kampus", deskripsi `body-s`, chip "Waktu respon rata-rata: < 15 Menit" `mint-300` (ikon jam) |
| 3 | Pilih pesanan | Label `micro` "PESANAN BERMASALAH". Kartu `surface` radius 16 padding 12: tile 48 `mint-100` ikon garpu-sendok, "#CX-8821 ● Kantin Bu Siti" (`mono` + `h5`), `caption` waktu dan total, tombol dropdown 40 `lav-300` |
| 4 | Kategori kendala | Label `micro` + "Pilih salah satu" `caption` `primary` kanan. Lima kartu pilihan (B.5): Makanan Tumpah / Rusak di Perjalanan, Driver Tidak Sesuai Titik / No Show, Item Pesanan Kurang / Tertukar, Kendala Pembayaran / QRIS Ganda, Pelanggaran Etika Berkendara di Kampus. Gap 8 |
| 5 | Kronologi | Label `micro` "CERITAKAN KRONOLOGI SINGKAT". Textarea `surface` radius 16, tinggi 4 baris, counter "98/300 karakter" kanan bawah |
| 6 | Bukti foto | Label `micro` + badge "Wajib" `danger-container`. Dua sel sejajar tinggi 200: thumbnail dengan tombol hapus dan pill `mint-300` "Bukti 1 Terlampir"; tile tambah (`surface`, border putus-putus 1.5 px `lav-400`, ikon kamera-tambah, "Tambah Bukti / Tangkapan Layar" `caption` 700 tengah) |
| 7 | Opsi penyelesaian | Label `micro` "OPSI PENYELESAIAN DIINGINKAN". 3 kartu opsi (B.5): "Klaim Garansi Saldo KampusPay" (badge "100% Cepat"), "Kirim Ulang Menu oleh Driver Lain", "Peringatan Etika & Mediasi BEM" |
| 8 | Strip darurat | B.5: "Butuh penanganan darurat lobi?" + kontak Posko + tombol "Panggil" |
| 9 | CTA | Primary 56 "Kirim Laporan ke Admin Kampus" + ikon perisai; catatan kaki `caption` + ikon gembok ("Dana pesanan ditahan sementara hingga investigasi selesai") |

State: pilih pesanan kosong (hanya pesanan ≤ 24 jam setelah `ARRIVED`/`COMPLETED`), validasi (bukti wajib, kronologi ≥ 20 karakter), terkirim (layar "Laporan #D-xxxx diterima" + status), daftar kasus (Terbuka / Diproses / Selesai) dengan timeline, `kasus-ditolak`, `sudah-ada-kasus` (tombol diganti "Lihat Kasus"). Opsi penyelesaian adalah permintaan pelapor, putusan tetap oleh admin.

### C.23 Web Landing Page (gambar 27)

Asumsi viewport 1280 px, kontainer 1248 px (padding 16). Latar halaman `bg`. Jarak vertikal antar seksi 32–56 px (estimasi).

| Seksi | Layout | Spesifikasi |
|---|---|---|
| Navbar | Sticky, tinggi 64, fill `surface`, border bawah `divider`; `shadow-card` setelah scroll | Kiri: tile logo 32 `primary` ikon petir putih + "Campus Express" `h4` + badge "GO-CAMPUS" `mint-300`. Tengah: 5 link `body-s` 13 / 500 (Fitur Utama, Mitra UMKM, Driver Kampus, Simulasi Komisi, Cara Kerja). Kanan: Primary 40 "Download APK / Web App" (ikon unduh) + avatar 36 `primary` (login) |
| Hero | Satu kolom, tengah, tanpa gambar ponsel. Padding atas 32 | Pill referral `mint-300` (ikon petir): "Program Referral Kampus: Ajak 3 Teman Kuliah, Dapatkan Bebas Ongkir 100%!". `web-h1` "Satu Aplikasi Terpadu untuk" lalu chip Word Rotator di baris berikutnya (fill `primary`, teks putih, radius 12, padding 4 / 12, ukuran sama dengan H1; contoh kata "Kirim Dokumen Lab"). Paragraf `web-body` maks. 640, tengah. Dua tombol 48 sejajar: Primary "Mulai Pakai Sekarang (PWA) →" dan tombol garis (border `border-subtle`, fill `surface`) "Daftar Driver Kampus" + ikon helm. Baris kepercayaan: 3 item `caption` dipisah celah 24, ikon 14 (bintang, perisai, gedung): "4.9/5 dari 10.000+ Mahasiswa", "Terintegrasi SSO Kampus Resmi (NIM Valid)", "Aktif UIN, UI, ITB, & UGM" (lihat T-20) |
| Statistik (Count-Up) | Grid 4 kolom, gap 12, tinggi ±126 | Kartu `surface`, radius 16, border `border-subtle`, padding 16. Label `micro` UPPERCASE `text-muted` kiri atas, tile ikon 28 `mint-100` kanan atas, angka `web-stat` (`primary`; kartu terakhir `info`), keterangan `web-small`. Isi: PENGGUNA AKTIF `10.000+`, DRIVER KAMPUS `50+`, MITRA KANTIN `30+`, POTONGAN KOMISI `0.5%` ("Bandingkan platform lain (20%+)") |
| Bento Build Showcase | Header kiri: eyebrow `web-eyebrow` "ARSITEKTUR EKOSISTEM 3-ARAH", `web-h2` "Satu Jaringan Terpadu untuk Tiga Pilar Civitas Akademika", paragraf. Grid 3 kolom, gap 12, tinggi ±255 | Kartu 1 "01 • MAHASISWA" (`surface`): judul `web-card-title` "Pesan Tepat Sampai di Meja Kelas", deskripsi, widget mini `lav-100` radius 12 (label "Keamanan Serah Terima Lobi", "PIN: 8492" `mono`, "Driver menuju Lobi FST", "ETA: 3 Menit", progress bar), link "Lihat panduan pemesanan →". Kartu 2 "02 • DRIVER RIDER" (fill `primary`, teks putih): judul "1-Click Order Radar Mahasiswa", deskripsi, kotak `rgba(255,255,255,0.14)` radius 12 ("Pendapatan Hari Ini" + "Rp 84.500" + "100% langsung cair ke Dompet Kampus"), link "Syarat pendaftaran driver →". Kartu 3 "03 • MITRA UMKM" (`surface`): judul "Harga Menu Tetap, Zero Markup", deskripsi, checklist 3 baris (ikon centang `primary`), link "Daftarkan warung kantin →". Eyebrow kartu `micro` `primary`; ikon 24 kanan atas |
| Toast aktivitas | Tetap kiri bawah viewport | B.5. Contoh isi: "Rizal baru saja pesan Nasi Ayam / Kantin Rektorat → Lab Komputer 3" (lihat T-09) |
| Workflow (Process Draw) | Header tengah: `web-eyebrow` "WORKFLOW CEPAT", `web-h2`, paragraf. Grid 4 kolom, gap 12, tinggi ±184 | Kartu `surface` radius 16 padding 16: tile nomor 32 `mint-100` (`01`–`04`, `h5` `primary`) kiri atas, ikon 20 kanan atas, judul `web-card-title`, deskripsi `web-small`, tag `micro` `primary` di dasar ("PRESET AKURAT", "RESPON < 30 DETIK", "PRESISI SELANG KELAS", "100% ANTI TERTUKAR"). Garis Process Draw tidak terlihat pada mockup; letakkan di belakang tile nomor (D.3) |
| Perbandingan (Price Roll) | Header tengah: `web-eyebrow` "PERBANDINGAN NYATA", `web-h2` "Hitung Penghematan Uang Saku Mahasiswa". Tab pill tengah. Dua kartu sejajar, lebar maks. 880 | Tab: "Makan Siang Satuan" (terpilih), "Jastip Kelompok (3 Porsi)", "Nebeng Antar Fakultas". Kartu kiri "Aplikasi Komersial Umum": 4 baris + total `h2`. Kartu kanan "Campus Express (Go-Campus)" (fill `primary`, badge "BEST VALUE SIVITAS"): 4 baris + total. Di bawah: banner `mint-100` radius 12 tinggi 48: "🎉 Kamu Berhemat Rp 19.000 (49%) untuk pesanan ini!" kiri, keterangan `caption` kanan. Mockup memakai tab skenario, bukan slider seperti `PRD.md` §8 |
| Antarmuka Ringan (Cursor Tour) | Header tengah: `web-eyebrow` "ANTARMUKA RINGAN", `web-h2`, paragraf. Bingkai perangkat tengah, lebar ±760 | Bingkai `surface`, radius 16, border `border-subtle`, `shadow-float`; bar atas status ("09:41 • Eduroam UIN-Connect", ikon sinyal). Isi: judul "RADAR MATCHING INTRA-KAMPUS" + badge "AKTIF"; chip "Pilih Pos Penjemputan Cepat" (3 chip, satu terpilih `primary`); 2 kartu dalam (QRIS & Saldo Mahasiswa dengan "Saldo Dompet Kampus Rp 45.000"; Chat Lobi dengan 2 bubble); kartu bawah "Mode Kurir Terverifikasi" + versi `mono`. 3 label hotspot (B.5): "Hotspot 1: Radar Order 1-Klik" (kanan atas), "Hotspot 2: Instant Settlement" (kiri bawah), "Hotspot 3: In-App Landmark Chat" (kanan bawah) |
| Testimoni (Review Shuffle) | Header tengah: `web-eyebrow` "TESTIMONI OTENTIK", `web-h2`, paragraf. Grid 3 kolom, gap 12 | Kartu `surface` radius 16 padding 16: 5 bintang `star` (16), kutipan `web-small`, baris bawah avatar inisial 36 `lav-300` + nama `h5` + peran `caption`. Terlihat sebagai grid statis, bukan tumpukan geser seperti `PRD.md` §8 |
| CTA Unduh | Pita `primary`, radius 24, padding 32, 2 kolom (7/5) | Kiri: pill eyebrow `rgba(255,255,255,0.16)` "AKSESIBILITAS MULTI-PLATFORM"; `web-h2` putih "Pasang Aplikasi di Ponselmu Sekarang" (frasa pertama diberi highlight `mint-300` teks `on-mint`); paragraf `on-primary-muted`; tombol putih "Download APK (1.8 MB)" (ikon Android) dan tombol glass "Panduan PWA Safari (iOS)". Kanan: kartu `surface` radius 16 padding 16 dengan QR 120 dp, "Scan untuk Pasang PWA" `h5`, `caption`, status "● Versi Stabil 2.4.0 (Live)" `primary` |
| Footer | 3 kolom (4 / 5 / 3), fill `surface`, border atas `divider`, padding 32 | Kolom 1: logo + deskripsi `web-small` + status "● Sistem Operasional Aktif di 14 Fakultas & Koridor Asrama". Kolom 2: kartu `surface` border dengan QR 64 + "Unduh Aplikasi Mobile" `h5` + teks + link "Panduan Add to Home Screen (Safari)". Kolom 3: "AKSESIBILITAS & TAUTAN CEPAT" `micro` + 4 link berikon (Syarat & Ketentuan Layanan, Hubungi Posko BEM & Helpdesk, Status Server & Cluster API, Pendaftaran Mitra Kurir Motor). Baris bawah: hak cipta kiri, indikator latensi dan versi kanan (`mono` `caption`) |

Perbedaan dengan `PRD.md` §8 pada mockup: Hero Referral Banner berupa pill statis tanpa pembuat tautan dan pelacak; Price Roll berupa tab skenario; Review Shuffle berupa grid 3 kolom; tidak ada gambar ponsel pada hero; Cursor Tour berupa label hotspot pada bingkai perangkat. Pilih salah satu: ikuti mockup atau PRD, lalu satukan.

Data contoh pada mockup (gambar 27), untuk seed dan uji UI. Seluruh angka adalah ilustrasi dan harus diberi label asumsi (T-19, T-20):

| Elemen | Isi pada mockup |
|---|---|
| Perbandingan, tab "Makan Siang Satuan", kartu kiri "Aplikasi Komersial Umum" | Harga Menu (Markup Resto 20%) `Rp 20.000`; Biaya Ongkir Luar Kampus `Rp 12.000`; Biaya Layanan & Jasa Aplikasi `Rp 4.500`; Biaya Parkir Gedung Eksternal `Rp 2.000`; Total Pengeluaran `Rp 38.500` |
| Perbandingan, kartu kanan "Campus Express (Go-Campus)" | Harga Asli Etalase Kantin `Rp 15.000`; Ongkir Flat Intra-Kampus `Rp 4.000`; Iuran Pemeliharaan BEM (0.5%) `Rp 500`; Biaya Parkir Kampus `Rp 0 (Gratis KTM)`; Total Bersih `Rp 19.500` |
| Banner hemat | "Kamu Berhemat Rp 19.000 (49%) untuk pesanan ini!" kiri; "Cukup untuk fotokopi puluhan lembar tugas" kanan |
| Testimoni (3 kartu) | Anisa Rahmawati (Mahasiswa Teknik Informatika '21); Daffa Firdaus (Driver Rider Kampus • FEB '22); Bu Siti Maryam (Pemilik Kantin Rektorat) |
| Cursor Tour | Bar atas "09:41 • Eduroam UIN-Connect"; chip pos jemput: Lobi Barat FST, satu chip kantin (terpilih; teks terlalu kecil untuk dibaca pasti), Perpustakaan Pusat; saldo "Saldo Dompet Kampus Rp 45.000"; chat lobi 2 bubble; kartu bawah "Mode Kurir Terverifikasi" dengan versi `v2.4.0-LIGHT` |
| Widget kartu 01 (Bento) | "Keamanan Serah Terima Lobi", `PIN: 8492`, "Driver menuju Lobi FST", `ETA: 3 Menit` |
| Widget kartu 02 (Bento) | "Pendapatan Hari Ini" `Rp 84.500`, "100% langsung cair ke Dompet Kampus" |
| Toast aktivitas | Avatar "RZ"; "LIVE ACTIVITY • 2m yang lalu"; "Rizal baru saja pesan Nasi Ayam"; rute "Kantin Rektorat → Lab Komputer 3" |

Selisih hemat 19.000 dari 38.500 − 19.500 = 19.000 (49,4%); hitungan baris konsisten, tetapi dasar iuran 0.5% dan markup 20% tidak (T-19).

Layout responsif yang disarankan (tidak ada mockup): di bawah `lg`, grid 4 kolom menjadi 2 kolom, grid 3 kolom menjadi 1 kolom dengan snap-scroll horizontal untuk bento dan testimoni; di bawah `md`, navbar diganti ikon menu, hero `web-h1` 32 / 38, tombol hero penuh lebar bertumpuk, kartu perbandingan bertumpuk (Campus Express di bawah), bingkai perangkat dipangkas ke satu kartu dalam.

---

## D. Interactive & Motion Specs

Catatan: animasi tidak terlihat pada gambar statis. Nilai di bawah adalah spesifikasi implementasi yang sesuai dengan elemen yang tampak pada mockup dan dengan `PRD.md` §5 dan §8. Semua animasi dekoratif dinonaktifkan bila `prefers-reduced-motion` (web) atau `MediaQuery.disableAnimations` (Flutter) aktif.

### D.1 Token Durasi dan Easing

| Token | Durasi | Easing | Pemakaian |
|---|---|---|---|
| `motion-instant` | 100 ms | `linear` | Efek tekan tombol (scale 0.98), ripple |
| `motion-fast` | 150 ms | `ease-out` | Perubahan warna, toggle, centang |
| `motion-base` | 250 ms | `cubic-bezier(0.2, 0, 0, 1)` | Kartu masuk/keluar, toast, chip |
| `motion-slow` | 300 ms | `ease-in-out` | Transisi halaman, snap bottom sheet |
| `motion-emphasis` | 400 ms | `cubic-bezier(0.2, 0, 0, 1)` | Isi garis stepper, hasil sukses |
| `motion-count` | 1200 ms | `ease-out-cubic` | Count-up |
| `motion-hold` | 2400 ms | — | Jeda Word Rotator |

Flutter: `Curves.easeOut`, `Curves.easeInOut`, `Cubic(0.2, 0, 0, 1)`.

### D.2 Word Rotator (Onboarding mobile dan Hero web)

Kata (mobile): `Jastip Kantin`, `Nebeng Kampus`, `Kirim Berkas`, `UMKM Mahasiswa` (diturunkan dari subjudul onboarding). Kata (web, gambar 27): `Kirim Dokumen Lab` terlihat pada mockup; kata lain mengikuti layanan (`Jastip Kantin`, `Nebeng Kampus`, `Katalog UMKM`). Chip web: fill `primary`, teks putih, radius 12, padding 4 / 12, ukuran font sama dengan `web-h1`.

| Aspek | Spesifikasi |
|---|---|
| Siklus | Tampil 2400 ms, keluar 250 ms, masuk 250 ms |
| Keluar | `translateY(0 → -100%)`, `opacity 1 → 0`, `ease-in` |
| Masuk | `translateY(100% → 0)`, `opacity 0 → 1`, `ease-out` |
| Lebar | Dikunci ke kata terpanjang (ukur dengan `TextPainter` di Flutter; elemen `invisible` di web) agar chip tidak berubah lebar dan tidak memicu layout shift |
| Chip (mobile) | Fill `primary`, teks putih; chip tidak beranimasi, hanya teks di dalamnya (`ClipRect` + `AnimatedSwitcher` dengan `SlideTransition`) |
| Aksesibilitas | `Semantics(liveRegion: false)`; teks pertama dibaca pembaca layar sekali, tidak diumumkan ulang; reduced motion: kata pertama statis |

Web (Framer Motion): `AnimatePresence mode="wait"`, `initial={{y:'100%',opacity:0}}`, `animate={{y:0,opacity:1}}`, `exit={{y:'-100%',opacity:0}}`, `transition={{duration:0.25, ease:[0.2,0,0,1]}}`. Implementasi lengkap ada di `tech.md` §6.2.

### D.3 Process Draw SVG dan Stepper Status

| Konteks | Mekanisme |
|---|---|
| Stepper di app (layar 8) | Saat status maju: garis ke simpul berikutnya terisi dari kiri ke kanan 400 ms `motion-emphasis`; simpul berubah dari `lav-200` ke `mint-300` (150 ms); ikon centang pada simpul yang selesai muncul dengan `scale 0.6 → 1.0` 200 ms `ease-out`; simpul aktif berdenyut halus (`scale 1 → 1.08 → 1`, 1600 ms loop) selama status belum berubah |
| Timeline web | Garis SVG vertikal: `pathLength` 0 → 1 mengikuti `scrollYProgress` (offset `["start 80%","end 40%"]`), tanpa durasi (terikat scroll). Simpul berubah dari `lav-300` ke `primary` saat `pathLength` melewati posisinya. Teks langkah masuk `opacity 0 → 1` + `translateY(12 → 0)` 250 ms saat simpul aktif |
| Reduced motion | Garis tampil penuh |

### D.4 Review Shuffle Stack

| Konteks | Mekanisme |
|---|---|
| Web (tumpukan) | Maks. 4 kartu terlihat. Kartu ke-n: `scale = 1 − 0.05n`, `translateY = 14n px`, `opacity = 1 − 0.2n`. Geser kartu teratas pada sumbu x; bila `|offset| > 100 px` atau kecepatan > 500 px/dtk: kartu keluar `translateX ±320 px` + `rotate ±8°` 250 ms `ease-in`, lalu dipindah ke dasar tumpukan; kartu lain naik satu posisi 250 ms `motion-base`. Bila tidak melewati ambang: kembali ke posisi awal dengan spring (`stiffness 300, damping 26`) |
| Mobile (profil, gambar 17) | `PageView` `viewportFraction 0.92`, indikator titik (lebar aktif 20 dp, transisi 150 ms). Tombol "Shuffle": mengacak urutan 6 ulasan teratas dan memuat dari awal; kartu lama `opacity → 0` 150 ms, kartu baru `opacity → 1` + `translateY(8 → 0)` 250 ms |

Pengamatan gambar 27: testimoni ditampilkan sebagai grid 3 kolom statis. Bila tumpukan geser dipertahankan, pakai di bawah `lg` dan grid di `lg` ke atas; di grid, kartu masuk dengan `opacity 0 → 1` + `translateY(16 → 0)` 250 ms dan jeda 60 ms antar kartu, sekali saat terlihat.

### D.5 Peta, ETA, dan Live Ping

| Elemen | Mekanisme |
|---|---|
| Marker kendaraan | Posisi dihitung tiap frame (target 30 fps) dari checkpoint terakhir: progres `p = clamp(t / durasiSegmen, 0, 0.95)` (lihat `PRD.md` §5.3). Marker berhenti di 0.95 sampai checkpoint berikutnya. Halo 72 dp berdenyut `scale 1 → 1.25`, `opacity 0.15 → 0`, 1800 ms loop |
| Garis rute | Putus-putus, dash 8 / gap 6, tebal 5, ujung bulat. Tidak beranimasi; bagian yang sudah dilalui tidak dihapus |
| Kamera | Saat checkpoint baru: `easeTo` ke fit bounds dengan padding 48, 600 ms `ease-in-out`. Setelah pengguna menggeser peta, kamera berhenti mengikuti sampai tombol recenter ditekan |
| Pill ETA | Angka menit berubah dengan cross-fade 200 ms; tidak boleh berubah lebih sering dari 1 kali per 5 detik (hindari kedip) |
| Fallback 2D | Perpindahan 3D → 2D tanpa animasi kamera; marker dan rute dirender ulang dalam 1 frame |
| Live Ping (mobile) | Isi kartu ganti tiap 6 dtk: `opacity 1 → 0` 150 ms, ganti teks, `opacity 0 → 1` 250 ms. Titik online berdenyut 1600 ms loop |
| Toast sales ping (web) | Masuk `translateY(16 → 0)` + `opacity 0 → 1` 250 ms; tampil 4000 ms; keluar 250 ms. Antrean: satu toast per 6 dtk |

### D.6 Komponen Lain

| Elemen | Mekanisme |
|---|---|
| Tombol tekan | `scale 1 → 0.98` 100 ms, kembali 150 ms |
| Claim 1-Click | Tekan → label menjadi spinner 20 dp (150 ms) → sukses: kartu geser keluar ke atas 250 ms dan layar Active Job dibuka (shared axis 300 ms) |
| Bar kedaluwarsa | Isi menyusut linear selama sisa waktu server; kartu dihapus saat 0 dengan `height → 0` + `opacity → 0` 200 ms |
| Slot PIN | Digit masuk: `scale 0.8 → 1` 120 ms. PIN salah: geser horizontal `±8 dp` 3 kali dalam 300 ms + haptic `heavyImpact` |
| Keypad | Tekan: fill `lav-400` 100 ms |
| Toggle | Thumb bergeser 150 ms `ease-out` |
| Bottom sheet | Muncul 300 ms `ease-in-out`; drag mengikuti jari; snap dengan spring `stiffness 400, damping 32` |
| Count-up (Radar, statistik, web) | `0 → n` 1200 ms `ease-out-cubic`; di mobile hanya saat nilai berubah, tidak dari 0 |
| Skeleton | Shimmer 1200 ms linear loop |
| Transisi halaman (Flutter) | Shared axis horizontal 300 ms `ease-in-out`; tab nav: fade-through 150 ms |
| Price Roll (web) | `useSpring(stiffness 120, damping 20)`; digit berubah mengikuti slider tanpa jeda |

### D.7 Landing Page dan Formulir (gambar 21–27)

| Elemen | Mekanisme |
|---|---|
| Navbar | `shadow-card` muncul setelah scroll 8 px, 150 ms |
| Statistik | Count-up 1200 ms `ease-out-cubic` saat 40% kartu terlihat (IntersectionObserver), satu kali; tanda `+` dan `%` ditambahkan setelah angka selesai dihitung |
| Bento Build Showcase | Kartu masuk `opacity 0 → 1` + `translateY(16 → 0)` 250 ms, jeda 60 ms antar kartu. Widget mini pada kartu 01: progress ETA terisi `0 → 65%` 800 ms `ease-out`, PIN muncul digit demi digit (80 ms per digit) |
| Workflow (Process Draw) | Garis horizontal di belakang tile nomor (desktop) atau vertikal (mobile), `pathLength` mengikuti scroll (D.3). Tile nomor berubah `mint-100 → mint-300` saat garis melewatinya, 150 ms |
| Tab perbandingan | Indikator tab bergeser 250 ms `motion-base`. Angka pada kedua kartu dan banner berputar dengan spring (`stiffness 120, damping 20`, ±400 ms). Tinggi kartu tetap (tidak berubah antar skenario) |
| Cursor Tour | Label hotspot muncul berurutan, jeda 600 ms, `opacity 0 → 1` + `scale 0.9 → 1` 250 ms. Tanpa interaksi, ikon kursor berpindah antar hotspot tiap 3000 ms (`translate`, 300 ms `ease-in-out`); jeda saat hover/fokus. Hover/fokus: ring 4 px dan `scale 1.05`, 150 ms. Navigasi keyboard: Tab berpindah antar hotspot |
| Toast aktivitas | Masuk 250 ms, tampil 4000 ms, keluar 250 ms; satu toast per 6 detik. Tombol tutup menghilangkan toast saat itu juga (150 ms fade) dan menghentikan toast berikutnya selama sesi |
| Bintang rating | Ketuk: `scale 1 → 1.2 → 1` 120 ms; bintang di kiri titik ketuk terisi berurutan, jeda 40 ms |
| Tag chip, pemilih tip | Perubahan warna 150 ms; chip terpilih `scale 0.96 → 1` 120 ms |
| Progres registrasi | Lebar isi progress bar beranimasi ke nilai baru 400 ms `motion-emphasis` saat berpindah langkah |
| Unggah dokumen/foto | Cincin progres pada dropzone dan tile; setelah selesai, thumbnail muncul `opacity 0 → 1` 250 ms |
| Kirim penilaian | Tombol → spinner 150 ms; sukses: layar terima kasih dengan centang `scale 0.6 → 1` 250 ms dan penghitung poin naik 600 ms `ease-out-cubic` |
| Jadwal toko dan toggle | Toggle 150 ms; baris jadwal yang dinonaktifkan turun ke `opacity 0.5` 150 ms |

---

## E. Implementation Guidelines

### E.1 `tailwind.config.js`

```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#006C4A',
          pressed: '#00553A',
          bright: '#059669',
          glow: '#10B981',
        },
        mint: { 100: '#CFF8E8', 300: '#8DF3CE', on: '#00553A' },
        lav: { 100: '#F1F3FF', 200: '#E9EDFF', 300: '#E2E7FF', 400: '#D5DBF5' },
        bg: '#F8F9FF',
        surface: '#FFFFFF',
        ink: { 800: '#1F2A3C' },
        text: { strong: '#0F1A2B', body: '#3E4A5A', muted: '#5B6676' },
        danger: { DEFAULT: '#BA1A1A', container: '#FFDAD6' },
        info: { DEFAULT: '#00639B', 100: '#D2EBFF' },
        star: '#F59E0B',
        line: { subtle: '#E3E7F4', divider: '#ECEFFA' },
      },
      fontFamily: {
        display: ['"Plus Jakarta Sans"', 'Inter', 'system-ui', 'sans-serif'],
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['"JetBrains Mono"', 'ui-monospace', 'monospace'],
      },
      fontSize: {
        display: ['40px', { lineHeight: '48px', letterSpacing: '-0.5px', fontWeight: '800' }],
        h1: ['28px', { lineHeight: '34px', letterSpacing: '-0.3px', fontWeight: '800' }],
        h2: ['22px', { lineHeight: '28px', letterSpacing: '-0.2px', fontWeight: '700' }],
        h3: ['18px', { lineHeight: '24px', letterSpacing: '-0.1px', fontWeight: '700' }],
        h4: ['16px', { lineHeight: '22px', fontWeight: '700' }],
        h5: ['15px', { lineHeight: '20px', fontWeight: '600' }],
        'body-l': ['16px', { lineHeight: '24px' }],
        'body-m': ['14px', { lineHeight: '20px' }],
        'body-s': ['13px', { lineHeight: '18px' }],
        caption: ['12px', { lineHeight: '16px', fontWeight: '500', letterSpacing: '0.1px' }],
        micro: ['11px', { lineHeight: '14px', fontWeight: '700', letterSpacing: '0.4px' }],
        'web-h1': ['40px', { lineHeight: '48px', letterSpacing: '-0.5px', fontWeight: '800' }],
        'web-h2': ['26px', { lineHeight: '32px', letterSpacing: '-0.3px', fontWeight: '800' }],
        'web-stat': ['30px', { lineHeight: '36px', fontWeight: '800' }],
        'web-eyebrow': ['11px', { lineHeight: '14px', letterSpacing: '0.6px', fontWeight: '700' }],
      },
      borderRadius: { xs: '4px', sm: '8px', md: '12px', lg: '16px', xl: '24px', sheet: '28px' },
      boxShadow: {
        card: '0 1px 3px rgba(15,26,43,.06), 0 1px 2px rgba(15,26,43,.04)',
        'bar-top': '0 -4px 16px rgba(15,26,43,.08)',
        float: '0 8px 24px rgba(15,26,43,.14)',
        cta: '0 4px 10px rgba(0,108,74,.28)',
      },
      backgroundImage: {
        wallet: 'linear-gradient(135deg, #006C4A 0%, #047857 100%)',
        'photo-fade': 'linear-gradient(to top, rgba(0,0,0,.65), rgba(0,0,0,0) 60%)',
      },
      transitionTimingFunction: { emphasis: 'cubic-bezier(0.2, 0, 0, 1)' },
      transitionDuration: { fast: '150ms', base: '250ms', slow: '300ms', emphasis: '400ms' },
      screens: { sm: '640px', md: '768px', lg: '1024px', xl: '1280px' },
    },
  },
  plugins: [],
};
```

Contoh pemakaian kelas:

| Komponen | Kelas |
|---|---|
| Primary button | `h-12 rounded-lg bg-primary px-4 font-display text-h4 text-white shadow-cta active:scale-[.98] active:bg-primary-pressed` |
| Kartu | `rounded-lg bg-surface p-4 shadow-card` |
| Kartu tonal | `rounded-lg bg-lav-300 p-4` |
| Badge sukses | `inline-flex h-6 items-center rounded-full bg-mint-300 px-2.5 text-micro uppercase text-mint-on` |
| Field | `h-14 rounded-md bg-lav-200 px-4 text-body-l focus:outline-none focus:ring-2 focus:ring-primary` |

### E.2 Flutter `ThemeData`

Font dibundel di `pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/PlusJakartaSans-Bold.ttf
          weight: 700
        - asset: assets/fonts/PlusJakartaSans-ExtraBold.ttf
          weight: 800
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Bold.ttf
          weight: 700
```

Token warna dan tema:

```dart
class CeColors {
  static const primary = Color(0xFF006C4A);
  static const primaryPressed = Color(0xFF00553A);
  static const primaryBright = Color(0xFF059669);
  static const primaryGlow = Color(0xFF10B981);
  static const mint100 = Color(0xFFCFF8E8);
  static const mint300 = Color(0xFF8DF3CE);
  static const onMint = Color(0xFF00553A);
  static const bg = Color(0xFFF8F9FF);
  static const surface = Color(0xFFFFFFFF);
  static const lav100 = Color(0xFFF1F3FF);
  static const lav200 = Color(0xFFE9EDFF);
  static const lav300 = Color(0xFFE2E7FF);
  static const lav400 = Color(0xFFD5DBF5);
  static const ink800 = Color(0xFF1F2A3C);
  static const textStrong = Color(0xFF0F1A2B);
  static const textBody = Color(0xFF3E4A5A);
  static const textMuted = Color(0xFF5B6676);
  static const danger = Color(0xFFBA1A1A);
  static const dangerContainer = Color(0xFFFFDAD6);
  static const info = Color(0xFF00639B);
  static const info100 = Color(0xFFD2EBFF);
  static const star = Color(0xFFF59E0B);
  static const lineSubtle = Color(0xFFE3E7F4);
  static const divider = Color(0xFFECEFFA);
}

class CeText {
  static const _display = 'PlusJakartaSans';
  static const _body = 'Inter';
  static const _mono = 'JetBrainsMono';

  static const display = TextStyle(fontFamily: _display, fontSize: 40, height: 48 / 40, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: CeColors.textStrong);
  static const h1 = TextStyle(fontFamily: _display, fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: CeColors.textStrong);
  static const h2 = TextStyle(fontFamily: _display, fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: CeColors.textStrong);
  static const h3 = TextStyle(fontFamily: _display, fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w700, letterSpacing: -0.1, color: CeColors.textStrong);
  static const h4 = TextStyle(fontFamily: _display, fontSize: 16, height: 22 / 16, fontWeight: FontWeight.w700, color: CeColors.textStrong);
  static const h5 = TextStyle(fontFamily: _display, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w600, color: CeColors.textStrong);
  static const bodyL = TextStyle(fontFamily: _body, fontSize: 16, height: 24 / 16, color: CeColors.textStrong);
  static const bodyM = TextStyle(fontFamily: _body, fontSize: 14, height: 20 / 14, color: CeColors.textBody);
  static const bodyS = TextStyle(fontFamily: _body, fontSize: 13, height: 18 / 13, color: CeColors.textBody);
  static const caption = TextStyle(fontFamily: _body, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: CeColors.textMuted);
  static const micro = TextStyle(fontFamily: _body, fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: CeColors.primary);
  static const mono = TextStyle(fontFamily: _mono, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: CeColors.textStrong);
}

ThemeData buildCeTheme() {
  const scheme = ColorScheme.light(
    primary: CeColors.primary,
    onPrimary: Colors.white,
    primaryContainer: CeColors.mint300,
    onPrimaryContainer: CeColors.onMint,
    secondary: CeColors.info,
    secondaryContainer: CeColors.lav300,
    onSecondaryContainer: CeColors.textStrong,
    surface: CeColors.surface,
    onSurface: CeColors.textStrong,
    surfaceContainerHighest: CeColors.lav300,
    error: CeColors.danger,
    errorContainer: CeColors.dangerContainer,
    outline: CeColors.lineSubtle,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: CeColors.bg,
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      displayMedium: CeText.display,
      headlineLarge: CeText.h1,
      headlineMedium: CeText.h2,
      headlineSmall: CeText.h3,
      titleLarge: CeText.h4,
      titleMedium: CeText.h5,
      bodyLarge: CeText.bodyL,
      bodyMedium: CeText.bodyM,
      bodySmall: CeText.bodyS,
      labelMedium: CeText.caption,
      labelSmall: CeText.micro,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: CeColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      toolbarHeight: 64,
      titleTextStyle: CeText.h3,
    ),
    cardTheme: CardThemeData(
      color: CeColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CeColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: CeText.h4,
        elevation: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CeColors.lav300,
        foregroundColor: CeColors.textStrong,
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: CeText.h5,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: CeColors.primary,
        minimumSize: const Size(0, 44),
        textStyle: CeText.h5,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CeColors.lav200,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: CeText.bodyL.copyWith(color: CeColors.textMuted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CeColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CeColors.danger, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: CeColors.surface,
      selectedColor: CeColors.primary,
      side: const BorderSide(color: CeColors.lineSubtle),
      shape: const StadiumBorder(),
      labelStyle: CeText.bodyM.copyWith(fontWeight: FontWeight.w600),
      secondaryLabelStyle: CeText.bodyM.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: CeColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected)
          ? CeText.caption.copyWith(color: CeColors.primary, fontWeight: FontWeight.w700)
          : CeText.caption),
      iconTheme: WidgetStateProperty.resolveWith((s) =>
          IconThemeData(size: 24, color: s.contains(WidgetState.selected) ? CeColors.primary : CeColors.textMuted)),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? CeColors.primary : CeColors.lav400),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? CeColors.primary : CeColors.lav400),
      side: BorderSide.none,
    ),
    dividerTheme: const DividerThemeData(color: CeColors.divider, thickness: 1, space: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: CeColors.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
  );
}
```

Catatan implementasi Flutter:
- Format rupiah: `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)`.
- Status badge, kartu bento, stepper, kotak PIN, dan bubble chat dibuat sebagai widget tersendiri di `core/widgets/` dengan parameter variasi warna dari tabel "Pemetaan warna status", bukan dengan menyalin `Container` per layar.
- Rasio kontras terhitung (WCAG): putih di atas `primary` 6,47:1; `on-mint` di atas `mint-300` 6,71:1; `primary` di atas `mint-100` 5,62:1; `danger` di atas `danger-container` 5,0:1; `text-body` di atas `surface` 9,01:1; `text-muted` (`#5B6676`) di atas `surface` 5,82:1, `bg` 5,54:1, `lav-200` 5,00:1, `lav-300` 4,74:1. Warna `text-muted` bawaan mockup (±`#6B7686`) hanya 4,38:1 di atas `bg` dan 3,75:1 di atas `lav-300`, sehingga tidak dipakai.

---

## F. Temuan dan Selisih terhadap Dokumen Lain

Hasil pembacaan 27 gambar (20 + 7). Kolom "Tindakan" menyebut dokumen yang perlu disamakan. T-01 sampai T-10 menyangkut keputusan produk; T-11 sampai T-18 menyangkut tarif, privasi, klaim, dan kualitas mockup pada kiriman pertama; T-19 sampai T-35 berasal dari gambar 21–27.

| ID | Gambar | Temuan | Berbenturan dengan | Tindakan |
|---|---|---|---|---|
| T-01 | Semua | Seluruh UI memakai tema terang (`bg #F8F9FF`, kartu putih). Peta isometrik juga terang | `PRD.md` §9.2 (latar `#04130E`), `tech.md` §5.2 (gaya peta gelap), `tech.md` §3.3 dan §6.1 (token berbeda), brief awal "Dark Emerald" | Putuskan tema. Bila mockup yang dipakai: perbarui token PRD, gaya peta, `theme.dart`, `tailwind.config.ts` mengikuti bagian A dan E |
| T-02 | 11, 18 | Potongan platform ditulis "Iuran Operasional Server BEM 5%" (Rp 300 dari Rp 6.000; Rp 422.500 dari Rp 8.450.000). Saldo minimum Rp 1.000 (gambar 10, 11). Dasar potongan tampak berupa ongkir | `PRD.md` X2 dan M13 (0,5% dari subtotal + ongkir, minimum Rp 50, saldo minimum Rp 5.000), `Monetization.md` §2–§3 | Tentukan persentase dan dasar komisi, lalu satukan angka di semua dokumen dan layar. 5% sepuluh kali lipat dari 0,5% dan bertentangan dengan pesan "0,5%" di landing |
| T-03 | 9, 11, 13, 17, 24, 25, 26 | Ada Escrow BEM (dana diteruskan ke kantin setelah diterima), ongkir "otomatis dikreditkan ke Saldo Dompet", Saldo KTM Tap / KampusPay milik konsumen (bernama "CXPay" pada gambar 24), tombol "Tarik Saldo", pencairan otomatis hasil penjualan merchant tiap 18.00 (gambar 26), serta refund otomatis ke saldo konsumen dan dana pesanan ditahan selama dispute (gambar 25) | `Monetization.md` §1 dan §4.1 (platform tidak memegang dana transaksi, saldo bukan uang elektronik), `PRD.md` §1.3 (tanpa pembayaran in-app) | Perubahan besar: platform menyimpan dan menyalurkan dana pengguna. Perlu keputusan produk dan tinjauan hukum sebelum dirancang. Bila tidak diambil, hapus elemen ini dari mockup |
| T-04 | 9, 23, 26, 27 | Metode "QRIS Dinamis" dengan "Verifikasi Otomatis AI Kampus < 10 Detik"; "QRIS Dinamis Merchant" dengan NMID pada Store Settings (gambar 26); e-receipt "QRIS Dinamis" (gambar 23); landing menjual "verifikasi otomatis < 10 detik" (gambar 27) | `PRD.md` M06 (QRIS statis + bukti + konfirmasi penerima) | QRIS dinamis dan verifikasi otomatis memerlukan penyedia pembayaran. Samakan dengan v1 (statis) atau tambahkan modul pembayaran |
| T-05 | 8, 9 | Keranjang berisi 2 kantin ("Pesanan Dari 2 Kantin", "Kantin FST & Psikologi") | `Rules.md` BR-O3 dan `PRD.md` FR-05.2 (satu merchant per order) | Multi-merchant memerlukan beberapa pengambilan oleh satu driver, ongkir per titik, dan status per merchant. Pilih: batasi ke 1 merchant atau definisikan ulang model order |
| T-06 | 9, 18 | Biaya Layanan & Pemeliharaan Loker Rp 1.000, diskon Subsidi UKT Rp 3.000 (voucher MABAEXPRESS), subsidi Kas BEM Rp 1.000–1.500 per trip | `PRD.md` FR-06.2 (komisi tidak dibebankan ke konsumen), `Monetization.md` §4 | Tentukan apakah ada biaya layanan konsumen dan sumber dana subsidi. Pada gambar 9 diskon 3.000 lebih besar dari biaya layanan + selisih zona |
| T-07 | 4, 5, 17 | Login NIM + OTP WhatsApp, domain kedua `@student.ac.id`, "sinkronisasi PD-DIKTI via API", "KTM Digital Terintegrasi" | `PRD.md` M01 (hanya Google SSO `@mhs.uin.ac.id`, NIM dari pengguna) | Integrasi PD-DIKTI dan OTP WhatsApp tidak ada di arsitektur. Keduanya perlu pembuktian ketersediaan (akses API, biaya pengirim OTP). Jika tidak tersedia, ganti teks dengan fitur yang benar-benar ada |
| T-08 | 1, 12, 13, 20 | Tombol utama "Chat WA" / "WhatsApp" (hijau, paling menonjol) dan tombol "Telepon" di kartu driver; chip "WA Darurat" selalu tampil di chat | `PRD.md` §1 dan FR-09.4 (chat in-app = saluran utama, WhatsApp hanya fallback darurat setelah 3 menit tanpa respons) | Jadikan tombol "Chat" (in-app) sebagai utama. Tampilkan WA hanya pada kondisi fallback. Pertimbangkan menghapus "Telepon" (membuka nomor pribadi) |
| T-09 | 3, 6 | Live Ping memuat nama dan jurusan ("Rizal (Teknik) pesan Nasi Goreng Kantin A") | `PRD.md` §8 komponen 3 dan `threat-model.md` T-50 (anonim, tanpa identitas) | Ubah ke "Seseorang di {fakultas} baru memesan {menu}", atau minta persetujuan pengguna di pengaturan privasi |
| T-10 | 3, 6, 8, 10, 11, 14, 22, 23, 25, 26 | Nav konsumen berbeda antar gambar (`Beranda/Pesanan/Radar/Akun` vs `Catalog/Orders/Wallet/Profile`). Driver dan merchant sama-sama memakai `Radar/Dompet/Toko/Akun`. "Radar" muncul di nav konsumen tanpa layar yang jelas. Gambar 22, 23, 25, 26 memakai susunan keempat (`Orders/Products/Store/Support`) dan header "Node" (tile truk + chip CAMPUS), termasuk pada layar konsumen (Order History, Dispute Center). Label bercampur Inggris dan Indonesia ("Catalog", "Orders", "Authentication", "Booking Detail", "Item Customizer") | `PRD.md` §9, `UserRole.md` §5 | Gunakan nav per peran seperti di C.0; semua label berbahasa Indonesia |
| T-11 | 4, 6, 7, 18 | "Rp 4.000 Flat Se-Kampus" dan "Tarif Flat Mahasiswa Rp 4.000", sedangkan panel admin mendefinisikan Zona 1 Rp 4.000, Zona 2 Rp 6.000, Zona 3 Rp 8.000 | `fareMatrix` pada `Architecture.md` §4.2 | Ganti teks promosi menjadi "Mulai Rp 4.000" atau satukan tarif. Tarif ditampilkan dari `fareMatrix`, bukan teks tetap |
| T-12 | 18, 19 | Gambar 18 dan 19 identik. Panel Admin berupa layar mobile dengan fitur baru: Status Operasional Kampus (kill switch), Broadcast Darurat ke 1.420 mahasiswa, Matriks Subsidi | `PRD.md` M19 (admin di web), `tech.md` §2 (admin di Next.js) | Konfirmasi gambar 19 salah unggah. Putuskan admin mobile atau web. Broadcast memerlukan endpoint dan topik FCM serta kebijakan siapa yang boleh menyiarkan |
| T-13 | 7, 10, 16, 17, 18 | Data sensitif tampil penuh: NIM lengkap (17), NIM dan SIM calon driver (18), nama dan angkatan penumpang sebelum order diambil (10), posisi dan jarak driver standby ke merchant (16) | `Rules.md` §10, `security-checklist.md` §8 | Masker NIM (`1121****0045`), tampilkan dokumen hanya setelah admin membuka, tampilkan inisial penumpang sampai klaim berhasil, bulatkan jarak driver untuk merchant |
| T-14 | 1, 2, 3, 7, 13, 15, 17, 22, 24, 27 | Cacat tata letak: (a) logo gagal dimuat, alt text "Campus Express Logo" tampil (1, 2, 3); (b) judul app bar terpotong ("Live Tra…", "Cantee…") karena logo dan judul berbagi baris; (c) ticker terpotong di bawah kartu lokasi (3); (d) chip "Cepat Datang" menimpa teks (7); (e) satuan "6.4 m" tanpa kejelasan (menit), pemisah desimal titik (6); (f) harga pada CTA membungkus 2 baris dan ringkasan bawah terpotong "Gara…" (15); (g) label "Level 5" membungkus (15); (h) placeholder peta menampilkan ikon gambar rusak (13); (i) bintang ulasan berupa garis luar, tidak terisi (17); (j) "Radar auto-sync: 1d lalu" ambigu (10); (k) bintang rating terpilih tampil sebagai garis luar (24, 27); (l) harga opsi membungkus ("+Rp / 2.000") pada gambar 22 | Bagian A dan B | Perbaiki saat implementasi: `errorBuilder` pada logo, judul app bar tanpa logo, `Flexible`/`FittedBox` pada CTA, format `id-ID` (`6,4 mnt`), bintang terisi `star`, tulis "1 dtk lalu" |
| T-15 | 1, 12, 13, 14, 16, 20 | Data contoh tidak konsisten untuk order yang sama: kendaraan driver Bayu "Honda Beat Hijau AB 4921 KM" (1, 12) vs "Honda Vario B 4192 KTX" (20); penerima "Rizky Ramadhan" (13) vs "Rizal" (3, 6) vs "kak Rizky" (20); #CX-8845 milik "Warung Mbak Tri" (16) dan "Kantin Pusat B – Bu Siti" (14); rating dan jumlah trip Bayu dan Rizky sama (142 / 4.95) | — | Samakan data seed untuk mockup dan uji UI |
| T-16 | 14 | "Auto-refresh • 5s" pada pesanan aktif dapur | `Architecture.md` §9 (anggaran baca) | Implementasi memakai listener `snapshots()` pada order merchant, bukan polling 5 detik |
| T-17 | 1, 5, 6, 17 | Klaim yang mengikat bisnis: "Garansi Tepat Waktu Istirahat Kuliah — CampusSafe", "Potensi Rp 40rb – 80rb/hari" untuk driver, "0% Komisi Kampus" untuk UMKM, "Respons cepat BEM & Admin", "45+ Kantin Aktif", "28 Driver Aktif", "1.482 Trip" | `Bussiness.md` §9 (target pilot: 5 merchant, 10 driver) | Hapus atau ganti klaim dan angka yang belum didukung data nyata; angka di UI harus berasal dari `stats/campus` |
| T-18 | 4 | Footer "UIN Syarif Hidayatullah Smart Transit" dan "v2.4.0" | — | Ganti dengan nama kampus pilot yang sebenarnya dan versi build dari `package_info_plus` |
| T-19 | 27 | Perbandingan hemat tidak cocok dengan rumusnya: "Iuran Pemeliharaan BEM (0.5%)" bernilai Rp 500, padahal 0,5% × Rp 15.000 = Rp 75 (0,5% × Rp 19.500 = Rp 98). "Markup Resto 20%" menaikkan Rp 15.000 menjadi Rp 20.000 (33%; 20% hanya Rp 18.000). Landing menulis komisi 0.5%, sedangkan aplikasi menulis 5% (gambar 11, 18, 21, 23) | `Monetization.md` §2.3, T-02 | Hitung dari rumus di `Monetization.md`, beri label "ilustrasi/asumsi", samakan persentase komisi |
| T-20 | 27 | Klaim pada landing: "10.000+" pengguna, "50+" driver, "30+" mitra, "4.9/5 dari 10.000+ Mahasiswa", "Aktif UIN, UI, ITB, & UGM", "14 Fakultas", "#1", tiga testimoni dengan nama lengkap, "Latency 18ms" | `Bussiness.md` §4 dan §9 (satu kampus, pilot 10 driver dan 5 merchant), `PRD.md` §1.2 | Jangan publikasikan. Angka statistik diambil dari `stats/campus`; testimoni hanya dari pengguna nyata dengan izin; klaim kampus lain dihapus. Klaim yang tidak benar berisiko menyesatkan konsumen; tinjau dengan pihak berkompeten |
| T-21 | 27 | Distribusi: "Download APK (1.8 MB)", "download APK tanpa via Play Store", PWA Safari untuk iOS, aplikasi "hanya 1.2 MB" | `PRD.md` §10 (APK ≤ 40 MB; Flutter Android + iOS), `attack-surface.md` §2 (sideloading), `safe-change-rules.md` §4.2 (Play Store dan TestFlight) | Aplikasi Flutter dengan peta tidak mungkin berukuran 1,2–1,8 MB. Tentukan jalur distribusi (Play Store, APK langsung dengan checksum dan tanda tangan, atau PWA/Flutter Web) lalu perbarui teks, QR, dan ukuran |
| T-22 | 27 | Kartu "Chat Lobi Terenkripsi" | `Rules.md` §6.4 (chat tidak end-to-end) | Ganti menjadi "Chat dalam aplikasi" tanpa klaim enkripsi end-to-end |
| T-23 | 27 | Pill referral statis "Ajak 3 Teman Kuliah, Dapatkan Bebas Ongkir 100%!" tanpa pembuat tautan dan pelacak | `PRD.md` §8 komponen 1, `Rules.md` RF-1 dan RF-2 (reward non-tunai, setelah order pertama), `Monetization.md` D3 | Bebas ongkir 100% butuh sumber dana. Tentukan reward; tambahkan pembuat tautan dan penghitung bila Hero Referral Banner dipertahankan |
| T-24 | 21 | Registrasi driver: STNK sebagai dokumen ketiga; format "JPG, PNG (Maks 5MB)"; KTM berstatus "Terverifikasi" saat unggah; NIM tampil penuh; tiga persetujuan tanpa persetujuan pemrosesan data pribadi; langkah 1 dan 3 tidak ada; plat B 3481 KAA sama dengan calon driver lain pada gambar 18 | `Rules.md` BR-A2 dan §5 (WebP ≤ 80 KB), `PRD.md` M19, `security-checklist.md` §8 | Tambah persetujuan data pribadi (KTM, SIM, STNK) sebelum unggah; kompres di klien ke ≤ 80 KB; ubah status KTM menjadi "Menunggu verifikasi" sampai admin menyetujui; tambahkan STNK ke `driverProfiles.docs` dan aturan retensi; masker NIM |
| T-25 | 22 | Menu management menambah Kuota Masak Harian, alur Draf → Terbitkan, opsi bawaan, batas nama 50 karakter, "Maks 2MB", komisi stan 0% | `Architecture.md` §4.2 `merchantMenus` (tanpa kuota, status, opsi bawaan), `Rules.md` §5 (nama 2–60), `Monetization.md` D1 (0% sesuai) | Tambah `dailyQuota`, `status` (`draft`/`published`), `isDefault` pada opsi; samakan batas nama; foto tetap dikompres ke ≤ 80 KB |
| T-26 | 23 | "Server BEM (5%)" Rp 1.000, padahal 5% × Rp 25.000 = Rp 1.250; label yang sama muncul di checkout sebagai "Biaya Layanan & Pemeliharaan Loker" Rp 1.000. E-receipt berformat PDF. Layar konsumen memakai nav dan header merchant | `PRD.md` FR-17.2 (e-receipt dapat dibagikan sebagai gambar), T-06, T-10 | Satukan nama dan dasar biaya; tentukan PDF atau gambar (PDF memerlukan pembuat PDF di klien atau Gateway) |
| T-27 | 24 | Rating menambah tip driver (Rp 1.000–5.000), saldo "CXPay", poin XP, foto ulasan (+20 poin), batas komentar 300 karakter | `Rules.md` BR-T4 (tidak ada tip v1), `PRD.md` FR-16.1 (komentar ≤ 280), `Architecture.md` `reviews` (tanpa foto) | Putuskan tip dan poin masuk v1 atau tidak (keduanya melibatkan dana/biaya); samakan batas komentar; tambah `photoKey` bila foto ulasan dipakai |
| T-28 | 25 | Dispute: "refund otomatis masuk ke dompet digital", "dana pesanan ditahan hingga investigasi selesai", "respon < 15 menit", pelapor memilih penyelesaian, "Kirim Ulang Menu oleh Driver Lain", "Peringatan Etika & Mediasi BEM", tombol telepon ke Admin Posko | `Rules.md` BR-P5 (refund di luar aplikasi), DP-4 (respons pertama 24 jam, selesai 3 hari), `PRD.md` FR-18.2 | Samakan SLA atau tulis target yang bisa dipenuhi. Escrow dan refund otomatis mengikuti keputusan T-03. "Kirim ulang" memerlukan alur order baru dan sumber dana. Sanksi etika memerlukan kebijakan tertulis dari BEM/kampus |
| T-29 | 26 | Store settings: pencairan otomatis tiap 18.00 WIB, "QRIS Dinamis Merchant" (NMID), "Otomatis Buka Saat Kuliah Dimulai — sinkron presensi kelas", jadwal dua rentang (Jumat) dan Sabtu, badge "Mitra Halal BEM 2025" | `Architecture.md` §4.2 `merchants.schedule` (satu rentang), T-03, T-04 | Pencairan dan QRIS dinamis mengikuti T-03 dan T-04. Sinkron presensi kelas tidak punya sumber data; hapus atau definisikan. Ubah `schedule` menjadi array rentang per hari. Badge halal memerlukan proses dan dokumen verifikasi |
| T-30 | 23, 27 | Tanggal dan versi tertanam di mockup: "November 2024", "© 2025", "v2.4.0", "v2.4.0-LIGHT", "Versi Stabil 2.4.0 (Live)" | — | Ambil dari data dan build, bukan teks tetap |
| T-31 | 22, 23, 24, 25, 27 | Data contoh satu order tidak konsisten: menu "Ayam Geprek Sambal Matah Spesial" Rp 16.000 (22) vs "Ayam Geprek Sambal Korek" Rp 17.000 (23) vs "Ayam Geprek Spesial" (24); Level 3 + Kol Goreng dari harga 22 menjadi 16.000 + 1.000 + 2.000 = 19.000, bukan 17.000. Lokasi merchant yang sama ditulis "Stan #12 FST" (22), "Kantin Pusat B – Bu Siti (Stan 12)" (23), "Pujasera Barat" (24), dan pemilik "Bu Siti Maryam" memiliki "Kantin Rektorat" (27). Kronologi dispute menyebut "es teh manis" (25), sedangkan e-receipt #CX-8821 memuat "Es Kopi Susu Aren Kampus" (23) | T-15 | Samakan data seed. Harga e-receipt dihitung dari snapshot menu dan opsi saat checkout, bukan angka tetap |
| T-32 | 23, 24, 25 | Order #CX-8821 berstatus "Selesai & PIN Valid" dengan rating driver 5.0 (23), dan pada saat yang sama dipilih sebagai "Pesanan Bermasalah" pada Dispute Center (25). Tidak jelas apakah rating dan dispute boleh ada pada order yang sama | `Rules.md` BR-P5 dan DP-4, `PRD.md` FR-16.1 dan FR-18.2 | Putuskan aturan: rating dikunci atau tetap boleh diubah 24 jam setelah dispute dibuka; dispute dibuka sebelum atau sesudah rating; tampilkan "Lihat Kasus" bila sudah ada (state `sudah-ada-kasus`, C.22) |
| T-33 | 24, 25, 27, 11 | Nama saldo konsumen tidak konsisten: "CXPay" dan "e-wallet" (24), "Saldo KampusPay" (25), "Dompet Kampus" (27), "Saldo Dompet" (11), "Saldo KTM Tap" (T-03) | T-03 | Tentukan satu nama produk saldo (atau hapus bila T-03 tidak diambil) dan pakai di semua layar, e-receipt, dan landing |
| T-34 | 26, 12, 23 | Preferensi layanan menulis "Rider mahasiswa mengantar langsung ke ruang kelas", sedangkan layar tracking dan e-receipt memakai serah terima di Lobi/Dropzone dengan PIN 4 digit (12, 23) | `PRD.md` §5 dan FR-09, `Rules.md` (serah terima) | Ubah teks menjadi "mengantar ke titik serah terima pilihan pembeli (lobi/dropzone)", atau definisikan titik antar ruang kelas lengkap dengan verifikasi PIN dan batas akses gedung |
| T-35 | 26, 27, 23 | Nama pemilik tidak konsisten: rekening a/n "Siti Aminah" (26), testimoni "Bu Siti Maryam, Pemilik Kantin Rektorat" (27), stan "Kantin Bu Siti" di FST (22, 23, 26). Nama stan resmi pada form ("Kantin Bu Siti - Spesialis Geprek & Soto") juga berbeda dengan strip identitas ("Kantin Bu Siti"). Rekening pribadi dipakai sebagai "Rekening Operasional Stan" | T-31, `security-checklist.md` §8 | Samakan data seed. Verifikasi bahwa nama pemilik rekening cocok dengan data merchant sebelum rekening diaktifkan (state `verifikasi-rekening`, C.21). Strip identitas mengambil nama dari field resmi, bukan teks terpisah |

### F.1 Layar dan State yang Masih Belum Ada Mockup

Semua 22 layar PRD dan Web Landing Page sudah memiliki mockup. Yang belum terlihat:

| Item | Keterangan |
|---|---|
| Registrasi Driver langkah 1 dan 3 | Gambar 21 hanya menampilkan langkah 2 dari 3. Perlu: langkah 1 (identitas dan kendaraan) dan langkah 3 (status verifikasi) |
| Tab `Products` (daftar menu) dan mode edit | Gambar 22 menampilkan formulir mode tambah; daftar menu merchant dan formulir edit belum ada |
| Tab `Orders` > Berjalan | Tab "Berjalan (1)" pada gambar 23 tidak ditampilkan |
| Tab `Support` | Hanya Dispute Center (gambar 25) yang terlihat; daftar kasus dan detail kasus belum ada |
| Notifikasi | Ikon bel muncul di app bar tetapi layar daftar notifikasi tidak ada |
| Layar sukses | Setelah kirim rating, kirim dokumen driver, kirim dispute, terbitkan menu |
| Landing di layar kecil | Gambar 27 hanya viewport desktop; susunan responsif pada C.23 adalah usulan |
| Semua state kosong, loading, galat, offline | Hanya sebagian terlihat pada mockup; gunakan pola di C.0 |
| Layar blokir akun | State `suspended` (`PRD.md` AC-01.3) |