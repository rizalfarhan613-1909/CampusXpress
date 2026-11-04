# PRD — Campus Express (Go-Campus)

| Atribut | Nilai |
|---|---|
| Versi dokumen | 1.0 |
| Status | Draft untuk review tim |
| Platform | Flutter (Android/iOS), Next.js (Landing, Merchant Web, Admin), Firebase, Cloudflare R2 + Workers |
| Target awal | 10.000 MAU di satu ekosistem kampus |
| Komisi | 0,5% per transaksi (`commissionBps = 50`) |
| Target biaya infrastruktur | Rp 0/bulan pada fase pilot; lihat catatan kuota di `Architecture.md` §9 |

---

## 1. Ringkasan Produk

Campus Express adalah platform layanan hiper-lokal kampus dengan empat layanan dalam satu aplikasi:

| Kode | Layanan | Deskripsi |
|---|---|---|
| `numpang` | Numpang Kampus | Tumpangan motor antar landmark kampus dengan tarif tetap per zona |
| `jastip` | Jastip Makanan | Driver membelikan makanan dari kantin/kedai mana pun di sekitar kampus |
| `paket` | Kirim Paket | Antar barang/dokumen antar-titik dalam kampus (maks. 5 kg) |
| `umkm` | Katalog UMKM | Pesan dari merchant terdaftar dengan menu, opsi kustom, dan jam buka |

### 1.1 Masalah

1. Pemesanan berjalan di grup WhatsApp (800+ anggota): pesan tenggelam, tidak ada status, tidak ada bukti transaksi, dan sengketa sulit diselesaikan.
2. Driver dan UMKM kampus tidak punya kanal digital murah; aplikasi besar memungut komisi tinggi dan tidak menjangkau lorong kampus.
3. Konsumen tidak tahu posisi dan estimasi tiba pesanan.

### 1.2 Tujuan

| ID | Tujuan | Indikator keberhasilan (90 hari setelah peluncuran) |
|---|---|---|
| G1 | Memindahkan pemesanan dari WhatsApp ke aplikasi | ≥ 70% order jastip/numpang tercatat di aplikasi |
| G2 | Transaksi aman dan dapat diaudit | Dispute rate < 3% dari order selesai |
| G3 | Biaya operasional minimal | Biaya infrastruktur bulanan Rp 0 pada pilot; terukur dan terbatas setelahnya |
| G4 | Kepercayaan lewat transparansi | ≥ 85% order memakai tracking; median selisih ETA vs aktual ≤ 4 menit |
| G5 | Adopsi | 10.000 MAU, 150 driver aktif, 40 merchant aktif |

### 1.3 Bukan Tujuan (v1)

- Pembayaran in-app otomatis (payment gateway). Pembayaran v1 hanya COD tunai atau QRIS statis dengan bukti unggah.
- Pelacakan GPS kontinu. v1 memakai pelacakan berbasis checkpoint landmark.
- Layanan di luar area kampus.
- Enkripsi end-to-end pada chat (lihat `Rules.md` §6 untuk alasannya).

---

## 2. Persona

| Persona | Peran | Kebutuhan utama | Hambatan |
|---|---|---|---|
| Rani, mahasiswi semester 3 | Konsumen | Pesan cepat, tahu kapan tiba, aman | Takut pesanan salah/hilang |
| Dimas, mahasiswa driver | Driver | Order masuk jelas, rebutan adil, komisi kecil | Uang talangan, order dibatalkan sepihak |
| Bu Siti, pemilik kantin | Merchant UMKM | Etalase digital, order rapi, tanpa potongan besar | Gaptek, tidak mau layar rumit |
| Kak Nadia, admin organisasi | Admin | Verifikasi driver/merchant, tangani sengketa | Beban manual, bukti terserak |

---

## 3. Aturan Lintas-Fitur

