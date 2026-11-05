# Bussiness — Strategi Bisnis Campus Express

> Catatan: angka kompetitor (komisi, ongkir, cakupan) pada dokumen ini adalah asumsi kerja dan harus diverifikasi dari sumber resmi terbaru sebelum dipakai dalam materi publik. Angka proyeksi adalah skenario, bukan prediksi.

## 1. Ringkasan Peluang

| Aspek | Isi |
|---|---|
| Titik awal | Grup WhatsApp 800+ anggota yang sudah menjadi pasar nyata untuk jastip dan tumpangan (Kampus IV UINSU Tuntungan & sekitarnya) |
| Proposisi nilai | Pemesanan terstruktur, sistem penawaran harga transparan (Reverse Auction / Bidding Model), estimasi jarak riil OSRM, komisi $0.5\%$, khusus kampus |
| Keunggulan lokal | Peta landmark & koridor kampus, kenal komunitas, PIN serah-terima, chat dalam aplikasi, pencocokan driver searah |
| Risiko utama | Pendapatan per transaksi sangat kecil; ketergantungan pada pasokan driver lokal |

## 2. Segmentasi dan Kebutuhan

| Segmen | Ukuran awal (asumsi) | Masalah | Nilai Campus Express |
|---|---|---|---|
| Mahasiswa konsumen | Seluruh mahasiswa kampus pilot (UINSU Tuntungan & koridor Simpang Tuntungan); 800+ sudah di grup WA | Pesan tenggelam di grup, tidak ada status, harga monopoli/kaku | Order terstruktur, bebas memilih penawaran driver (bidding), tracking, riwayat |
| Mahasiswa driver | Puluhan hingga ratusan | Penghasilan tidak tercatat, komisi platform besar mahal | Fleksibilitas menentukan tarif bid, order jelas, komisi platform hanya $0.5\%$, bukti serah-terima |
| UMKM kampus | Kantin, kedai, laundry, fotokopi sekitar kampus | Tidak punya kanal digital murah | Etalase gratis, order tertata |
| Pihak kampus | Organisasi mahasiswa, BEM, pengelola | Ingin ekosistem aman dan mandiri | Moderasi, laporan, kontrol |

## 3. Analisis Kompetitor

### 3.1 Perbandingan dengan Platform Besar (Gojek/Grab/InDrive)

| Dimensi | Platform besar | Campus Express | Implikasi |
|---|---|---|---|
| Komisi dari mitra | Umumnya persentase dua digit dari penjualan (asumsi kerja $\pm 20\%$ pada simulasi Price Roll) | $0.5\%$ dari nominal bid disetujui | Kunci pesan ke driver dan UMKM |
| Mekanisme Tarif | Algoritma terpusat kaku / dynamic surge pricing tinggi | Reverse Auction (Bidding) + Rekomendasi Jarak OSRM | Driver & konsumen bebas menentukan kesepakatan harga adil |
| Cakupan | Luas, terbatas di gerbang/luar lingkungan kampus | Hiper-lokal & Regional Multi-Hub (Koridor Tuntungan, Jl. Golf, Bunga Ncole, hingga kampus lain di Sumut) | Kecepatan dan presisi titik antar |
| Titik antar | Alamat umum; sering berhenti di gerbang | Landmark preset (gedung, fakultas, asrama, gerbang) | Mengurangi salah titik |
| Pembayaran | Dompet digital, kartu | COD dan QRIS statis | Kekurangan: tidak seamless |
| Skala promo | Besar, subsidi agresif | Tidak ada subsidi tunai | Jangan bersaing di harga promo |
| Layanan | Terstandar, terintegrasi | Jastip fleksibel, kirim paket, tumpangan searah | Fleksibilitas lokal sebagai pembeda |
| Kepercayaan | Merek nasional | Komunitas yang saling kenal, verifikasi NIM | Keamanan lewat identitas kampus |

### 3.2 Alternatif Lain

| Alternatif | Kekuatan | Kelemahan | Respons |
|---|---|---|---|
| Grup WhatsApp (kondisi saat ini) | Gratis, familiar | Tanpa status, tanpa audit, spam, tawar-menawar manual berantakan | Migrasi bertahap ke sistem Bidding App, WA tetap fallback darurat |
| Chat pribadi dengan driver langganan | Personal | Tidak skalabel, tidak ada jaminan | Fitur driver favorit (rilis lanjutan) |
| Pesan langsung ke kantin | Sederhana | Tidak ada antar | Katalog UMKM + driver dispatcher |

### 3.3 Keunggulan Model Reverse Auction (Bidding)

Alih-alih tarif algoritmik terpusat yang kaku, Campus Express memakai Reverse
Auction: konsumen memasang order, driver mengajukan penawaran, lalu konsumen
memilih pemenang. Model ini cocok dengan pola perjalanan mahasiswa di koridor
Tuntungan–Medan.

