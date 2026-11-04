# Safe Change Rules — Campus Express

SOP perubahan aman untuk aplikasi, Gateway, Firestore, dan R2. Tujuannya: setiap perubahan dapat diuji, dipantau, dan dibatalkan tanpa mengorbankan data atau saldo pengguna.

## 1. Prinsip

| # | Prinsip |
|---|---|
| 1 | Perubahan kecil dan sering lebih aman daripada rilis besar |
| 2 | Tidak ada perubahan langsung ke produksi dari laptop; semua lewat CI/CD |
| 3 | Setiap perubahan punya rencana rollback sebelum dieksekusi |
| 4 | Skema data berubah dengan pola expand → migrate → contract, tidak pernah dalam satu langkah |
| 5 | Wallet, komisi, PIN, dan rules adalah area berisiko tinggi dan memerlukan dua peninjau |
| 6 | Jika ragu, matikan lewat kill switch daripada mempercepat perbaikan |

## 2. Klasifikasi Perubahan

| Kelas | Contoh | Peninjau | Jendela rilis | Rollback |
|---|---|---|---|---|
| Rendah | Teks, gaya, landing statis | 1 | Kapan saja | Revert deploy |
| Sedang | Fitur klien baru di balik flag, endpoint Gateway baru | 1 + tes hijau | Hari kerja, di luar jam sibuk (11.00–13.30 dan 17.00–20.00) | Matikan flag, revert |
| Tinggi | Rules, skema Firestore, wallet/komisi, mesin status order, unggah R2 | 2 + tes keamanan | Jam sepi (mis. 21.00–23.00) dan bukan akhir pekan padat | Rencana rollback tertulis dan diuji di staging |
| Darurat | Perbaikan insiden produksi | 1 peninjau cepat + tinjauan pasca-kejadian | Segera | Kill switch dahulu |

## 3. Lingkungan dan Alur Cabang

| Lingkungan | Pemicu deploy | Data |
|---|---|---|
| `dev` | Setiap push ke cabang fitur (opsional) | Emulator/data sintetis |
| `staging` | Merge ke `develop` | Data sintetis |
| `prod` | Tag `vX.Y.Z` pada `main` + persetujuan manual | Data nyata |

Alur: `feature/*` → PR ke `develop` → staging → PR `develop` → `main` → tag → produksi.

## 4. Gerbang CI/CD

### 4.1 Pipeline Per Komponen

| Komponen | Langkah | Gagal berarti |
|---|---|---|
| Flutter | `flutter analyze`, `flutter test`, build APK rilis, ukuran APK ≤ 40 MB | Blokir merge |
| Next.js | `lint`, `tsc --noEmit`, `test`, `build`, `npm audit --audit-level=high` | Blokir merge |
| Gateway | `tsc`, tes unit, tes konkurensi klaim, tes idempotensi komisi, `wrangler deploy --dry-run` | Blokir merge |
| Rules | Tes emulator untuk semua koleksi dan transisi | Blokir merge |
| Rahasia | `gitleaks` | Blokir merge |

### 4.2 Aturan Deploy

| Aturan | Detail |
|---|---|
| Urutan | Rules/indeks → Gateway → web → aplikasi (agar klien lama dan baru tetap kompatibel) |
| Persetujuan | Environment `prod` di GitHub memerlukan persetujuan manual |
| Indeks Firestore | Dideploy dan menunggu status `READY` sebelum kode yang memakainya dirilis |
| Rilis Android | Internal testing → closed testing → produksi bertahap 5% → 20% → 50% → 100% |
| Rilis iOS | TestFlight → rilis bertahap |
| Catatan rilis | Berisi perubahan, kelas risiko, rencana rollback, penanggung jawab |

## 5. Aturan Migrasi Firestore

Firestore tidak memiliki skema paksa, jadi disiplin dilakukan lewat kode dan prosedur.

### 5.1 Pola Expand → Migrate → Contract

