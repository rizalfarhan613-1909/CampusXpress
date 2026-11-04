# Rules — Aturan Bisnis Campus Express

Dokumen ini adalah sumber tunggal untuk aturan bisnis, validasi, batas transaksi, pedoman chat, dan kebijakan pembatalan. Nilai angka bersumber dari `config/app` sehingga dapat diubah admin tanpa rilis aplikasi.

## 1. Konstanta Konfigurasi

| Kunci `config/app` | Nilai awal | Keterangan |
|---|---|---|
| `commissionBps` | 50 | 0,5% |
| `minCommission` | 50 | Rupiah |
| `driverMinBalance` | 5.000 | Syarat klaim |
| `driverLowBalanceWarn` | 10.000 | Notifikasi saldo rendah |
| `topupMin` / `topupMax` | 10.000 / 500.000 | Per transaksi top-up |
| `codMax` | 200.000 | Batas COD |
| `orderMax` | 500.000 | Batas total order |
| `avgSpeedKmh` | 20 | ETA |
| `merchantAcceptTimeoutSec` | 300 | |
| `driverClaimTimeoutSec` | 600 | |
| `pinMaxAttempts` / `pinLockSec` | 5 / 600 | |
| `maxActiveJobsPerDriver` | 2 | |
| `chatRatePerMin` | 20 | |
| `chatReadonlyAfterSec` | 86400 | |
| `nimPattern` | `^[0-9]{10,12}$` | Sesuaikan format NIM kampus |

## 2. Aturan Akun dan Peran

| Kode | Aturan |
|---|---|
| BR-A1 | Satu akun Google `@mhs.uin.ac.id` = satu akun aplikasi; satu NIM = satu akun. |
| BR-A2 | Driver wajib: KTM aktif, SIM C berlaku, data kendaraan, persetujuan pemrosesan data pribadi. |
| BR-A3 | Merchant wajib: nama usaha, landmark, minimal satu produk, QRIS statis (bila menerima QRIS), kontak penanggung jawab. |
| BR-A4 | Admin hanya ditetapkan melalui skrip Gateway oleh pemilik proyek, tidak lewat aplikasi. |
| BR-A5 | Mahasiswa yang sudah tidak aktif (lulus/cuti) dapat dinonaktifkan oleh admin; data order tetap disimpan sesuai retensi. |
| BR-A6 | Satu pengguna tidak boleh memesan layanan untuk dirinya sendiri (konsumen ≠ driver pada order yang sama). |

## 3. Aturan Layanan

| Layanan | Aturan |
|---|---|
| Numpang Kampus | Maksimal 1 penumpang; helm wajib; tarif tetap per pasangan zona; tidak boleh keluar area kampus yang ditetapkan |
| Jastip Makanan | Maksimal 10 item; harga item diisi konsumen sebagai estimasi, harga akhir sesuai struk; selisih > Rp 5.000 harus disetujui konsumen via chat sebelum dibeli |
| Kirim Paket | Maksimal 5 kg dan ukuran muat satu tas; dilarang: barang berbahaya, obat resep, minuman beralkohol, uang tunai, dokumen identitas asli, hewan hidup |
| Katalog UMKM | Hanya merchant terverifikasi; harga katalog mengikat saat order dibuat; stok habis ditandai `available=false` |

### 3.1 Tarif

| Kode | Aturan |
|---|---|
| BR-T1 | Tarif dibaca dari `fareMatrix` per pasangan zona; klien tidak menentukan nilai. |
| BR-T2 | Ongkir jastip/umkm = `jastipBase` zona tujuan. |
| BR-T3 | Perubahan tarif berlaku untuk order baru; order berjalan memakai snapshot harga. |
| BR-T4 | Tip tidak ada pada v1. |

## 4. Aturan Order dan Transaksi