| Kode | Aturan |
|---|---|
| X1 | Semua nilai uang disimpan sebagai integer Rupiah (tanpa desimal). |
| X2 | Komisi = `max(50, round_half_up(total × 0,005))` dalam Rupiah; `total` = subtotal + ongkir. |
| X3 | Ongkir/tarif ditentukan oleh matriks zona dan tidak bisa diubah klien. |
| X4 | Identitas pengguna terverifikasi lewat Google SSO domain `@mhs.uin.ac.id` dan NIM. |
| X5 | Semua transisi status order mengikuti mesin status di `Architecture.md` §5. |
| X6 | Gambar dikompresi di klien ke WebP ≤ 80 KB sebelum unggah. |

---

## 4. Daftar 20 Modul

Notasi: **FR** = kebutuhan fungsional, **AC** = kriteria penerimaan (Given/When/Then dipadatkan).

### M01 — Autentikasi & Identitas

| ID | Kebutuhan |
|---|---|
| FR-01.1 | Login hanya dengan Google SSO; akun dengan email di luar `@mhs.uin.ac.id` ditolak. |
| FR-01.2 | Setelah login pertama, pengguna wajib mengisi NIM dan nomor WhatsApp. |
| FR-01.3 | NIM divalidasi dengan pola yang dapat dikonfigurasi (`config/app.nimPattern`) dan harus unik. |
| FR-01.4 | Sesi dapat dicabut oleh admin (suspend). |

| AC | Kriteria |
|---|---|
| AC-01.1 | Given email `@gmail.com`, When login, Then ditolak dengan pesan "Gunakan akun @mhs.uin.ac.id" dan sesi Firebase dihapus. |
| AC-01.2 | Given NIM sudah dipakai akun lain, When submit, Then muncul error "NIM sudah terdaftar" tanpa membocorkan pemilik. |
| AC-01.3 | Given akun suspended, When membuka aplikasi, Then diarahkan ke layar blokir dengan tautan Help Desk. |

### M02 — Peran & Onboarding

| ID | Kebutuhan |
|---|---|
| FR-02.1 | Pengguna dapat memegang beberapa peran: `consumer` (default), `driver`, `merchant`. Peran `admin` hanya via custom claim. |
| FR-02.2 | Layar onboarding menjelaskan nilai tiap peran dengan Word Rotator. |
| FR-02.3 | Mendaftar sebagai driver/merchant memicu alur verifikasi (M19). |

| AC | Kriteria |
|---|---|
| AC-02.1 | Given pengguna baru, When memilih "Saya Konsumen", Then masuk Home tanpa verifikasi tambahan. |
| AC-02.2 | Given pengguna memilih "Jadi Driver", When belum lengkap dokumen, Then status `pending_docs` dan fitur klaim order terkunci. |

### M03 — Landmark & Zona

| ID | Kebutuhan |
|---|---|
| FR-03.1 | Admin mengelola landmark (nama, koordinat, tipe, zona) dan graf jalur antar-landmark. |
| FR-03.2 | Konsumen memilih titik jemput/antar dari landmark preset, bukan alamat bebas. |
| FR-03.3 | Tarif dihitung dari matriks zona asal-tujuan. |
| FR-03.4 | Catatan lokasi bebas (maks. 140 karakter) untuk detail, mis. "lantai 2 ruang 204". |

| AC | Kriteria |
|---|---|
| AC-03.1 | Given asal = tujuan, When konfirmasi, Then ditolak. |
| AC-03.2 | Given landmark nonaktif, When picker dibuka, Then tidak ditampilkan. |

### M04 — Katalog Merchant & Daftar Makanan

| ID | Kebutuhan |
|---|---|
| FR-04.1 | Daftar merchant dengan status Buka/Tutup, estimasi persiapan, dan landmark. |
| FR-04.2 | Pencarian menu dan filter kategori dilakukan di klien dari data yang sudah di-cache. |
| FR-04.3 | Merchant tutup tidak dapat dipesan namun tetap tampil dengan label. |

| AC | Kriteria |
|---|---|
| AC-04.1 | Given merchant menekan Tutup Toko, When konsumen membuka katalog, Then tombol pesan nonaktif maksimal 5 detik kemudian. |
| AC-04.2 | Given katalog termuat, When offline, Then daftar tetap tampil dari cache dengan penanda "data tersimpan". |

