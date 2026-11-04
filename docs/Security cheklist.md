# Security Checklist — Campus Express

Cara pakai: centang sebelum setiap rilis (`[ ]` → `[x]`). Kolom **Bukti** berisi cara memverifikasi. Item bertanda **KRITIS** memblokir rilis bila belum terpenuhi.

## 1. Identitas dan Autentikasi

| ✓ | Item | Prioritas | Bukti |
|---|---|---|---|
| [ ] | Hanya penyedia Google yang aktif di Firebase Auth | KRITIS | Konsol Auth |
| [ ] | Rules menolak semua akses bila `email_verified != true` atau domain bukan `@mhs.uin.ac.id` | KRITIS | Uji emulator: akun `@gmail.com` ditolak |
| [ ] | Gateway memverifikasi ID token (penerbit, audiens, kedaluwarsa, tanda tangan via JWKS) | KRITIS | Tes unit Gateway |
| [ ] | Custom claim `admin` hanya diberikan lewat skrip terkontrol dan tercatat | KRITIS | Audit log |
| [ ] | Akun `suspended` ditolak di rules (`status == 'active'`) dan sesi dicabut (`revokeRefreshTokens`) | Tinggi | Uji manual |
| [ ] | Firebase App Check (Play Integrity / App Attest) diwajibkan pada Firestore dan Gateway | Tinggi | Mode enforce aktif |
| [ ] | Tidak ada login anonim | Tinggi | Konsol Auth |

## 2. Firestore Security Rules

| ✓ | Item | Prioritas | Bukti |
|---|---|---|---|
| [ ] | Aturan awal `allow read, write: if false;` pada `match /{document=**}` | KRITIS | Tinjau kode |
| [ ] | `wallets`, `walletTx`, `auditLogs`, `nimIndex`, `salesPings`, `stats`, `referrals`: tulis klien dilarang | KRITIS | Tes emulator |
| [ ] | `orders`: klien hanya dapat membuat dengan `status == 'PLACED'`, `consumerUid == auth.uid`, `finalized == false` | KRITIS | Tes emulator |
| [ ] | `orders`: update dibatasi `affectedKeys().hasOnly([...])` per peran dan transisi | KRITIS | Tes emulator tiap transisi |
| [ ] | `orders/*/secrets/handover`: baca hanya konsumen; tulis dilarang | KRITIS | Tes emulator |
| [ ] | Driver tidak dapat membaca order yang bukan `AWAITING_DRIVER`/miliknya | Tinggi | Tes emulator |
| [ ] | Chat: baca/tulis hanya `participants`; `senderUid == auth.uid`; `createdAt == request.time`; panjang teks ≤ 500 | KRITIS | Tes emulator |
| [ ] | Ruang chat `readonly`/`closed` menolak tulis | Tinggi | Tes emulator |
| [ ] | Pembatasan ukuran daftar (`blockedUids`, `fcmTokens`) di rules | Sedang | Tes emulator |
| [ ] | Semua rules memiliki tes otomatis dan dijalankan di CI | Tinggi | Pipeline hijau |
| [ ] | Query tanpa `limit` dilarang oleh konvensi kode (lint) | Sedang | Lint |

## 3. Trusted Gateway

| ✓ | Item | Prioritas | Bukti |
|---|---|---|---|
| [ ] | Semua endpoint selain `/public/*` memerlukan `Authorization: Bearer <ID token>` | KRITIS | Tes: 401 tanpa token |
| [ ] | Klaim order menggunakan transaksi Firestore (cek status, saldo, `activeJobs`) | KRITIS | Tes konkurensi: dua klaim, satu menang |
| [ ] | Komisi idempoten lewat `idempotencyKey = commission:{orderId}` | KRITIS | Tes kirim ulang |
| [ ] | PIN dibandingkan constant-time; batas percobaan 5; kunci 10 menit | KRITIS | Tes unit |
| [ ] | Rate limit per UID dan per IP (Workers Rate Limiting / Durable Object) | Tinggi | Uji beban |
| [ ] | Validasi skema semua body (zod) dan penolakan field tak dikenal | Tinggi | Tes unit |
| [ ] | CORS hanya untuk domain Landing, Merchant Web, Admin | Tinggi | Tes manual |
| [ ] | Log tidak memuat PIN, token, atau isi chat | KRITIS | Tinjau log |
| [ ] | Respon error generik ke klien, detail hanya di log | Sedang | Tinjau kode |

## 4. Chat

| ✓ | Item | Prioritas |
|---|---|---|
| [ ] | Enkripsi transit (TLS) dan at-rest dari penyedia; pengguna diberi pemberitahuan bahwa chat bukan E2EE | Tinggi |
| [ ] | Teks dirender sebagai teks polos (tidak ada HTML/Markdown aktif; tautan tidak otomatis dibuka tanpa konfirmasi) | KRITIS |
| [ ] | Pengiriman gambar melewati Gateway: validasi magic bytes WebP, ≤ 80 KB | Tinggi |
| [ ] | Batas laju 20 pesan/menit dan deduplikasi `clientId` | Tinggi |
| [ ] | Tombol laporkan pesan dan blokir tersedia dan berfungsi | Tinggi |
| [ ] | TTL `expireAt` aktif pada `messages` | Sedang |
| [ ] | Nomor telepon terdeteksi memunculkan peringatan privasi | Sedang |
| [ ] | Aplikasi tidak pernah meminta PIN, OTP, atau kata sandi di chat dan ada peringatan permanen | Tinggi |

