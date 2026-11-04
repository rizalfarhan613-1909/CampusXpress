# UserRole — Matriks RBAC Campus Express

## 1. Model Peran

| Peran | Kode | Cara memperoleh | Disimpan di | Catatan |
|---|---|---|---|---|
| Konsumen | `consumer` | Otomatis setelah login dan profil lengkap | `users.roles` | Default semua pengguna |
| Driver | `driver` | Pengajuan + verifikasi admin | `users.roles` dan `driverProfiles.status == 'approved'` | Peran aktif hanya jika `approved` |
| Merchant | `merchant` | Pengajuan + verifikasi admin | `users.roles` dan `merchants.status == 'approved'` | Satu pemilik dapat memiliki satu merchant pada v1 |
| Admin | `admin` | Hanya lewat custom claim oleh pemilik proyek | Firebase Auth custom claim `admin: true` | Tidak disimpan sebagai field yang dapat ditulis klien |

Aturan dasar:

| Kode | Aturan |
|---|---|
| RB-1 | Satu akun dapat memegang banyak peran (mis. konsumen + driver); `activeRole` menentukan antarmuka, bukan hak akses; hak akses ditentukan oleh peran yang disetujui. |
| RB-2 | Pengguna `suspended` kehilangan seluruh hak kecuali membuka Help Desk dan melihat status akun. |
| RB-3 | Pada order yang sama, satu pengguna tidak boleh menjadi konsumen sekaligus driver. |
| RB-4 | Pemisahan tugas: admin yang mengajukan penyesuaian saldo tidak dapat menyetujuinya sendiri. |
| RB-5 | Hak akses ditegakkan di Firestore Rules dan Gateway; UI hanya menyembunyikan, tidak melindungi. |

## 2. Legenda

| Simbol | Arti |
|---|---|
| C | Create |
| R | Read |
| U | Update (terbatas pada field/transisi yang disebut) |
| D | Delete |
| — | Tidak diizinkan |
| (own) | Hanya data milik sendiri |
| (part) | Hanya sebagai peserta order |
| (GW) | Hanya melalui Gateway; klien langsung tidak boleh menulis |

## 3. Matriks Akses Data

| Sumber daya | Konsumen | Driver | Merchant | Admin |
|---|---|---|---|---|
| `users` (profil) | R, U (own; field profil) | R, U (own) | R, U (own) | R (semua), U status via GW |
| `users.roles`, `status`, `strikes` | R (own) | R (own) | R (own) | U (GW) |
| `driverProfiles` | — | C, R, U (own; dokumen, `online`) | — | R, U status (GW) |
| Dokumen KTM/SIM (R2 privat) | — | C (own) | — | R (GW, URL jangka pendek, tercatat) |
| `merchants` | R (approved, publik) | R (approved) | C, R, U (own) | R, U status (GW) |
| `merchantMenus` | R | R | C, R, U (own) | R, D |
| `landmarks`, `zones`, `fareMatrix` | R | R | R | C, R, U, D |
| `config/*` | R | R | R | U (GW) |
| `orders` | C (own), R (own), U (batal sebelum klaim) | R (`AWAITING_DRIVER` terfinalisasi), R/U (part: checkpoint) | R/U (own merchant: terima, tolak, siap) | R, U (GW; dispute/batal) |
| `orders` → `CLAIMED` | — | U (GW) | — | — |
| `orders` → `COMPLETED` | — | U (GW) | U (GW; ambil sendiri) | U (GW; dispute) |
| `orders/*/events` | R (part) | R (part) | R (part) | R |
| `orders/*/secrets/handover` | R (own) | — | — | — |
| `chats` | R (part) | R (part) | R (part) | R (hanya pada dispute/laporan) |
| `chats/*/messages` | C, R (part) | C, R (part) | C, R (part) | R (dispute), U (flag/hapus via GW) |
| `wallets` | — | R (own) | — | R, U (GW) |
| `walletTx` | — | R (own) | — | R, U (GW) |
| Top-up (pengajuan) | — | C (GW, own) | — | R, U (GW; setujui/tolak) |
| `reviews` | C (own, sekali), R | R (about own) | R (about own) | R, U (sembunyikan, GW) |
| `disputes` | C, R (part) | C, R (part) | C, R (part) | R, U (GW) |
| `referrals` | R (own) | R (own) | — | R |
| `salesPings`, `stats` | R (publik via GW) | R (publik) | R (publik) | R |
| `auditLogs` | — | — | — | R |
| `nimIndex` | — | — | — | — (hanya GW) |