### M05 — Kustomisasi Menu & Keranjang

| ID | Kebutuhan |
|---|---|
| FR-05.1 | Menu memiliki grup opsi (wajib/opsional, maks. pilihan, `priceDelta`). |
| FR-05.2 | Keranjang hanya berisi item dari satu merchant. |
| FR-05.3 | Widget Price Roll menampilkan perbandingan biaya komisi vs asumsi aplikasi besar. |

| AC | Kriteria |
|---|---|
| AC-05.1 | Given grup opsi wajib belum dipilih, When Tambah, Then tombol nonaktif dan grup ditandai. |
| AC-05.2 | Given item dari merchant lain, When ditambah, Then dialog konfirmasi kosongkan keranjang. |

### M06 — Checkout & Pembayaran

| ID | Kebutuhan |
|---|---|
| FR-06.1 | Metode: `COD` (tunai ke driver/merchant) atau `QRIS_STATIC` (bayar ke QRIS statis penerima, unggah bukti). |
| FR-06.2 | Ringkasan: subtotal, ongkir, total, estimasi ETA. Komisi tidak dibebankan ke konsumen. |
| FR-06.3 | Batas nilai COD Rp 200.000; di atas itu wajib QRIS. |
| FR-06.4 | Penerima (driver/merchant) mengonfirmasi pembayaran QRIS diterima. |

| AC | Kriteria |
|---|---|
| AC-06.1 | Given QRIS dipilih, When bukti belum diunggah, Then tombol "Pesan" nonaktif. |
| AC-06.2 | Given total Rp 250.000 dan COD, When checkout, Then COD disabled dengan alasan. |
| AC-06.3 | Given order dibuat, When tersimpan, Then `pricing.total` dihitung ulang oleh server dan bernilai sama dengan tampilan klien. |

### M07 — Mesin Order & Notifikasi

| ID | Kebutuhan |
|---|---|
| FR-07.1 | Order melewati status: `PLACED → ACCEPTED → READY → AWAITING_DRIVER → CLAIMED → AT_PICKUP → ON_DELIVERY → ARRIVED → COMPLETED` (varian per layanan di Architecture §5). |
| FR-07.2 | Setiap transisi menulis event audit. |
| FR-07.3 | Notifikasi FCM pada: order diterima, driver klaim, driver tiba, pesan baru, selesai. |
| FR-07.4 | Timeout otomatis: merchant 5 menit, klaim driver 10 menit. |

| AC | Kriteria |
|---|---|
| AC-07.1 | Given merchant tidak merespons 5 menit, Then order `EXPIRED` dan konsumen diberi tahu. |
| AC-07.2 | Given transisi ilegal (mis. `PLACED → COMPLETED`), Then ditolak oleh rules/gateway. |

### M08 — Radar Order Driver & Klaim 1-Klik

| ID | Kebutuhan |
|---|---|
| FR-08.1 | Radar menampilkan order `AWAITING_DRIVER` realtime, urut terbaru, dengan asal, tujuan, tarif, ETA, komisi. |
| FR-08.2 | Klaim dijamin atomik: hanya satu driver yang berhasil. |
| FR-08.3 | Driver hanya dapat klaim jika saldo ≥ ambang (Rp 5.000) dan klaim aktif < 2. |

| AC | Kriteria |
|---|---|
| AC-08.1 | Given dua driver menekan Klaim bersamaan, Then satu sukses dan satu menerima "Order sudah diambil". |
| AC-08.2 | Given saldo Rp 3.000, When Klaim, Then ditolak dengan tombol "Top-Up". |

### M09 — Pekerjaan Aktif Driver & PIN Serah-Terima

| ID | Kebutuhan |
|---|---|
| FR-09.1 | Driver menandai checkpoint: tiba di titik jemput, mulai antar, tiba di tujuan. |
| FR-09.2 | Serah-terima ditutup dengan PIN 4 digit yang ditampilkan di layar konsumen dan diketik driver. |
| FR-09.3 | Maksimal 5 percobaan PIN salah, kunci 10 menit, lalu eskalasi ke Help Desk. |
| FR-09.4 | Pintasan WhatsApp hanya aktif sebagai fallback darurat (chat in-app tidak merespons ≥ 3 menit atau fitur chat error). |