| Tahap | Aksi | Kompatibilitas |
|---|---|---|
| 1. Expand | Tambah field/koleksi baru dengan nilai default; kode baru menulis keduanya (lama dan baru) | Klien lama tetap berfungsi |
| 2. Migrate | Skrip backfill idempoten memproses dokumen lama dalam batch | Dapat dihentikan dan dilanjutkan |
| 3. Switch | Kode membaca dari field baru; flag mengatur peralihan | Klien lama masih memakai field lama |
| 4. Contract | Setelah klien lama < 2% (lihat `minAppVersion`), hapus field lama dan kode terkait | Tidak dapat dibatalkan; lakukan hanya setelah pemantauan 14 hari |

### 5.2 Ketentuan

| Kode | Aturan |
|---|---|
| MG-1 | Setiap dokumen mutable memiliki `schemaVersion`; kode membaca sesuai versi. |
| MG-2 | Skrip migrasi berada di `tools/migrations/NNN-nama.ts`, memiliki mode `--dry-run`, mencatat jumlah dokumen, dan idempoten. |
| MG-3 | Batas batch 400 operasi; jeda antar batch; hormati kuota tulis harian (migrasi besar dijalankan di luar jam sibuk dan dianggarkan terhadap kuota). |
| MG-4 | Cadangan ekspor Firestore dibuat sebelum migrasi kelas Tinggi. |
| MG-5 | Migrasi diuji di staging dengan salinan data sintetis berukuran setara. |
| MG-6 | Perubahan nama field dilakukan sebagai tambah-lalu-hapus, bukan rename langsung. |
| MG-7 | Perubahan tipe field memakai field baru, bukan mengubah tipe pada field yang sama. |
| MG-8 | Dokumen finansial (`wallets`, `walletTx`) tidak dimigrasi dengan menimpa; setiap koreksi berupa transaksi `adjustment` baru dengan audit. |
| MG-9 | Indeks dihapus hanya setelah memastikan tidak ada query yang bergantung padanya. |
| MG-10 | Perubahan struktur `merchantMenus` memperhatikan batas 1 MiB per dokumen; pantau ukuran dokumen terbesar. |

### 5.3 Rules

| Aturan | Detail |
|---|---|
| Versi | Rules disimpan di repo; setiap rilis rules memiliki tag |
| Uji | Tes emulator wajib untuk setiap koleksi, termasuk kasus ditolak |
| Rilis | Perubahan rules yang memperketat dirilis setelah klien baru tersebar; yang melonggarkan memerlukan dua peninjau |
| Pemantauan | Setelah rilis, pantau lonjakan `permission-denied` di Crashlytics selama 2 jam |

## 6. Feature Flag dan Kill Switch

Dikelola lewat Remote Config.

| Flag | Fungsi | Nilai bawaan |
|---|---|---|
| `minAppVersion` | Memaksa pembaruan aplikasi | Versi stabil minimum |
| `chatEnabled` | Matikan chat bila kuota/insiden | true |
| `trackingEnabled` | Matikan pembaruan checkpoint | true |
| `map3dEnabled` | Paksa mode 2D | true |
| `newOrdersEnabled` | Pause order baru | true |
| `walletTopupEnabled` | Pause top-up | true |
| `landingPingsEnabled` | Matikan Sales Pings | true |
| `claimV2Enabled` | Contoh flag fitur baru | false |

Aturan: fitur baru berisiko Sedang ke atas dirilis dengan flag mati, dinyalakan untuk 5% → 25% → 100%, dan flag dihapus dari kode setelah stabil dua rilis.

## 7. Aturan Khusus Area Berisiko Tinggi

| Area | Aturan tambahan |
|---|---|
| Wallet dan komisi | Perubahan wajib menyertakan tes rekonsiliasi: Σ `walletTx` = `balance`; tidak ada perubahan saat ada order aktif tanpa rencana |
| Mesin status order | Perubahan transisi memperbarui diagram, tabel transisi, dan tes rules sekaligus |
| PIN | Tidak boleh dicatat di log; perubahan algoritma menjaga kompatibilitas order aktif |
| Unggah R2 | Perubahan batas ukuran/tipe menyertakan tes berkas berbahaya |
| Rules | Dua peninjau; tidak ada `if true` sementara |
| ETA | Perubahan rumus disertai tes numerik (contoh: 1.200 m pada 20 km/jam = 216 dtk) |