## 4. Matriks Fitur Aplikasi

| Fitur | Konsumen | Driver | Merchant | Admin |
|---|---|---|---|---|
| Login Google SSO | ✔ | ✔ | ✔ | ✔ |
| Memesan layanan | ✔ | — | — | — |
| Melihat katalog | ✔ | ✔ | ✔ | ✔ |
| Checkout COD/QRIS | ✔ | — | — | — |
| Melacak order (peta 3D) | ✔ (own) | ✔ (order aktif) | ✔ (order pesanan merchant, tanpa posisi detail pasca-handover) | ✔ |
| Radar order | — | ✔ (approved, online) | — | — |
| Klaim order | — | ✔ (saldo cukup) | — | — |
| Konfirmasi checkpoint | — | ✔ | — | — |
| Memasukkan PIN | — | ✔ | — | — |
| Menampilkan PIN | ✔ | — | — | — |
| Chat order | ✔ | ✔ | ✔ | — (lihat hanya pada dispute) |
| Top-up wallet | — | ✔ | — | — |
| Buka/Tutup toko | — | — | ✔ | ✔ (paksa tutup) |
| Terima/Tolak order | — | — | ✔ | — |
| Kelola menu | — | — | ✔ | ✔ (moderasi) |
| Pengaturan toko dan payout | — | — | ✔ | ✔ (lihat) |
| Beri rating | ✔ | — | — | — |
| Buka dispute | ✔ | ✔ | ✔ | — |
| Putuskan dispute | — | — | — | ✔ |
| Verifikasi driver/merchant | — | — | — | ✔ |
| Setujui top-up | — | — | — | ✔ (dua admin ≥ Rp 200.000) |
| Kelola landmark, zona, tarif | — | — | — | ✔ |
| Suspend/aktifkan akun | — | — | — | ✔ |
| Tinjau laporan chat | — | — | — | ✔ |
| Lihat laporan agregat | — | — | ✔ (milik sendiri) | ✔ |
| Referral dan tautan undangan | ✔ | ✔ | ✔ | — |

## 5. Matriks Per Layar (22 Layar)

| # | Layar | Konsumen | Driver | Merchant | Admin |
|---|---|---|---|---|---|
| 1 | Onboarding & Role Selector | ✔ | ✔ | ✔ | — |
| 2 | Auth & NIM | ✔ | ✔ | ✔ | ✔ |
| 3 | Consumer Home | ✔ | — | — | — |
| 4 | Landmark & Zone Picker | ✔ | ✔ | — | — |
| 5 | Merchant Catalog | ✔ | — | — | — |
| 6 | Menu Customizer | ✔ | — | — | — |
| 7 | Cart & Checkout | ✔ | — | — | — |
| 8 | Live 3D Tracking & ETA | ✔ | — | — | — |
| 9 | Driver Order Radar | — | ✔ | — | — |
| 10 | Driver Active Job | — | ✔ | — | — |
| 11 | Driver Wallet & Top-Up | — | ✔ | — | — |
| 12 | Merchant Dashboard | — | — | ✔ | — |
| 13 | Merchant Incoming Order | — | — | ✔ | — |
| 14 | Profile & Review Shuffle | ✔ | ✔ | ✔ | — |
| 15 | Admin Panel | — | — | — | ✔ |
| 16 | In-App Chat | ✔ | ✔ | ✔ | — |
| 17 | Menu Management | — | — | ✔ | — |
| 18 | Order History & E-Receipt | ✔ | ✔ | ✔ | — |
| 19 | Rating & Review | ✔ | — | — | — |
| 20 | Driver Registration | — | ✔ (calon driver) | — | — |
| 21 | Store Settings & Payout | — | — | ✔ | — |
| 22 | Dispute & Help Desk | ✔ | ✔ | ✔ | ✔ (tinjau) |