## 5. Cloudflare R2 dan Berkas

| ✓ | Item | Prioritas | Bukti |
|---|---|---|---|
| [ ] | Dua bucket terpisah: `ce-public` (gambar produk, aset peta) dan `ce-private` (KTM, SIM, bukti bayar, QRIS) | KRITIS | Konsol R2 |
| [ ] | `ce-private` tanpa akses publik; baca via Gateway dengan URL bertanda tangan ≤ 5 menit | KRITIS | Uji akses langsung: 403 |
| [ ] | Unggah hanya melalui Gateway; klien tidak memegang kredensial R2 | KRITIS | Tinjau app |
| [ ] | Validasi tipe dengan magic bytes, bukan ekstensi; tolak selain WebP | Tinggi | Tes unit |
| [ ] | Batas ukuran 80 KB (+ toleransi 5 KB) dan batas jumlah unggah per hari per UID | Tinggi | Tes unit |
| [ ] | Nama objek acak (UUID); tidak memuat NIM/nama | Tinggi | Tinjau kode |
| [ ] | Metadata EXIF dihapus (konversi WebP di klien dan verifikasi di Gateway) | Tinggi | Tes manual |
| [ ] | CORS bucket publik dibatasi domain sendiri; hotlink protection via aturan WAF | Sedang | Konsol |
| [ ] | Siklus hidup: bukti bayar 90 hari, dokumen driver dihapus 30 hari setelah akun nonaktif | Tinggi | Aturan lifecycle |

## 6. Aplikasi Flutter

| ✓ | Item | Prioritas |
|---|---|---|
| [ ] | `--obfuscate --split-debug-info` pada build rilis | Tinggi |
| [ ] | Tidak ada rahasia di kode atau aset (lihat `secrets.md`) | KRITIS |
| [ ] | Penyimpanan lokal hanya data non-sensitif; token tidak disimpan manual | Tinggi |
| [ ] | `android:allowBackup="false"`, `usesCleartextTraffic="false"` | Tinggi |
| [ ] | Layar PIN dan bukti bayar memakai `FLAG_SECURE` (blokir tangkapan layar) | Sedang |
| [ ] | Versi minimum aplikasi dipaksa via Remote Config | Tinggi |
| [ ] | Deep link divalidasi (host dan parameter) | Sedang |
| [ ] | Dependensi dipindai (`dart pub outdated`, Dependabot) | Sedang |
| [ ] | Keystore rilis disimpan di luar repo, cadangan terenkripsi | KRITIS |

## 7. Web Next.js (Landing, Merchant, Admin)

| ✓ | Item | Prioritas |
|---|---|---|
| [ ] | CSP ketat (tanpa `unsafe-inline` untuk skrip), `X-Content-Type-Options`, `Referrer-Policy`, `frame-ancestors 'none'` | Tinggi |
| [ ] | Panel Admin hanya dapat diakses dengan custom claim `admin` dan, bila memungkinkan, dilindungi Cloudflare Access | KRITIS |
| [ ] | Tidak ada `dangerouslySetInnerHTML` pada data pengguna | KRITIS |
| [ ] | Referral: kode di-sanitasi (`^[A-Z0-9]{6}$`) | Sedang |
| [ ] | Endpoint publik hanya mengembalikan data teragregat dan anonim | KRITIS |
| [ ] | `npm audit` bersih dari kerentanan tinggi/kritis | Tinggi |

## 8. Data Pribadi (UU PDP)

| ✓ | Item | Prioritas |
|---|---|---|
| [ ] | Pemberitahuan privasi dan persetujuan eksplisit sebelum unggah KTM/SIM | KRITIS |
| [ ] | Minimisasi data: simpan hanya yang diperlukan; rekening penuh tidak masuk Firestore | Tinggi |
| [ ] | Akses KTM/SIM hanya admin verifikator; setiap akses dicatat | Tinggi |
| [ ] | Mekanisme permintaan hapus akun dan data | Tinggi |
| [ ] | Prosedur pemberitahuan insiden data pribadi disiapkan (lihat `secrets.md` §7) | Tinggi |
| [ ] | Tinjauan hukum oleh pihak berwenang kampus/penasihat sebelum peluncuran publik | Tinggi |

## 9. Operasional

| ✓ | Item | Prioritas |
|---|---|---|
| [ ] | Dua langkah (2FA) pada akun Google/Firebase, Cloudflare, GitHub, dan Play Console | KRITIS |
| [ ] | Peran IAM minimum; tidak ada akun pemilik bersama | Tinggi |
| [ ] | Cadangan Firestore terjadwal (ekspor) ke penyimpanan terpisah, diuji pulih sekali per kuartal | Tinggi |
| [ ] | Peringatan kuota 70% dan 90% aktif | Tinggi |
| [ ] | Anggaran dan batas pengeluaran manual di Cloud Billing jika memakai Blaze | Tinggi |
| [ ] | Kill switch Remote Config diuji | Sedang |
| [ ] | Runbook insiden dan daftar kontak tersedia | Sedang |

## 10. Gerbang Rilis

Rilis boleh dilakukan bila: semua item **KRITIS** tercentang, tidak ada temuan Tinggi terbuka tanpa mitigasi tertulis, dan hasil tes rules + Gateway hijau di CI.