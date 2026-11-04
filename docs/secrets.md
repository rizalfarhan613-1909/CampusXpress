# Secrets Management — Campus Express

## 1. Klasifikasi

| Kelas | Contoh | Boleh di klien/repo? | Penyimpanan |
|---|---|---|---|
| Publik | Konfigurasi Firebase klien (`apiKey`, `projectId`, `appId`), URL Gateway, domain | Ya, bukan rahasia; tetap dibatasi (lihat §3) | Berkas konfigurasi per lingkungan |
| Rahasia | Service account Firebase Admin, kunci R2 (bila memakai S3 API), kunci tanda tangan URL, token Cloudflare, token CI | **Tidak pernah** | Secret manager platform |
| Rahasia tanda tangan | Keystore Android, kunci APNs, sertifikat iOS | **Tidak pernah** di repo | Penyimpanan terenkripsi di luar repo + Play App Signing |
| Data pribadi | KTM, SIM, bukti bayar | Bukan rahasia konfigurasi, tetapi dilindungi | R2 privat |

Konfigurasi Firebase klien memang terlihat publik di aplikasi; keamanan datanya ditentukan oleh Rules, App Check, dan pembatasan kunci API, bukan oleh kerahasiaan kunci.

## 2. Inventaris Rahasia

| ID | Rahasia | Dipakai oleh | Lokasi | Pemilik | Rotasi |
|---|---|---|---|---|---|
| S-01 | `FIREBASE_SERVICE_ACCOUNT_JSON` | Gateway | Workers Secret | Lead Backend | 90 hari |
| S-02 | `R2` binding (tidak ada kunci) | Gateway | `wrangler.toml` binding | Lead Backend | Tidak berlaku |
| S-03 | `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` | Skrip cadangan (opsional) | Secret CI | Lead Backend | 90 hari |
| S-04 | `URL_SIGNING_KEY` | Gateway (URL privat) | Workers Secret | Lead Backend | 90 hari |
| S-05 | `ADMIN_BOOTSTRAP_TOKEN` | Skrip pemberian claim admin | Disimpan di password manager, tidak di CI | Pemilik proyek | Sekali pakai, dibuat ulang tiap penggunaan |
| S-06 | `CF_API_TOKEN` | CI deploy | Secret CI | Lead DevOps | 90 hari |
| S-07 | `FIREBASE_TOKEN` / kredensial deploy | CI deploy | Secret CI | Lead DevOps | 90 hari |
| S-08 | Keystore Android + `key.properties` | Build rilis | Penyimpanan terenkripsi + Play App Signing | Lead Mobile | Tidak dirotasi; cadangkan |
| S-09 | Kunci APNs | FCM iOS | Konsol Firebase | Lead Mobile | Bila ada kebocoran |
| S-10 | `APP_CHECK_DEBUG_TOKEN` | Pengembang lokal/CI | Konsol Firebase, per pengembang | Tiap pengembang | 30 hari |

Daftar ini adalah satu-satunya tempat rahasia boleh didokumentasikan; nilainya tidak pernah ditulis di sini.

## 3. Konfigurasi Publik dan Pembatasannya

| Item | Pembatasan |
|---|---|
| Kunci API Android | Batasi ke nama paket + SHA-256 sertifikat penandatangan |
| Kunci API iOS | Batasi ke bundle ID |
| Kunci API Web | Batasi ke referrer domain Landing/Merchant/Admin |
| API yang diaktifkan | Hanya yang dipakai (Identity Toolkit, Firestore, FCM) |
| App Check | Mode enforce pada Firestore; Gateway memverifikasi token App Check |

## 4. Struktur Lingkungan

| Lingkungan | Proyek Firebase | Worker | Bucket R2 | Tujuan |
|---|---|---|---|---|
| `dev` | `campus-express-dev` | `ce-gateway-dev` | `ce-public-dev`, `ce-private-dev` | Pengembangan, emulator |
| `staging` | `campus-express-stg` | `ce-gateway-stg` | `ce-public-stg`, `ce-private-stg` | Uji rilis, data sintetis |
| `prod` | `campus-express-prod` | `ce-gateway` | `ce-public`, `ce-private` | Produksi |

Rahasia tidak dibagi antar lingkungan. Data produksi tidak pernah disalin ke dev atau staging.

## 5. Cara Memakai Rahasia

### 5.1 Gateway (Cloudflare Workers)

```bash
wrangler secret put FIREBASE_SERVICE_ACCOUNT_JSON --env prod
wrangler secret put URL_SIGNING_KEY --env prod
```

Pembacaan di kode lewat `env.FIREBASE_SERVICE_ACCOUNT_JSON`; tidak pernah dicatat ke log.

### 5.2 CI (GitHub Actions)

