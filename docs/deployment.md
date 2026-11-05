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
pernah lewat command line/args):

```bash
cd services/gateway

# Wajib
npx wrangler secret put FIREBASE_SERVICE_ACCOUNT_JSON   # service account Firebase (JSON satu baris)
npx wrangler secret put URL_SIGNING_KEY                 # HMAC untuk tautan /f/:key (5 menit)
npx wrangler secret put R2_ACCESS_KEY_ID                # kredensial R2 (S3 API presigner)
npx wrangler secret put R2_SECRET_ACCESS_KEY

# Opsional (bergantung pemakaian presigner S3 langsung)
npx wrangler secret put R2_ACCOUNT_ID
npx wrangler secret put R2_BUCKET_NAME
npx wrangler secret put R2_PRIVATE_BUCKET_NAME
```

Daftar binding yang dibaca Worker didefinisikan di
`services/gateway/src/env.ts` (`Env['Bindings']`).

### 3.3 Deploy

```bash
# Dari root repo:
npm run gateway:deploy        # → npm --prefix services/gateway run deploy → wrangler deploy

# Atau langsung:
cd services/gateway && npm run deploy
```

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

Seeder opsional (hanya lingkungan non-produksi / emulator):

```bash
npm run seed:hub:emulator
```

## 6. Build Mobile (Flutter)

```bash
cd apps/mobile
flutter pub get
flutter build appbundle --release \
  --dart-define-from-file=config/prod.json   # hanya data publik
flutter analyze                               # 0 issues
```

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