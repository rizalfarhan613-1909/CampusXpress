# Deployment — Campus Express

Panduan rilis **Fase 6 (Production Deployment & Final Cleanup)** untuk seluruh
komponen monorepo. Rahasia **tidak** ditulis di sini — daftar dan prosedur
rotasinya ada di [`docs/secrets.md`](./secrets.md).

## 0. Peta Komponen

| Komponen | Folder | Target Deploy | Artefak |
|---|---|---|---|
| Aplikasi mobile | `apps/mobile` | Play Store / App Store | `flutter build` (APK/AAB/IPA) |
| Web (landing, merchant, admin) | `apps/web` | **Cloudflare Pages** atau **Vercel** | Static export `apps/web/out/` |
| Business engine | `backend/functions` | Firebase Cloud Functions (`nodejs22`) | `backend/functions/lib/` |
| Trusted Gateway | `services/gateway` | **Cloudflare Workers** | `wrangler deploy` |
| Presigner R2 | `backend/cloudflare-r2` | (library, dipakai Gateway/CLI) | — |

## 1. Prasyarat Toolchain

| Alat | Versi | Catatan |
|---|---|---|
| Node.js | 22.x | Sesuai `engines` di `backend/functions`. |
| TypeScript | **6.0.3** | Disamakan dengan TS bawaan VS Code agar tab Problems bersih. Lihat §7. |
| Wrangler | 4.x | Terpasang sebagai `devDependency` di `services/gateway`. |
| Flutter / Dart | 3.44 / 3.12 | Untuk `apps/mobile`. |
| firebase-tools | 15.x | Terpasang di root (`devDependencies`). |
| Java | 17+ | Diperlukan emulator Firestore untuk `npm run test:engine`. |

## 2. Gerbang Verifikasi Pra-Deploy

Jalankan dari root repo; **semua harus lulus** sebelum deploy:

```bash
npm run typecheck        # functions + r2 + gateway + web → 0 error
npm run test:engine      # 28 test passed (0 failed)
npm run web:build        # menghasilkan apps/web/out/
cd apps/mobile && flutter analyze   # 0 issues
```

Semua gerbang di atas dapat dijalankan sekaligus (plus audit rahasia dan
validasi TOML Wrangler tanpa perlu login) dengan CLI rilis:

```bash
node scripts/release/release.mjs preflight --with-tests
```

`npm run test:engine` menjalankan Firestore Emulator. Jika muncul
`Port 8080 ... port taken`, hentikan emulator yang tertinggal lalu ulangi:

```powershell
Get-CimInstance Win32_Process -Filter "Name='java.exe'" |
  Where-Object { $_.CommandLine -like '*cloud-firestore-emulator*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
```

## 3. Deploy Trusted Gateway (Cloudflare Workers)

### 3.1 Variabel non-rahasia (`services/gateway/wrangler.toml`)

```toml
[vars]
FIREBASE_PROJECT_ID = "campus-express-prod"
ALLOWED_ORIGINS     = "https://campusexpress.example,https://admin.campusexpress.example"
R2_PUBLIC_DOMAIN    = "https://cdn.campusexpress.example"
APP_CHECK_ENFORCE   = "false"
```

Binding R2 (`PUBLIC_BUCKET` → `ce-public`, `PRIVATE_BUCKET` → `ce-private`) dan
cron trigger (`*/2 * * * *`, `0 17 * * *`) sudah didefinisikan di `wrangler.toml`.

### 3.2 Secrets (via `wrangler secret put`)

Jalankan dari `services/gateway/` (nilai dimasukkan secara interaktif, tidak
pernah lewat command line/args). Cara termudah — satu perintah untuk seluruh
secret wajib:

```bash
node scripts/release/release.mjs gateway:secrets
```

Setara dengan urutan manual berikut:

```bash
cd services/gateway

# Wajib
npx wrangler secret put FIREBASE_SERVICE_ACCOUNT_JSON   # service account Firebase (JSON satu baris)
npx wrangler secret put URL_SIGNING_KEY                 # HMAC untuk tautan /f/:key (5 menit)
npx wrangler secret put R2_ACCOUNT_ID                   # kredensial R2 (S3 API presigner)
npx wrangler secret put R2_ACCESS_KEY_ID
npx wrangler secret put R2_SECRET_ACCESS_KEY

# Opsional (bergantung pemakaian presigner S3 langsung)
npx wrangler secret put R2_BUCKET_NAME
npx wrangler secret put R2_PRIVATE_BUCKET_NAME
```

Daftar binding yang dibaca Worker didefinisikan di
`services/gateway/src/env.ts` (`Env['Bindings']`).

### 3.3 Deploy

```bash
# Dari root repo (membuat bucket R2 bila perlu, deploy, lalu health check):
node scripts/release/release.mjs gateway --create-buckets

# Setara manual:
npm run gateway:deploy        # → npm --prefix services/gateway run deploy → wrangler deploy
```

Nama Worker adalah `ce-gateway` (bukan `campus-express-gateway`), sehingga URL
produksi berbentuk:

```
https://ce-gateway.<subdomain-akun>.workers.dev
```