| AC | Kriteria |
|---|---|
| AC-09.1 | Given PIN benar, Then status `COMPLETED`, komisi dipotong dari wallet, e-receipt dibuat. |
| AC-09.2 | Given 5 PIN salah, Then input terkunci 10 menit dan event `PIN_LOCKED` tercatat. |

### M10 — Pelacakan Peta 3D Isometrik

| ID | Kebutuhan |
|---|---|
| FR-10.1 | Peta isometrik 3D kampus: bangunan ekstrusi, jalur, landmark, marker kendaraan. |
| FR-10.2 | Posisi driver dianimasikan dengan interpolasi sepanjang segmen jalur antar-landmark. |
| FR-10.3 | Fallback 2D Canvas untuk perangkat low-end atau error WebGL. |
| FR-10.4 | Tidak ada pemanggilan API peta berbayar. |

| AC | Kriteria |
|---|---|
| AC-10.1 | Given checkpoint baru, Then marker bergerak mulus (≥ 30 fps pada perangkat target) ke segmen berikutnya tanpa lompat. |
| AC-10.2 | Given RAM ≤ 3 GB atau WebGL gagal, Then mode 2D aktif otomatis dan dapat dipaksa dari pengaturan. |

### M11 — Kalkulator ETA Dinamis

| ID | Kebutuhan |
|---|---|
| FR-11.1 | ETA = waktu tempuh jalur terpendek pada graf landmark pada kecepatan rata-rata 20 km/jam + buffer penyiapan pesanan. |
| FR-11.2 | ETA dihitung ulang saat checkpoint dan ketika merchant mengubah estimasi persiapan. |
| FR-11.3 | Kecepatan rata-rata dikoreksi oleh kecepatan teramati dengan batas 10–30 km/jam. |

| AC | Kriteria |
|---|---|
| AC-11.1 | Given jarak jalur 1.200 m dan tanpa buffer, Then ETA = 1.200 / 5,556 ≈ 216 detik (±1 detik). |
| AC-11.2 | Given order jastip tanpa merchant, Then buffer default 8 menit. |

### M12 — Chat Realtime In-App

| ID | Kebutuhan |
|---|---|
| FR-12.1 | Satu ruang chat per order, partisipan sesuai peran (konsumen-merchant, konsumen-driver). |
| FR-12.2 | Pesan teks, gambar WebP ≤ 80 KB, dan Quick Chips. |
| FR-12.3 | Moderasi: filter kata, laporan, blokir, batas laju. |
| FR-12.4 | Ruang menjadi read-only 24 jam setelah order selesai dan pesan kedaluwarsa 30 hari (TTL). |

| AC | Kriteria |
|---|---|
| AC-12.1 | Given pengguna bukan partisipan, When membaca ruang, Then ditolak oleh rules. |
| AC-12.2 | Given nomor telepon diketik di chat, Then pesan dikirim dengan penanda peringatan privasi (tidak diblokir, supaya fallback tetap berfungsi). |

### M13 — Dompet Deposit Driver (Prepaid)

| ID | Kebutuhan |
|---|---|
| FR-13.1 | Driver top-up via QRIS statis admin + unggah bukti; admin menyetujui. |
| FR-13.2 | Komisi dipotong saat order `COMPLETED`; ledger tidak dapat diubah. |
| FR-13.3 | Notifikasi saldo rendah < Rp 10.000. |
| FR-13.4 | Saldo tidak boleh negatif. |

| AC | Kriteria |
|---|---|
| AC-13.1 | Given top-up Rp 20.000 disetujui, Then saldo bertambah Rp 20.000 dan satu baris `walletTx` bertipe `topup`. |
| AC-13.2 | Given order total Rp 30.000, Then komisi Rp 150 dipotong tepat satu kali meski permintaan selesai dikirim ulang (idempoten). |