## 8. Rencana Rollback

| Komponen | Cara rollback | Perkiraan waktu |
|---|---|---|
| Gateway | `wrangler rollback` ke versi sebelumnya atau deploy ulang tag sebelumnya | < 5 menit |
| Web (Pages/Hosting) | Rollback ke deployment sebelumnya dari dashboard | < 5 menit |
| Aplikasi Android | Hentikan rilis bertahap; naikkan `minAppVersion` tidak dilakukan untuk rollback; rilis versi perbaikan dengan kode sebelumnya; matikan flag fitur | Jam; mitigasi segera via flag |
| Rules | Deploy ulang versi rules sebelumnya dari tag | < 10 menit |
| Indeks | Biarkan indeks baru (tidak berbahaya); hapus nanti | — |
| Data (migrasi) | Pulihkan dari ekspor hanya sebagai opsi terakhir; sebelumnya gunakan jalur "switch" kembali ke field lama (tahap 1–3 masih menulis keduanya) | Menit hingga jam |
| Konfigurasi | Kembalikan versi Remote Config sebelumnya | Menit |

Tidak ada rollback untuk tahap Contract; karena itu tahap tersebut menunggu masa pemantauan.

## 9. Prosedur Rilis (Checklist)

| ✓ | Langkah |
|---|---|
| [ ] | PR menyertakan kelas perubahan, dampak, dan rencana rollback |
| [ ] | Peninjau sesuai kelas menyetujui |
| [ ] | CI hijau (analisis, tes, rules, rahasia) |
| [ ] | Staging diuji: alur order penuh (konsumen, merchant, driver), chat, wallet, tracking |
| [ ] | Cadangan Firestore dibuat bila kelas Tinggi |
| [ ] | Rilis dilakukan pada jendela yang sesuai |
| [ ] | Pantau 2 jam: crash-free, error Gateway, `permission-denied`, kuota, latensi klaim |
| [ ] | Catatan rilis dan perubahan diumumkan ke tim; admin diberi tahu bila berdampak |

## 10. Respons Insiden

| Tingkat | Definisi | Respons |
|---|---|---|
| SEV1 | Order tidak bisa dibuat/diselesaikan, saldo salah, kebocoran data | Aktifkan kill switch terkait, rollback, komunikasi ke pengguna ≤ 30 menit |
| SEV2 | Fitur utama degradasi (chat/tracking), kuota hampir habis | Matikan fitur non-esensial via flag, perbaiki dalam 24 jam |
| SEV3 | Bug minor | Masuk antrean |

Pasca-insiden: tinjauan tanpa menyalahkan dalam 7 hari, tindakan perbaikan dicatat dan ditinjau pada rilis berikutnya.

## 11. Pencadangan dan Pemulihan

| Data | Metode | Frekuensi | Uji pulih |
|---|---|---|---|
| Firestore | Ekspor terjadwal ke bucket terpisah | Mingguan (harian bila volume tinggi) | Per kuartal |
| R2 privat | Replikasi/sinkronisasi ke bucket cadangan | Mingguan | Per kuartal |
| Konfigurasi | Disimpan di repo (rules, indeks, flag template) | Setiap perubahan | Tiap deploy |
| Wallet | Ledger `walletTx` tidak dihapus; ekspor CSV bulanan | Bulanan | Rekonsiliasi bulanan |

Catatan: ekspor Firestore terjadwal mungkin memerlukan layanan yang tidak termasuk dalam paket gratis; verifikasi ketersediaan dan biayanya sebelum mengandalkan jadwal otomatis, atau gunakan skrip ekspor manual berkala.