## 6. Hak Admin Terperinci

| Sub-peran (kebijakan operasional) | Cakupan | Catatan |
|---|---|---|
| Admin Verifikator | Persetujuan driver/merchant, melihat KTM/SIM | Akses dokumen tercatat |
| Admin Keuangan | Persetujuan top-up, penyesuaian saldo, rekonsiliasi | Dua persetujuan untuk ≥ Rp 200.000 |
| Admin Moderasi | Dispute, laporan chat, strike, suspend | Tidak membaca chat tanpa laporan/dispute |
| Admin Sistem | Landmark, zona, tarif, konfigurasi | Perubahan tarif dicatat dan diumumkan |
| Pemilik Proyek | Pemberian claim admin | Satu-satunya yang dapat menambah admin |

Sub-peran diimplementasikan sebagai custom claim tambahan (`adminScope: ['verify','finance','moderate','system']`); `admin: true` tanpa scope tidak memiliki hak aksi.

## 7. Siklus Hidup Peran

| Peristiwa | Aturan |
|---|---|
| Pengajuan driver | Status `pending_docs` → `pending_review` → `approved`/`rejected`; ditolak harus menyertakan alasan; dapat mengajukan ulang setelah memperbaiki |
| Pengajuan merchant | `pending` → `approved`/`rejected` |
| Pencabutan | Admin mengubah status → `suspended`; Gateway mencabut token refresh; order aktif ditangani manual |
| Peningkatan ke admin | Skrip Gateway terkontrol (`ADMIN_BOOTSTRAP_TOKEN`), tercatat di `auditLogs`, hanya oleh pemilik proyek |
| Penurunan | Menghapus claim admin; token dicabut |
| Tinjauan berkala | Daftar admin dan hak ditinjau bulanan |

## 8. Pemetaan Penegakan Teknis

| Lapisan | Mekanisme |
|---|---|
| Custom claim cermin | Gateway menyalin status ke token (`driver: true`, `merchantId`, `suspended`, `admin`, `adminScope`) agar rules tidak perlu membaca dokumen `users` pada jalur panas; claim diperbarui saat persetujuan, pencabutan, atau suspend, disertai pencabutan refresh token |
| Firestore Rules | Fungsi `isConsumer()`, `isApprovedDriver()`, `isMerchantOwner(id)`, `isAdmin()`, `isParticipant(order)`; batasi field via `affectedKeys().hasOnly(...)` |
| Gateway | Verifikasi ID token → muat peran → cek kepemilikan/status → eksekusi; respons 403 untuk peran tidak sesuai |
| Aplikasi | Navigasi dan tombol disembunyikan sesuai peran; bukan kontrol keamanan |
| Audit | Setiap aksi admin dan perubahan peran mencatat `actorUid`, aksi, target, sebelum/sesudah |

## 9. Kasus Uji RBAC (Wajib di CI)

| # | Skenario | Hasil yang diharapkan |
|---|---|---|
| 1 | Konsumen menulis `users.roles` | Ditolak |
| 2 | Konsumen membaca `wallets` driver | Ditolak |
| 3 | Driver non-approved membaca radar | Ditolak |
| 4 | Driver membaca order `CLAIMED` milik driver lain | Ditolak |
| 5 | Driver mengubah `pricing` order | Ditolak |
| 6 | Merchant membaca order merchant lain | Ditolak |
| 7 | Non-partisipan membaca `chats/{id}/messages` | Ditolak |
| 8 | Driver membaca `orders/{id}/secrets/handover` | Ditolak |
| 9 | Klien mencoba `status = 'COMPLETED'` | Ditolak |
| 10 | Pengguna `suspended` membuat order | Ditolak |
| 11 | Admin tanpa scope `finance` menyetujui top-up | 403 di Gateway |
| 12 | Admin keuangan menyetujui top-up buatannya sendiri ≥ Rp 200.000 | Ditolak (pemisahan tugas) |