### M14 — Operasional Merchant

| ID | Kebutuhan |
|---|---|
| FR-14.1 | Toggle Buka/Tutup toko dan jam operasional otomatis. |
| FR-14.2 | Daftar order masuk dengan Terima/Tolak dan estimasi persiapan. |
| FR-14.3 | Dispatcher: tandai `READY`, pilih antar driver atau ambil sendiri. |

| AC | Kriteria |
|---|---|
| AC-14.1 | Given order baru, Then bunyi dan getar muncul di perangkat merchant yang terbuka. |

### M15 — Manajemen Menu & Pengaturan Toko

| ID | Kebutuhan |
|---|---|
| FR-15.1 | CRUD produk dengan foto, harga, kategori, ketersediaan, grup opsi. |
| FR-15.2 | Pengaturan profil toko, QRIS statis, rekening payout, jam buka. |
| FR-15.3 | Maksimal 150 produk per merchant pada v1. |

| AC | Kriteria |
|---|---|
| AC-15.1 | Given foto > 80 KB setelah kompresi maksimal, Then unggah ditolak dengan saran ukuran. |

### M16 — Rating & Ulasan

| ID | Kebutuhan |
|---|---|
| FR-16.1 | Konsumen menilai driver dan merchant 1–5 plus komentar ≤ 280 karakter setelah `COMPLETED`. |
| FR-16.2 | Satu ulasan per order, dapat diedit 24 jam. |
| FR-16.3 | Agregat rating dihitung server. |

### M17 — Riwayat Order & E-Receipt

| ID | Kebutuhan |
|---|---|
| FR-17.1 | Riwayat paginasi 20 item. |
| FR-17.2 | E-receipt memuat rincian harga, driver, waktu, ID order; dapat dibagikan sebagai gambar. |

### M18 — Dispute & Safety

| ID | Kebutuhan |
|---|---|
| FR-18.1 | Konsumen/driver/merchant dapat membuka dispute dengan kategori dan bukti. |
| FR-18.2 | Tombol Darurat menampilkan kontak keamanan kampus yang dikonfigurasi admin. |
| FR-18.3 | SLA tanggapan admin 24 jam. |

### M19 — Panel Admin & Persetujuan

| ID | Kebutuhan |
|---|---|
| FR-19.1 | Antrean verifikasi driver (KTM/SIM) dan merchant. |
| FR-19.2 | Persetujuan top-up wallet dengan dua langkah untuk nominal ≥ Rp 200.000. |
| FR-19.3 | Manajemen landmark, zona, tarif, dan konfigurasi. |
| FR-19.4 | Moderasi: suspend, strike, tinjau laporan chat. |
| FR-19.5 | Setiap aksi admin tercatat di `auditLogs`. |

### M20 — Landing Page & Pertumbuhan

| ID | Kebutuhan |
|---|---|
| FR-20.1 | Landing Page Next.js 15 statis dengan 9 komponen interaktif (§8). |
| FR-20.2 | Tautan referral per pengguna dan pelacak reward. |
| FR-20.3 | Data publik (Sales Pings, statistik) dilayani lewat endpoint ter-cache agar hemat kuota baca. |

---

## 5. Spesifikasi Peta 3D & ETA

### 5.1 Model Data Peta

| Elemen | Sumber | Format |
|---|---|---|
| Bangunan | Digambar manual dari citra satelit kampus | GeoJSON polygon + properti `height_m`, `name` |
| Jalur | Ditelusuri manual | GeoJSON LineString, tiap garis = satu edge graf |
| Landmark | Dikelola admin | Dokumen `landmarks/{id}` |
| Graf | Dihitung dari edge | `config/landmarkGraph` (satu dokumen) |
| Aset | Cloudflare R2 | `campus-map.geojson`, sprite kendaraan PNG |

Tidak ada tile server eksternal: gaya peta dirakit dari GeoJSON sendiri sehingga biaya nol dan tampilan dapat disesuaikan dengan tema emerald.

### 5.2 Rumus ETA