| Pihak | Keunggulan | Dampak bisnis |
|---|---|---|
| Driver | **Efisiensi jalur searah**: driver yang memang menuju Simpang Tuntungan, Pasar Induk Lau Cih, Jl. Lapangan Golf, atau arah Medan dapat mengambil order yang searah tanpa memutar jauh | Biaya perjalanan per order turun; driver bisa menumpuk 2 order searah |
| Driver | **Kebebasan menetapkan tarif** sesuai kondisi (hujan, jam sibuk, barang berat) dengan acuan OSRM | Pendapatan lebih adil; tidak bergantung pada surge pricing platform |
| Konsumen | **Kebebasan memilih harga**, bukan sekadar menerima tarif | Biaya transparan dan bisa dinegosiasikan sesuai kantong mahasiswa |
| Konsumen | **Kebebasan memilih ETA dan rating driver** pada setiap kartu penawaran | Kontrol kualitas layanan; menghindari driver berperingkat rendah |
| Platform | Komisi tetap rendah $0.5\%$ pada harga kesepakatan (`finalPrice`) | Difensiasi terhadap komisi dua digit platform besar |
| Ekosistem | Rekomendasi jarak riil OSRM mencegah perang harga ekstrem di kedua arah | Pasar tetap sehat; driver tidak menjual rugi |

Kombinasi “peta landmark presisi + rekomendasi OSRM + bidding” membuat Campus
Express lebih presisi daripada grup WhatsApp dan lebih murah daripada platform
besar, tanpa subsidi tunai.

### 3.4 Posisi

Campus Express bukan pesaing langsung platform besar di seluruh kota; ia melayani kebutuhan yang tidak dioptimalkan oleh mereka (lorong kampus, jastip, titik landmark, komunitas). Strategi: menjadi infrastruktur lokal yang lebih murah dan lebih cocok melalui model penawaran harga adil (bidding), bukan menandiagi subsidi.

## 4. Strategi Pertumbuhan Kampus

### 4.1 Fase

| Fase | Durasi | Sasaran | Taktik | KPI keluar |
|---|---|---|---|---|
| 0. Persiapan | 4 minggu | Peta, graf landmark Tuntungan, dokumen, merekrut 10 driver awal dan 5 merchant | Survei pemetaan landmark & OSRM routing, pelatihan driver | Graf landmark selesai; 10 driver + 5 merchant terverifikasi |
| 1. Pilot tertutup | 4 minggu | 100 order sukses dengan sistem Bidding | Undang 100 anggota grup WA dalam gelombang 25 | Dispute $< 5\%$, crash-free $> 98\%$ |
| 2. Migrasi grup WA | 8 minggu | $70\%$ order di aplikasi | Admin grup mengarahkan semua permintaan ke tautan aplikasi; format pesan grup diganti tombol "Buka Bidding di Aplikasi" | $\ge 70\%$ order via aplikasi |
| 3. Perluasan | 12 minggu | 3.000 MAU | Referral, kolaborasi BEM/organisasi, kampanye landing | 3.000 MAU |
| 4. Skala kampus & Multi-Hub | 6 bulan | 10.000 MAU | Merchant lebih banyak, ekspansi hub kampus Sumut (UINSU Pancing, USU, UNIMED) | 10.000 MAU, 150 driver aktif |

### 4.2 Taktik Migrasi dari WhatsApp

| Taktik | Detail |
|---|---|
| Tautan dalam deskripsi grup | Setiap pesan permintaan jastip/numpang dibalas bot/admin dengan tautan aplikasi |
| Insentif non-tunai | Badge, prioritas penawaran bid, peringkat referral |
| Kemudahan awal | Order pertama dibantu pada layar pertama; video 30 detik |
| Peran admin grup | Admin grup menjadi duta; permintaan "numpang"/"jastip" tidak diproses di grup setelah tanggal tertentu |
| Fallback | WA tetap digunakan untuk keadaan darurat; komunikasi order di aplikasi |

### 4.3 Sisi Penawaran

| Aktor | Strategi rekrutmen |
|---|---|
| Driver | Rekrut dari pengguna aktif di grup WA; proses daftar $< 5$ menit; saldo awal $\text{Rp } 10.000$ dari top-up, bukan bonus |
| Merchant | Kunjungi langsung; bantu unggah 10 menu pertama; foto bersama; tanpa biaya |

### 4.4 Loop Pertumbuhan

```mermaid
flowchart LR
  A[Konsumen buat pesanan] --> B[Driver tawar bid & Konsumen pilih]
  B --> C[Pesanan selesai + ulasan]
  C --> D[Bagikan tautan referral]
  D --> E[Konsumen baru]
  E --> A
  C --> F[Driver dan merchant dapat order]
  F --> G[Lebih banyak penawaran bid kompetitif]
  G --> A
```

## 5. Model Skenario

Asumsi: nilai rata-rata kesepakatan order $\text{Rp } 30.000$, komisi $0.5\% = \text{Rp } 150$.