| Aturan | Detail |
|---|---|
| Lokasi | Repository/Environment secrets; Environment `prod` memerlukan persetujuan manual |
| Akses | Hanya workflow dari cabang `main` dan tag rilis |
| Fork | Rahasia tidak tersedia pada pull request dari fork |
| Cetak | Tidak ada `echo` rahasia; log disamarkan |

### 5.3 Flutter

Konfigurasi publik per lingkungan dimasukkan lewat `--dart-define-from-file=config/prod.json` (hanya data publik). Keystore dimuat dari `android/key.properties` yang masuk `.gitignore`.

### 5.4 Next.js

Hanya variabel berawalan `NEXT_PUBLIC_` yang boleh berisi konfigurasi publik. Rahasia server tidak dipakai di Next.js; panggilan sensitif selalu ke Gateway.

## 6. Berkas Contoh dan Aturan Repo

`.env.example` hanya memuat nama variabel dan nilai publik:

```dotenv
NEXT_PUBLIC_FIREBASE_PROJECT_ID=campus-express-dev
NEXT_PUBLIC_FIREBASE_APP_ID=
NEXT_PUBLIC_GATEWAY_URL=https://ce-gateway-dev.example.workers.dev
NEXT_PUBLIC_APP_CHECK_SITE_KEY=
```

`.gitignore` wajib memuat:

```gitignore
.env
.env.*
!.env.example
*.jks
*.keystore
key.properties
service-account*.json
.dev.vars
firebase-debug.log
```

| Kontrol | Alat |
|---|---|
| Pemindaian pra-commit | `gitleaks` (hook pre-commit) |
| Pemindaian CI | `gitleaks` + GitHub secret scanning dan push protection |
| Larangan | Tidak ada rahasia di issue, chat tim, tangkapan layar, atau dokumen |

## 7. Rotasi

### 7.1 Jadwal

| Jenis | Interval | Pemicu tambahan |
|---|---|---|
| Rahasia Gateway dan CI | 90 hari | Anggota tim keluar, dugaan kebocoran |
| Token pengembang (App Check debug) | 30 hari | Pergantian perangkat |
| Keystore | Tidak dirotasi | Kebocoran: ikuti prosedur Play upload key reset |

### 7.2 Prosedur Rotasi Service Account (tanpa downtime)

1. Buat kunci baru untuk service account yang sama di IAM.
2. Unggah kunci baru sebagai secret `FIREBASE_SERVICE_ACCOUNT_JSON` ke lingkungan target (`wrangler secret put`), lalu deploy.
3. Verifikasi dengan `GET /health/deps` (memeriksa akses Firestore dan R2).
4. Nonaktifkan lalu hapus kunci lama setelah 24 jam tanpa error.
5. Catat tanggal rotasi dan pelaksana di log operasional.

## 8. Prinsip Hak Minimum

| Identitas | Peran IAM |
|---|---|
| Service account Gateway | `Cloud Datastore User` (bukan Owner/Editor); tidak ada akses ke Billing atau IAM |
| Service account CI | Deploy Hosting/Rules saja |
| Token Cloudflare CI | Edit Workers dan Pages untuk akun ini; tanpa akses DNS global bila tidak diperlukan |
| Pengembang | Peran Viewer di produksi; akses tulis lewat CI |

## 9. Penanganan Insiden Kebocoran

| Langkah | Tindakan | Batas waktu |
|---|---|---|
| 1 | Cabut/rotasi rahasia terdampak (lihat §7.2) | Segera, ≤ 1 jam |
| 2 | Tinjau log akses (Firestore, Workers, R2) untuk penyalahgunaan | ≤ 4 jam |
| 3 | Bila ada akses ke data pribadi: kumpulkan fakta (data, jumlah pengguna, waktu) | ≤ 24 jam |
| 4 | Beri tahu pengguna terdampak dan pihak berwenang sesuai UU PDP dan arahan kampus | Sesuai ketentuan yang berlaku; konsultasikan penasihat hukum |
| 5 | Pasca-insiden: akar masalah, perbaikan, pembaruan `threat-model.md` | ≤ 7 hari |

Bila kunci ter-commit: hapus dari riwayat tidak cukup; anggap sudah bocor dan rotasi.

## 10. Daftar Periksa Berkala

| ✓ | Item | Frekuensi |
|---|---|---|
| [ ] | Rotasi sesuai jadwal §7 | Triwulanan |
| [ ] | Tinjau anggota dan peran pada Firebase, Cloudflare, GitHub, Play | Bulanan |
| [ ] | Pastikan tidak ada kunci service account yang tidak terpakai | Bulanan |
| [ ] | Uji pemulihan keystore dari cadangan | Semesteran |
| [ ] | Jalankan pemindaian rahasia penuh pada riwayat repo | Triwulanan |