```
v        = avgSpeedKmh / 3,6                      (m/s; 20 km/jam = 5,556 m/s)
tempuh   = Σ jarak edge pada jalur terpendek / v  (detik)
buffer   = max(0, prepReadyAt − sekarang)         (untuk umkm)
         = defaultPrepBufferSec                   (jastip: 480; paket: 120; numpang: 0)
ETA      = sekarang + tempuh(driver → jemput) + buffer_sisa + tempuh(jemput → antar)
```

Kecepatan terkoreksi setelah tiap segmen: `v ← clamp(0,7·v + 0,3·v_obs, 2,78, 8,33)` (10–30 km/jam).

### 5.3 Animasi

Progres pada segmen aktif: `p = clamp((t − t_checkpoint) / durasi_segmen, 0, 0,95)`. Marker berhenti di 95% sampai checkpoint berikutnya sehingga tidak melewati landmark sebelum dikonfirmasi driver.

### 5.4 Mode Render

| Kondisi | Mode |
|---|---|
| RAM ≥ 4 GB dan WebGL tersedia | 3D isometrik (pitch 60°, bearing 45°) |
| RAM < 4 GB atau FPS < 24 selama 3 detik | 2D Canvas polyline |
| Pengguna menyalakan "Hemat data/baterai" | 2D Canvas |

---

## 6. Spesifikasi In-App Chat

| Aspek | Spesifikasi |
|---|---|
| Ruang | `chats/{orderId}`, dibuat saat order `PLACED` (konsumen-merchant) dan diperluas saat `CLAIMED` (konsumen-driver) |
| Jenis pesan | `text`, `chip`, `image`, `system` |
| Quick Chips konsumen | "Saya sudah di titik", "Tolong tunggu 2 menit", "Pesanan sudah benar?" |
| Quick Chips driver | "Saya sudah tiba", "Sedang antre di kedai", "Titik ini sulit, boleh pindah?" |
| Batas | 20 pesan/menit/pengguna, 500 karakter/pesan, gambar ≤ 80 KB |
| Status | terkirim (`createdAt` server), dibaca (`readBy` per partisipan, ditulis maksimal sekali per sesi buka) |
| Penutupan | Read-only 24 jam setelah selesai; TTL 30 hari |
| Moderasi | Daftar kata terlarang, laporan pesan, blokir per pengguna, tinjauan admin pada dispute |

---

## 7. Fase Rilis

| Fase | Cakupan | Kriteria keluar |
|---|---|---|
| Alpha (4 minggu) | M01–M07, M12, 15 pengguna uji | Order end-to-end tanpa error kritis |
| Pilot tertutup (4 minggu) | + M08–M11, M13, M14, 10 driver, 5 merchant | 100 order sukses, dispute < 5% |
| Pilot terbuka | + M15–M19, anggota grup WhatsApp diundang bertahap | 1.000 MAU, kuota Firestore < 70% |
| Skala | + M20 kampanye penuh, evaluasi Blaze | 10.000 MAU |

---

## 8. Spesifikasi Landing Page

Arsitektur: Next.js 15 (static export), Tailwind CSS, Framer Motion. Di-host gratis di Cloudflare Pages atau Firebase Hosting.