| Kode | Aturan |
|---|---|
| BR-O1 | Satu konsumen maksimal 2 order aktif bersamaan. |
| BR-O2 | Total order maksimal Rp 500.000; COD maksimal Rp 200.000. |
| BR-O3 | Keranjang hanya satu merchant. |
| BR-O4 | Merchant harus merespons dalam 5 menit; selebihnya order `EXPIRED`. |
| BR-O5 | Order `AWAITING_DRIVER` tanpa klaim 10 menit menjadi `EXPIRED`; konsumen dapat memesan ulang satu klik. |
| BR-O6 | Driver tidak dapat klaim bila saldo < `driverMinBalance` atau sudah punya 2 pekerjaan aktif. |
| BR-O7 | Order `COMPLETED` hanya via PIN yang benar (atau konfirmasi merchant untuk ambil sendiri). |
| BR-O8 | Komisi dipotong tepat sekali per order selesai (idempoten). |
| BR-O9 | Order yang diselesaikan manual oleh admin pada dispute tetap mengikuti aturan komisi yang sama kecuali admin menetapkan pengecualian beserta alasan tercatat. |

### 4.1 Pembayaran

| Kode | Aturan |
|---|---|
| BR-P1 | Metode: COD tunai atau QRIS statis; tidak ada pembayaran di dalam aplikasi pada v1. |
| BR-P2 | QRIS: konsumen mengunggah bukti; penerima menekan "Pembayaran Diterima". Order tidak diproses sebelum itu untuk jastip/paket/numpang. |
| BR-P3 | Pada jastip COD, driver menalangi harga barang; konsumen membayar harga struk + ongkir saat serah-terima. |
| BR-P4 | Bukti QRIS yang terbukti palsu: strike pada akun konsumen dan kasus dispute otomatis. |
| BR-P5 | Pengembalian dana dilakukan di luar aplikasi antar pihak berdasarkan putusan dispute; aplikasi hanya mencatat. |

## 5. Validasi Form

| Field | Aturan | Pesan error |
|---|---|---|
| Email | Akhiran `@mhs.uin.ac.id`, `email_verified` true | "Gunakan akun @mhs.uin.ac.id" |
| NIM | Sesuai `nimPattern`, unik | "NIM tidak valid" / "NIM sudah terdaftar" |
| Nama tampilan | 2–40 karakter, huruf, spasi, titik, apostrof | "Nama 2–40 karakter" |
| WhatsApp | `^(\+62\|62\|0)8[1-9][0-9]{7,11}$`, disimpan sebagai E.164 | "Nomor WhatsApp tidak valid" |
| Catatan lokasi/order | ≤ 140 karakter | "Maksimal 140 karakter" |
| Nama produk | 2–60 karakter | |
| Harga produk | Integer 500–500.000, kelipatan 100 | "Harga 500–500.000, kelipatan 100" |
| Grup opsi | Maks. 6 grup, 12 opsi per grup | |
| Jumlah item | 1–20 per baris | |
| Top-up | Integer `topupMin`–`topupMax`, kelipatan 1.000 | |
| Ulasan | Bintang 1–5, komentar ≤ 280 | |
| Plat nomor | `^[A-Z]{1,2}\s?[0-9]{1,4}\s?[A-Z]{0,3}$` | "Format plat tidak valid" |
| Gambar | WebP/JPEG/PNG → dikonversi WebP, ≤ 80 KB, sisi terpanjang ≤ 1280 px | "Gambar terlalu besar" |

## 6. Pedoman Keamanan dan Etika Chat

### 6.1 Tujuan Chat

Chat adalah kanal resmi untuk koordinasi order (titik temu, konfirmasi item, perubahan). Chat bukan untuk percakapan pribadi di luar order.

### 6.2 Aturan

| Kode | Aturan |
|---|---|
| CH-1 | Dilarang kata kasar, ancaman, pelecehan, ujaran SARA, dan konten seksual. |
| CH-2 | Dilarang meminta atau memberi data sensitif (PIN, OTP, kata sandi, nomor rekening pribadi). Aplikasi tidak pernah meminta PIN lewat chat; PIN hanya diketik driver di layar serah-terima. |
| CH-3 | Dilarang mengajak transaksi di luar aplikasi. |
| CH-4 | Nomor telepon boleh dibagikan, tetapi sistem menampilkan peringatan privasi. |
| CH-5 | Pengguna dapat melaporkan pesan dan memblokir lawan bicara; blokir tidak membatalkan order aktif. |
| CH-6 | Batas laju 20 pesan/menit; pelanggaran berulang menunda pengiriman 60 detik. |
| CH-7 | Gambar hanya WebP ≤ 80 KB dan tunduk pada kebijakan yang sama dengan teks. |