| Skenario | MAU | Order/hari | Komisi/hari | Komisi/bulan (30 hari) |
|---|---|---|---|---|
| Pilot | 1.000 | 60 | $\text{Rp } 9.000$ | $\text{Rp } 270.000$ |
| Pertumbuhan | 3.000 | 180 | $\text{Rp } 27.000$ | $\text{Rp } 810.000$ |
| Target | 10.000 | 600 | $\text{Rp } 90.000$ | $\text{Rp } 2.700.000$ |

Pada skenario target, 600 order/hari melebihi kapasitas tulis gratis Firestore ($\pm 400$ order/hari; lihat `Architecture.md` §9), sehingga biaya infrastruktur kemungkinan mulai muncul; pendapatan komisi masih jauh lebih besar dari biaya tersebut, tetapi kecil sebagai bisnis.

## 6. Keberlanjutan Finansial

Komisi $0.5\%$ menjaga nilai bagi driver dan UMKM, tetapi hampir tidak membiayai tim. Jalur pendapatan tambahan (rangkaian opsi, bukan komitmen):

| Opsi | Mekanisme | Risiko |
|---|---|---|
| Listing unggulan UMKM | Biaya promosi tetap kecil per minggu | Persepsi tidak adil |
| Sponsor kampus/brand | Slot banner terbatas di Home, label jelas | Kepercayaan, etika konten |
| Langganan driver premium | Fitur analitik penawaran bid, prioritas radar | Keadilan antar-driver |
| Hibah/pendanaan kegiatan mahasiswa | Pendanaan inkubasi kampus | Ketergantungan |
| Layanan B2B kampus | Pengantaran dokumen administrasi | Kompleksitas |

Keputusan arah monetisasi perlu persetujuan tim dan pihak kampus; dokumen ini tidak menetapkannya.

## 7. Rencana Skala

| Tahap | Pemicu | Perubahan teknis | Perubahan operasional |
|---|---|---|---|
| Satu kampus, 3.000 MAU | Tulis harian $> 70\%$ kuota | Siapkan Blaze + anggaran peringatan | Tambah admin moderator |
| Satu kampus, 10.000 MAU | Order $> 400$/hari | Pindahkan Gateway ke opsi B bila perlu; optimasi baca | Tim moderator 3–5 orang |
| Multi-kampus (Sumut) | Permintaan dari kampus lain (UINSU Pancing, USU, UNIMED) | Multi-tenant: `campusId` / `hub_id` pada semua koleksi, peta dan OSRM graph per kampus, domain email per kampus | Komunitas lokal per kampus, pelatihan duta |
| Layanan baru | Kebutuhan terbukti | Modul terpisah dalam arsitektur yang sama | Uji pilot |

Prasyarat multi-kampus: menambahkan `campusId` / `hub_id` sejak awal pada skema akan jauh lebih murah daripada migrasi nanti; disarankan memasukkannya pada rilis pertama sebagai field konstanta.

## 8. Risiko Bisnis

| Risiko | Probabilitas | Dampak | Mitigasi |
|---|---|---|---|
| Driver tidak cukup | Sedang | Tinggi | Rekrut sebelum membuka konsumen; target 1 driver per 60 konsumen aktif |
| Penawaran bid terlalu tinggi / perang harga | Sedang | Sedang | Tampilkan rekomendasi harga OSRM sebagai acuan wajar |
| Konsumen kembali ke WA | Tinggi pada awal | Sedang | Admin grup mendukung, nilai tracking, bidding transparan, dan riwayat |
| Insiden keamanan fisik/pelecehan | Rendah | Sangat tinggi | Verifikasi identitas, PIN, chat, Help Desk, kebijakan jelas |
| Kuota gratis habis | Sedang | Tinggi | Anggaran kuota, peringatan, rencana Blaze |
| Dukungan kampus tidak ada | Sedang | Sedang | Libatkan BEM/dosen pembimbing sejak awal |
| Tim kehabisan tenaga | Sedang | Tinggi | Dokumentasi, pembagian peran, otomasi moderasi |
| Platform besar masuk ke kampus | Rendah–sedang | Sedang | Fokus pada keunggulan lokal & model bidding $0.5\%$ komisi |

## 9. Metrik Utama

| Kategori | Metrik | Target 90 hari |
|---|---|---|
| Akuisisi | Pengguna terdaftar, % dari grup WA | 800 $\rightarrow$ 1.500 |
| Aktivasi | Order pertama dalam 7 hari setelah daftar | $\ge 50\%$ |
| Retensi | Pengguna dengan $\ge 2$ order/bulan | $\ge 35\%$ |
| Pasokan | Driver aktif mingguan, jumlah bid per order | 40, $\ge 3$ bid/order |
| Kualitas | Rating rata-rata, dispute rate, selisih ETA | $\ge 4.5$, $< 3\%$, $\le 4$ menit |
| Keuangan | Komisi/bulan, biaya infrastruktur/bulan | Biaya $\le$ komisi |