| # | Komponen | Perilaku | Sumber data | Kriteria penerimaan |
|---|---|---|---|---|
| 1 | Hero Referral Banner | Login Google lalu menghasilkan tautan `/r/{kode}`; tampil jumlah undangan yang berhasil | `referrals/{kode}` via Gateway | Kode unik 6 karakter; salin tautan satu klik |
| 2 | Word Rotator Header | Ganti kata: "Numpang / Jastip / Kirim / Jajan" tiap 2,4 detik | statis | Tidak memicu layout shift; hormati `prefers-reduced-motion` |
| 3 | Sales Pings Engine | Toast anonim "Seseorang di Gedung Rektorat memesan Nasi Goreng" | `GET /public/pings` (cache edge 30 dtk) | Tidak memuat identitas pengguna; polling 30 detik; maks. 1 toast / 6 detik |
| 4 | Count-Up Stats | Hitung naik saat terlihat | `GET /public/stats` | Animasi sekali per kunjungan lewat IntersectionObserver |
| 5 | Bento Build Showcase | Grid fitur Konsumen/Driver/Merchant | statis | Responsif 1/2/4 kolom |
| 6 | Process Draw SVG Timeline | Garis SVG tergambar bertahap saat scroll | statis | Jalur digambar dengan `pathLength` 0→1 |
| 7 | Price Roll Calculator | Slider nilai order; angka berputar | statis | Penghematan = nilai × (asumsi_besar − 0,005); asumsi 20% dapat dikonfigurasi dan diberi label "asumsi" |
| 8 | Cursor Tour Preview | Hotspot tooltip pada mockup layar | statis | Navigasi keyboard dan sentuh |
| 9 | Review Shuffle Carousel | Kartu bertumpuk bergeser seperti Tinder | `GET /public/reviews` (opsional) | Dapat digeser sentuh dan tombol panah |

---

## 9. Peta 22 Layar Mobile

Legenda modul: M## merujuk bagian 4. Widget dalam kurung adalah komponen landing/UI interaktif yang dipakai ulang.

| # | Layar | Peran | Modul | Komponen & Data Kunci | Status/State Wajib | Aksi Utama |
|---|---|---|---|---|---|---|
| 1 | Onboarding & Role Selector | Semua | M02 | [Word Rotator], 3 kartu peran | Pertama kali / ulang | Pilih peran |
| 2 | Auth Google SSO & Validasi NIM | Semua | M01 | Tombol Google, form NIM, WA | Loading, domain salah, NIM duplikat | Masuk, simpan profil |
| 3 | Consumer Home Bento Dashboard | Konsumen | M04, M20 | Grid bento: 4 layanan, order aktif, [Sales Pings], [Count-Up Stats] | Kosong, order aktif, offline | Pilih layanan |
| 4 | Landmark & Zone Picker Modal | Konsumen, Driver | M03 | Pencarian landmark, mini-peta, daftar zona | Tanpa hasil | Pilih titik |
| 5 | Merchant Catalog & Food List | Konsumen | M04 | Kartu merchant, status buka, kategori | Tutup, kosong, error | Buka merchant |
| 6 | Menu Customizer | Konsumen | M05 | Grup opsi, jumlah, catatan, [Price Roll Calculator] | Opsi wajib belum dipilih | Tambah ke keranjang |
| 7 | Cart & Checkout | Konsumen | M06 | Ringkasan harga, metode COD/QRIS, unggah bukti | Batas COD, bukti belum ada | Pesan |
| 8 | Live 3D Map Tracking & ETA | Konsumen | M09–M11 | Peta 3D/2D, ETA, status stepper [Process Draw], PIN 4 digit | Menunggu driver, bergerak, tiba | Buka chat, bagikan PIN |
| 9 | Driver Order Radar | Driver | M08 | Daftar order realtime, tombol Klaim, saldo | Offline, saldo rendah, tidak ada order | Klaim |
| 10 | Driver Active Job & Navigation | Driver | M09 | Checkpoint stepper, input PIN, pintasan WA darurat | PIN terkunci | Konfirmasi checkpoint, selesai |
| 11 | Driver Prepaid Wallet & Top-Up | Driver | M13 | Saldo, riwayat, modal top-up QRIS | Menunggu persetujuan, ditolak | Top-up |
| 12 | Merchant Operational Dashboard | Merchant | M14 | Toggle Buka/Tutup, ringkasan hari ini | Tutup otomatis, offline | Buka/Tutup |
| 13 | Merchant Incoming Order & Dispatcher | Merchant | M14 | Daftar order, Terima/Tolak, set persiapan, tandai Siap | Timeout, baru | Terima, Siap |
| 14 | User Profile & Review Shuffle | Semua | M16 | Profil, rating, [Review Shuffle Stack] | Belum ada ulasan | Edit profil |
| 15 | Admin Zone & Approval Panel | Admin | M19 | Antrean verifikasi, top-up, konfigurasi | Antrean kosong | Setujui/Tolak |
| 16 | In-App Live Chat | Konsumen, Driver, Merchant | M12 | Daftar pesan, Quick Chips, kirim gambar | Read-only, diblokir, offline | Kirim, laporkan |
| 17 | UMKM Menu Management & Add/Edit Product | Merchant | M15 | Daftar produk, form produk, grup opsi, foto | Batas 150 produk | Simpan |
| 18 | Order History & Digital E-Receipt | Konsumen, Driver, Merchant | M17 | Daftar paginasi, detail struk | Kosong | Bagikan struk |
| 19 | Post-Order Rating & Review | Konsumen | M16 | Bintang, komentar, tag cepat | Sudah dinilai | Kirim ulasan |
| 20 | Driver Registration & Document Upload | Driver | M02, M19 | Unggah KTM, SIM, data kendaraan, persetujuan data pribadi | Menunggu, ditolak + alasan | Kirim pengajuan |
| 21 | UMKM Store Settings & Payout Profile | Merchant | M15 | Profil toko, jam buka, QRIS statis, rekening | Validasi gagal | Simpan |
| 22 | Dispute Center & Safety Help Desk | Semua | M18 | Buat dispute, unggah bukti, tombol darurat, status kasus | Terbuka, diproses, selesai | Ajukan, eskalasi |