Catat URL tersebut — dipakai oleh Web (`NEXT_PUBLIC_GATEWAY_URL`) dan APK
(`GATEWAY_BASE_URL`). CLI menyimpannya di `.release/production.json`
(gitignored).

### 3.4 Uji pasca-deploy

```bash
curl https://<worker>.workers.dev/health          # {"ok":true,"service":"ce-gateway"}
curl https://<worker>.workers.dev/health/deps     # memeriksa akses Firestore + R2 (lihat secrets.md §7.2)
```

Development lokal: salin `services/gateway/.env.example` → `services/gateway/.dev.vars`,
lalu `npm run gateway:dev` (`wrangler dev`).

## 4. Deploy Web (Cloudflare Pages / Vercel)

`apps/web` memakai Next.js 15 dengan `output: 'export'` → menghasilkan situs
statis di `apps/web/out/` (termasuk `_headers` untuk cache Cloudflare Pages).

Rilis lewat CLI (menulis `apps/web/.env.production`, membangun ulang, dan
memverifikasi URL Gateway benar-benar ter-embed):

```bash
node scripts/release/release.mjs web \
  --gateway-url=https://ce-gateway.<subdomain>.workers.dev \
  --firebase-api-key=... \
  --firebase-app-id=... \
  --firebase-messaging-sender-id=...
```

Tambahkan `--deploy` untuk langsung `wrangler pages deploy ... --project-name=campusxpress`.

### 4.1 Cloudflare Pages

| Setting | Nilai |
|---|---|
| Build command | `npm run web:build` |
| Build output directory | `apps/web/out` |
| Root directory | (root repo) |
| Environment | `NEXT_PUBLIC_*` (lihat `apps/web/.env.example`) — hanya konfigurasi publik, tanpa kunci privat |

### 4.2 Vercel

| Setting | Nilai |
|---|---|
| Framework preset | Next.js |
| Root directory | `apps/web` |
| Build command | `next build` (default) |
| Output | statis (`out/`) — Vercel mendeteksi otomatis |
| Environment | `NEXT_PUBLIC_*` |

Hanya variabel berawalan `NEXT_PUBLIC_` yang boleh berisi konfigurasi publik;
panggilan sensitif selalu melalui Gateway (lihat `docs/secrets.md` §5.4).

## 5. Deploy Firebase (Functions, Rules, Indexes)

```bash
npm run build:functions

firebase deploy \
  --config backend/firebase/firebase.json \
  --project campus-express-prod \
  --only functions,firestore:rules,firestore:indexes
```

Atau lewat CLI (rules/indexes lebih dulu, lalu functions):

```bash
node scripts/release/release.mjs firebase --project=campus-express-prod \
  --only=firestore:rules,firestore:indexes,functions
```

Alias proyek tersedia di `.firebaserc` (`dev`, `staging`, `prod`) — gunakan
`firebase use prod` bila ingin menghindari `--project` berulang.

### 5.1 Seed data riil Hub UINSU Tuntungan (produksi)

Seeder menulis **6 landmark** (Gedung FST, Rektorat & Dekanat, Pujasera, Kos
Jl. Lapangan Golf, Simpang Tuntungan, Pasar Induk Lau Cih) dan dokumen
`config/tuntungan_hub` berisi `fare_tiers` (Tier 1 Rp 5.000 / Tier 2 Rp 7.000 /
Tier 3 Rp 7.000 + Rp 2.000 per km). Operasi idempoten (`merge`).

Prasyarat: service account dengan role **Cloud Datastore User** pada proyek
produksi (docs/secrets.md §8), lalu:

```bash
# PowerShell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\service-account-prod.json"
$env:FIREBASE_PROJECT_ID="campus-express-prod"
node scripts/release/release.mjs seed --project=campus-express-prod --yes
```

```bash
# bash
GOOGLE_APPLICATION_CREDENTIALS=/path/service-account-prod.json \
FIREBASE_PROJECT_ID=campus-express-prod \
  node scripts/release/release.mjs seed --project=campus-express-prod --yes
```

Alternatif setara: `npm run seed:hub:prod` setelah dua variabel di atas diset.
Target non-emulator **wajib** `--yes` agar seed produksi tidak berjalan tak
sengaja. Verifikasi di Console: `landmarks` = 6 dokumen, `config/tuntungan_hub`
berisi `fare_tiers`.

Seed emulator (lokal/CI): `npm run seed:hub:emulator` atau
`node scripts/release/release.mjs seed --emulator`.

## 6. Build Mobile (Flutter)

### 6.1 Release APK pilot (sideload)

Konfigurasi produksi disuntikkan sebagai `--dart-define` (bukan berkas rahasia):

```bash
node scripts/release/release.mjs apk \
  --gateway-url=https://ce-gateway.<subdomain>.workers.dev \
  --firebase-api-key=... \
  --firebase-app-id=... \
  --firebase-messaging-sender-id=...
```

CLI menulis `apps/mobile/config/prod.json` (gitignored) lalu menjalankan:

```bash
flutter build apk --release --dart-define-from-file=config/prod.json
```

