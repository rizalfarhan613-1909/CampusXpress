# Campus Express — Web (Next.js 15)

Aplikasi web Campus Express: landing page pemasaran, dasbor merchant, dan panel
kontrol admin BEM. Dibangun sebagai **Next.js 15 App Router + TypeScript + Tailwind
CSS** dengan **static export** (`out/`) sesuai `docs/Design.md` §C.23, §C.12–§C.15,
§C.17, §C.21 dan `docs/tech.md` §6.

## Perintah

```bash
# dari folder ini (apps/web)
npm install
npm run dev        # http://localhost:3000
npm run build      # static export ke ./out
npm run lint       # ESLint (next/core-web-vitals + next/typescript)
npm run typecheck  # tsc --noEmit

# atau dari root monorepo
npm run web:dev
npm run web:build
```

## Peta rute

| Rute | Berkas | Acuan desain |
|---|---|---|
| `/` | `app/(marketing)/page.tsx` | §C.23 Web Landing Page |
| `/r/[code]` | `app/r/[code]/page.tsx` | §C.23 + tech.md §6.8 (referral) |
| `/merchant/` | `app/merchant/page.tsx` | §C.12 Dasbor merchant |
| `/merchant/orders/` | `app/merchant/orders/page.tsx` | §C.13 Order dispatcher |
| `/merchant/menu/` | `app/merchant/menu/page.tsx` | §C.17 Kelola menu |
| `/merchant/settings/` | `app/merchant/settings/page.tsx` | §C.21 Pengaturan toko |
| `/admin/` | `app/admin/page.tsx` | §C.15 Master control panel |

## Komponen landing (9 komponen interaktif)

| Komponen | Perilaku |
|---|---|
| `HeroReferralBanner` | Pill program referral + generator tautan `/r/[kode]/` (kode `^[A-Z0-9]{6}$`) |
| `WordRotator` | Siklus 2400 ms, lebar dikunci kata terpanjang agar tanpa layout shift |
| `SalesPings` | Toast kiri bawah: masuk 250 ms, tampil 4 dtk, satu toast / 6 dtk, tombol tutup |
| `CountUp` | `0 → n` 1200 ms `ease-out-cubic`, dipicu 40% kartu terlihat, sekali saja |
| `BentoShowcase` | Grid 3 kolom + widget PIN/ETA (progress 0 → 65%, PIN per digit 80 ms) |
| `ProcessDraw` | 4 langkah, garis SVG `pathLength` mengikuti `scrollYProgress` |
| `PriceRoll` | Tab 3 skenario, angka berputar spring (120/20), dua kartu + banner hemat |
| `CursorTour` | Hotspot pada bingkai perangkat, auto-geser 3 dtk, jeda saat hover/fokus |
| `ReviewShuffle` | Grid 3 kolom di `lg+`, tumpukan kartu geser di bawah `lg` |

## Token desain

`tailwind.config.ts` memuat token dari `docs/Design.md` §A.1–§A.5 dan §E.1:

- `primary` `#006C4A` (+ `pressed`, `bright`, `glow`, `on-primary`)
- `mint` `#8DF3CE` / `#CFF8E8`, `lav` `#E1E7FF` family (`#F1F3FF` … `#D5DBF5`)
- `bg` `#F8F9FF`, `surface` `#FFFFFF`, `ink`, `text`, `danger`, `info`, `star`, `line`
- Tipografi `web-h1` 40/48, `web-h2` 26/32, `web-stat` 30/36, `body-*`, `caption`, `micro`
- Radius `xs`–`sheet` + `bento` 20 px, shadow `card` / `float` / `cta` / `bar-top`

Font: Plus Jakarta Sans (heading), Inter (body), JetBrains Mono (ID/mono) di-self-host
melalui `next/font/google` sehingga tidak ada unduhan font saat runtime.

## Konfigurasi lingkungan (opsional)

Salin `.env.local.example` → `.env.local`. Tanpa berkas ini aplikasi tetap berjalan
dalam **mode demo** (data contoh lokal, generator referral lokal):

```
NEXT_PUBLIC_GATEWAY_URL=
NEXT_PUBLIC_FIREBASE_API_KEY=
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=
NEXT_PUBLIC_FIREBASE_PROJECT_ID=
NEXT_PUBLIC_FIREBASE_APP_ID=
```

## Batasan yang diketahui

1. **Data masih demo.** Seluruh angka berasal dari `lib/demo*.ts` (data contoh
   Design.md) dan diberi label ilustrasi. Belum ada panggilan tulis ke Gateway.
2. **Static export + rute dinamis.** `/r/[code]` hanya digenerate untuk kode contoh
   (`DEMO12`, `UIN201`, `FST112`) karena `output: 'export'` memerlukan
   `generateStaticParams`. Produksi perlu rewrite Worker/Cloudflare Function untuk
   kode arbitrer.
3. **Kompresi WebP** hanya disimulasikan di web (berkas diperiksa ukurannya lalu
   dilaporkan); pemampatan sesungguhnya dilakukan modul gambar aplikasi.
4. **Tema terang** mengikuti mockup (Design.md temuan T-01), bukan tema gelap pada
   `PRD.md` §9.2.
5. Heatmap/garis `ProcessDraw` hanya digambar pada `lg+` (grid 1 baris) dan di bawah
   `md` (grid 1 kolom) karena grid 2 kolom tidak selaras dengan satu garis tunggal.