### 9.1 Kriteria Penerimaan Lintas-Layar

| Kode | Kriteria |
|---|---|
| UX-1 | Setiap layar memiliki state kosong, loading (skeleton), dan error dengan tombol coba lagi. |
| UX-2 | Kontras teks minimal WCAG AA terhadap latar emerald gelap. |
| UX-3 | Target sentuh minimal 44×44 dp. |
| UX-4 | Semua teks bahasa Indonesia melalui berkas lokalisasi, siap ditambah bahasa lain. |
| UX-5 | Layar 8 dan 10 tetap berfungsi pada koneksi 3G (data teks, gambar tertunda). |

### 9.2 Token Desain

| Token | Nilai | Pemakaian |
|---|---|---|
| `emerald-500` | `#059669` | Aksi utama, aksen |
| `emerald-600` | `#047857` | Hover/pressed, header kartu |
| `emerald-900` | `#064E3B` | Latar permukaan tinggi |
| Latar dasar | `#04130E` | Latar aplikasi |
| Teks utama | `#ECFDF5` | Teks pada latar gelap |
| Radius bento | 20 dp | Kartu bento |
| Jarak grid | 12 dp | Antar kartu |

---

## 10. Kebutuhan Non-Fungsional

| Kategori | Target |
|---|---|
| Performa | Cold start ≤ 3 dtk pada Android 8 / RAM 3 GB; render layar ≤ 100 ms setelah data tersedia |
| Ukuran | APK ≤ 40 MB |
| Realtime | Pesan chat terlihat penerima ≤ 2 dtk pada jaringan 4G |
| Ketersediaan | Mengikuti SLA layanan Firebase/Cloudflare; mode degradasi saat Gateway down (tampilkan banner, order baru ditunda) |
| Offline | Katalog dan riwayat terbaca offline; aksi tulis kritis memerlukan koneksi |
| Keamanan | Lihat `Security/security-checklist.md` |
| Privasi | Mengikuti UU Pelindungan Data Pribadi (UU No. 27 Tahun 2022); data KTM/SIM dibatasi akses dan retensi |
| Aksesibilitas | Dukungan pembaca layar dasar, skala font 200% |

## 11. Risiko Produk

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Kuota gratis Firebase habis | Aplikasi berhenti | Anggaran kuota per fitur, cache agresif, peringatan 70%, rencana Blaze (Architecture §9) |
| Driver enggan top-up | Pasokan driver turun | Komisi sangat kecil, ambang rendah, onboarding jelas |
| Bukti QRIS palsu | Kerugian penerima | Konfirmasi penerima wajib, strike, dispute |
| Pendapatan 0,5% tidak menutup biaya | Keberlanjutan | Lihat `Bussiness.md` dan `Monetization.md` |