### 6.3 Penegakan

| Pelanggaran | Tindakan |
|---|---|
| Kata kasar (ringan) | Peringatan otomatis di chat |
| Pelecehan/ancaman (sedang) | Strike, tinjauan admin ≤ 24 jam |
| Pelecehan seksual, ancaman fisik, doxxing (berat) | Suspend langsung, penyimpanan bukti, eskalasi ke pihak kampus bila perlu |
| Laporan palsu berulang | Strike pelapor |

### 6.4 Privasi dan Enkripsi Chat

Pesan dienkripsi saat transit dan saat disimpan oleh penyedia infrastruktur, tetapi tidak end-to-end, agar bukti dapat ditinjau pada dispute dan pelanggaran. Pengguna diberi tahu pada layar chat pertama kali. Pesan dihapus otomatis 30 hari setelah dikirim, kecuali ditahan untuk kasus terbuka.

## 7. Kebijakan Pembatalan

| Kondisi | Pembatal | Konsekuensi |
|---|---|---|
| Sebelum klaim driver | Konsumen | Gratis, tanpa strike |
| Setelah klaim, sebelum `AT_PICKUP` | Konsumen | Gratis 2× per hari; seterusnya 1 strike |
| Setelah `AT_PICKUP` (barang sudah dibeli/dijemput) | Konsumen | Tidak dapat dibatalkan; buka dispute atau bayar biaya ongkir dan barang |
| Merchant menolak/timeout | Merchant | Order batal; 3 timeout dalam sehari menurunkan peringkat tampilan |
| Setelah klaim | Driver | Order kembali `AWAITING_DRIVER`; 1 strike |
| Driver menghilang > 10 menit setelah `AT_PICKUP` tanpa chat | Sistem/Admin | Order dispute otomatis, strike driver |
| Kondisi darurat/kendala kampus | Admin | Batal massal, tanpa strike |

### 7.1 Strike

| Jumlah strike (30 hari bergulir) | Tindakan |
|---|---|
| 1 | Peringatan |
| 2 | Batas klaim satu pekerjaan aktif (driver) / satu order aktif (konsumen) selama 7 hari |
| 3 | Suspend 7 hari |
| 5 dalam 90 hari | Tinjauan permanen oleh admin |

Strike dapat diajukan banding lewat Dispute Center dalam 7 hari.

## 8. Dispute

| Kode | Aturan |
|---|---|
| DP-1 | Dapat dibuka oleh peserta order dalam 24 jam setelah `ARRIVED`/`COMPLETED`. |
| DP-2 | Kategori: barang tidak sampai, barang salah/rusak, harga tidak sesuai, perilaku, pembayaran, lainnya. |
| DP-3 | Bukti: chat, foto (≤ 80 KB), bukti bayar. |
| DP-4 | SLA tanggapan pertama 24 jam, penyelesaian target 3 hari. |
| DP-5 | Putusan admin final pada v1; banding ke ketua pengelola proyek. |

## 9. Rating

| Kode | Aturan |
|---|---|
| RT-1 | Hanya konsumen pada order `COMPLETED` yang dapat menilai, satu kali, dapat diedit 24 jam. |
| RT-2 | Driver dengan rating < 3,5 setelah ≥ 20 ulasan masuk tinjauan. |
| RT-3 | Ulasan yang melanggar CH-1 disembunyikan oleh admin. |

## 9a. Referral

| Kode | Aturan |
|---|---|
| RF-1 | Reward diberikan hanya setelah pengguna undangan menyelesaikan order pertama bernilai ≥ Rp 10.000. |
| RF-2 | Reward v1 non-tunai: badge dan peringkat; tidak ada saldo uang. |
| RF-3 | Satu akun hanya dapat memasukkan satu kode; tidak dapat memakai kode sendiri. |
| RF-4 | Kecurangan (akun palsu, perangkat sama) mengakibatkan pencabutan reward dan strike. |

## 10. Retensi Data

| Data | Retensi |
|---|---|
| Order dan e-receipt | 12 bulan, setelah itu dianonimkan |
| Chat | 30 hari |
| Dokumen KTM/SIM | Selama akun driver aktif + 30 hari setelah penonaktifan, lalu dihapus |
| Bukti bayar | 90 hari |
| Audit log | 24 bulan |