Hasil: `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`, disalin ke
`dist/CampusExpress-<versi>-release.apk` beserta `dist/SHA256SUMS.txt`. Build
gagal bila APK > 40 MB (target PRD.md).

Alternatif manual:

```bash
cd apps/mobile
flutter pub get
flutter build apk --release \
  --dart-define=GATEWAY_BASE_URL=https://ce-gateway.<subdomain>.workers.dev \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=campus-express-prod \
  --dart-define=FIREBASE_STORAGE_BUCKET=campus-express-prod.firebasestorage.app
```

### 6.2 Signing

`apps/mobile/android/app/build.gradle.kts` memuat `android/key.properties` bila
ada (template: `key.properties.example`). Tanpa berkas itu, build tetap berjalan
dengan **kunci debug** — cukup untuk sideload pilot, tetapi **tidak boleh**
diunggah ke Play Store. Untuk AAB Play Store:

```bash
cd apps/mobile
flutter build appbundle --release --dart-define-from-file=config/prod.json
```

### 6.3 Catatan rilis

- Izin `INTERNET` dan `POST_NOTIFICATIONS` kini ada di manifest utama; tanpa
  `INTERNET` APK release tidak dapat menghubungi Firebase/Gateway.
- `flutter analyze` harus 0 issues sebelum build.
- Uji instalasi: `adb install -r dist/CampusExpress-<versi>-release.apk`.

## 7. Catatan Toolchain TypeScript (kenapa 6.0.3)

VS Code memakai **TypeScript 6.0.3** bawaan. TS 6.0 menandai beberapa opsi
sebagai *deprecated* (akan dihapus di TS 7.0): `baseUrl`, `moduleResolution:
node10`, `target: ES5`, `esModuleInterop: false`, dll., dan menyalakan
`noUncheckedSideEffectImports` (sehingga impor `import './x.css'` butuh
deklarasi modul).

Agar tab **Problems** 100% bersih **dan** `npm run typecheck` tetap lulus:

1. Semua `devDependencies` TypeScript disamakan ke `^6.0.3` (root, `apps/web`,
   `backend/functions`, `services/gateway`, `backend/cloudflare-r2`).
2. `apps/web/tsconfig.json` dan `backend/functions/tsconfig.json` menambahkan
   `"ignoreDeprecations": "6.0"` untuk membungkam peringatan deprecation tsb.
3. `apps/web/types/declarations.d.ts` mendeklarasikan `*.css` (dan varian
   preprocessor) agar impor `./globals.css` dan `leaflet/dist/leaflet.css`
   lolos `noUncheckedSideEffectImports` (TS2882).

> Catatan: nilai `ignoreDeprecations` **harus** `"6.0"` (bukan `"5.0"`) karena
> opsi yang di-*deprecate* di TS 6.0 hanya bisa dibungkam dengan versi 6.0.
> Jangan menaikkan TypeScript ke 7.x tanpa menghapus opsi-opsi deprecated di atas.

## 8. Checklist Go-Live Fase 6

| ✓ | Langkah | Perintah / bukti |
|---|---|---|
| [ ] | Working tree bersih, `main` = `origin/main` | `git status -sb` |
| [ ] | Preflight lulus (typecheck, 28 test, audit, dry-run Wrangler, analyze) | `node scripts/release/release.mjs preflight --with-tests` |
| [ ] | Rules & indexes ter-deploy | `node scripts/release/release.mjs firebase --only=firestore:rules,firestore:indexes` |
| [ ] | Functions ter-deploy (nodejs22) | `... firebase --only=functions` |
| [ ] | 6 landmark + `config/tuntungan_hub` ada di produksi | Console Firestore |
| [ ] | Secrets Worker terpasang (7 nama, tanpa nilai di log) | `npx wrangler secret list` |
| [ ] | Worker live & sehat | `GET /health` → `{"ok":true,...}`; `GET /health/deps` |
| [ ] | Web build memuat URL Worker produksi | `node scripts/release/release.mjs web --gateway-url=...` |
| [ ] | Domain Pages masuk `ALLOWED_ORIGINS` Worker | `wrangler.toml` / `--allowed-origins` |
| [ ] | APK ≤ 40 MB, terpasang di perangkat uji | `dist/CampusExpress-<versi>-release.apk` |
| [ ] | 10 driver + 5 UMKM pilot dapat login & order | UAT lapangan |

### 8.1 Known operational notes

- `services/gateway/wrangler.toml` sebelumnya memakai komentar `//` (invalid
  TOML) sehingga `wrangler deploy` gagal total; sudah diperbaiki menjadi `#`.
- `R2_PUBLIC_DOMAIN` dan `ALLOWED_ORIGINS` di `wrangler.toml` masih domain
  contoh. Ganti dengan domain Pages/CDN nyata sebelum go-live, atau deploy
  dengan `--allowed-origins=https://<project>.pages.dev`.
- `APP_CHECK_ENFORCE=false` di produksi: nyalakan (`"true"`) setelah App Check
  terdaftar untuk Web/Android agar tidak memblokir klien pilot.
- `.env.production`, `config/prod.json`, `key.properties`, dan `dist/` bersifat
  gitignored — jangan pernah di-commit.