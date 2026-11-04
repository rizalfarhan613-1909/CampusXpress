# Backend Readiness — Campus Express (hasil audit & integrasi)

Tanggal audit: 4 November 2026. Ruang lingkup: `backend/` (Firebase Functions core
engine, Firestore rules/indexes, R2 client) dan kesesuaiannya dengan
`PRD.md`, `Architecture.md` §4–§9, `tech.md` §8, `Rules.md`, `UserRole.md`, dan
`Security cheklist.md`.

## 1. Hasil verifikasi (dijalankan nyata, bukan klaim)

| Perintah | Lingkup | Hasil |
|---|---|---|
| `npx tsc --noEmit` | `backend/functions` | **0 error** |
| `npx tsc --noEmit` | `backend/cloudflare-r2` | **0 error** |
| `npm run test:engine` | Firestore Emulator (`demo-campus-express`) | **22 passed / 0 failed** |

Ringkasan suite integrasi (`backend/firebase/test-engine.mjs`): seeder 11 landmark +
matriks tarif; ambang saldo deposit `Rp 5.000`; klaim atomik (2 driver → 1 menang);
maks. 2 order aktif; COD > `Rp 200.000` ditolak; mesin status (transisi ilegal);
PIN 5× salah → lock 10 menit + event `PIN_LOCKED`; komisi
`max(50, round((subtotal+ongkir)×0,005))` + ledger idempoten; top-up admin;
**finalize harga tepercaya + `PRICE_MISMATCH`**; **pembatalan + kuota gratis/strike**;
**cron expire order timeout**.

> Catatan lingkungan: emulator Firestore memakai Java 26 dan port 8080. Bila proses
> emulator sebelumnya belum keluar, hentikan dulu
> (`Get-NetTCPConnection -LocalPort 8080`) sebelum menjalankan ulang.

## 2. Status endpoint / rute backend

Gateway saat ini berbentuk **Firebase Callable Functions** (`backend/functions`),
bukan Cloudflare Workers Hono seperti contoh di `tech.md` §8.

| Rute acuan | Implementasi | Status |
|---|---|---|
| `/orders/finalize` | `finalizeOrder` → `core/finalizeOrder.ts` | ✅ Baru |
| `/orders/claim` | `claimOrder` → `core/claimOrder.ts` (transaksi) | ✅ |
| `/orders/complete` | `completeOrder` → `core/completeOrder.ts` | ✅ |
| `/orders/cancel` | `cancelOrder` → `core/cancelOrder.ts` | ✅ Baru |
| `/cron/expire-orders` | `expireOrdersCron` (`onSchedule */2`) + `expireOrders` | ✅ Baru |
| `/wallet/topup` | `topUpWallet` (admin, idempoten) | ✅ |
| `/upload/:kind` | hanya pustaka `cloudflare-r2/r2Client.ts` (validasi magic-bytes + limit 85 KB) — belum terhubung ke rute | ⚠️ Belum |
| `/files/:key`, `/f/:key` | signed URL 5 menit belum ada (butuh `@aws-sdk/s3-request-presigner` + kredensial R2) | ⚠️ Belum |
| `/admin/topup/:id/approve` | alur pengajuan→persetujuan dua langkah belum ada (top-up masih satu langkah admin) | ⚠️ Belum |
| `/public/pings`, `/public/stats`, `/public/reviews` | endpoint publik + header edge cache 30 dtk belum ada | ⚠️ Belum |

## 3. Aturan bisnis kritis — terbukti lulus

- **X3 harga tepercaya**: ongkir dihitung ulang dari matriks zona; order dengan
  ongkir/total palsu ditandai `EXPIRED` + `PRICE_MISMATCH` (tidak terlihat driver).
- **Ambang saldo driver < Rp 5.000** → `INSUFFICIENT_BALANCE`.
- **Race condition klaim**: `db.runTransaction` → tepat satu driver menang
  (`ORDER_TAKEN` untuk yang kalah).
- **PIN lock**: 5× salah → `locked_until = now + 10 menit` + event `PIN_LOCKED`.
- **Komisi**: `max(50, round_half_up((subtotal+ongkir)×0,005))`, ledger
  `COMMISSION_DEDUCTION` idempoten per order.
- **COD > Rp 200.000** → `COD_LIMIT_EXCEEDED` (pertahanan ganda: rules + engine).
- **Pembatalan + strike** per `Rules.md` §7 (gratis sebelum klaim; 2×/hari setelah
  klaim; strike untuk pembatalan driver / kuota konsumen habis).
- **Timeout**: `PLACED` > 5 mnt & `AWAITING_DRIVER` > 10 mnt → `EXPIRED`.

## 4. Audit Firestore Security Rules (`backend/firebase/firestore.rules`)

Terkonfirmasi aman (default-deny + whitelist):

- `match /{document=**} { allow read, write: if false }` sebagai gerbang awal.
- `wallets`, `walletTx`, `salesPings`, `stats`, `referrals`, `nimIndex` (`write`),
  `auditLogs` (`write`), `reviews`, `disputes`, `driverProfiles`, `merchantMenus`
  **tidak memiliki blok izin → otomatis ditolak** (hanya bisa ditulis Gateway via
  Admin SDK).
- `orders`: `create` dibatasi `hasOnly([...])` + batas nominal (`total ≤ 500.000`,
  COD ≤ 200.000, komisi 50–2.500); `update` hanya perpindahan `status` sesuai peran;
  `delete: false`. Field sensitif (`pricing`, `commission_fee`) tidak dapat diubah
  klien setelah dibuat.
- `orders/*/secrets/handover`: `get` hanya konsumen pemesan, `write: false`.

Indeks komposit tersedia untuk semua pola query lot (`status+created_at`,
`driver_id+created_at`, `consumer_id+created_at`, `merchant_id+status+created_at`,
`products`, `landmarks`).

## 5. Celah yang belum tertutup (tidak dapat diverifikasi di lingkungan ini)

1. **Gateway Workers (tech.md §8)** belum dibangun (`services/gateway` belum ada);
   middleware CORS domain, rate limiting per-UID/IP, dan App Check enforcement
   belum aktif. Callable Firebase sudah memverifikasi ID token otomatis, tetapi
   `enforceAppCheck` belum diaktifkan.
2. **R2**: unggah & signed URL belum dirutekan; `@aws-sdk/s3-request-presigner`
   belum terpasang. Validasi gambar (magic bytes, limit 85 KB, folder publik/privat)
   sudah siap di `r2Client.ts`.
3. **Endpoint publik ber-cache** dan **top-up dua langkah** belum ada.
4. **Rules fungsional (bukan celah keamanan)**: driver belum dapat membaca dompet
   sendiri, `driverProfiles` self read/update, dan `orders` belum mengizinkan update
   `tracking`/`version` saat checkpoint — perlu disesuaikan sebelum layar UI terkait.

## 6. Kesimpulan

Core business engine (klaim, PIN/komisi, top-up, finalize harga, pembatalan/strike,
expire timeout) **lulus 100%** dengan typecheck bersih. Fondasi aman untuk lanjut ke
penyusunan `Design.md` dan UI Web. Pekerjaan tersisa bersifat **lapisan pengiriman**
(Workers/R2/endpoint publik/App Check) dan penyempurnaan rules untuk kebutuhan baca
klien; tidak ada yang memblokir desain UI.
