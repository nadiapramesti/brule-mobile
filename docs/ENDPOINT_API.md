# Dokumen Endpoint API BRÛLÉ Mobile

Base URL (development): `http://127.0.0.1:8001/api` (lewat `adb reverse tcp:8001 tcp:8001`)
Format: JSON. Autentikasi: Laravel Sanctum, header `Authorization: Bearer <token>`.
Pesan error validasi memakai status `422` dengan bentuk `{ "message": "...", "errors": { "field": ["..."] } }`.

## 1. Autentikasi dan Akun

| Method | Endpoint | Auth | Fungsi |
|---|---|---|---|
| POST | `/register` | - | Daftar pelanggan baru, langsung mengembalikan token |
| POST | `/login` | - | Masuk (customer, roaster, admin), mengembalikan token dan data `user.role` |
| GET | `/me` | Bearer | Data akun yang sedang masuk |
| PUT | `/me` | Bearer | Ubah nama, email, nomor WhatsApp |
| PUT | `/me/password` | Bearer | Ubah password (token perangkat lain dicabut) |
| POST | `/logout` | Bearer | Keluar, token saat ini dihapus |

**POST /register**: body `name`, `email`, `phone` (opsional), `password`, `password_confirmation`. Respons `201`: `{ token, user: { id, name, email, phone, role } }`.
**POST /login**: body `email`, `password`. Respons `200`: `{ token, user }`. Error: `422` kredensial salah, `403` akun diblokir atau bukan customer. Dibatasi 6 percobaan per menit.
**PUT /me**: body `name`, `email`, `phone`. Respons: objek user terbaru.
**PUT /me/password**: body `current_password`, `password`, `password_confirmation`. Respons `{ "message": "ok" }`.

## 2. Katalog (publik, tanpa login)

| Method | Endpoint | Fungsi |
|---|---|---|
| GET | `/coffees` | Daftar kopi aktif, query opsional `q` untuk pencarian |
| GET | `/coffees/{slug}` | Detail kopi: cerita, asal biji (traceability), profil sangrai dan harga per 100 g |
| GET | `/gear` | Daftar perlengkapan, query opsional `q` |
| GET | `/gear/{slug}` | Detail perlengkapan: kategori, harga, stok, pilihan varian dan gambarnya |

Respons daftar berbentuk `{ "data": [ ... ] }`.

## 3. Buku Alamat (Bearer)

| Method | Endpoint | Fungsi |
|---|---|---|
| GET | `/addresses` | Daftar alamat milik pengguna (alamat utama paling atas) |
| POST | `/addresses` | Tambah alamat (maksimal 5; alamat pertama otomatis jadi utama) |
| PUT | `/addresses/{id}` | Ubah alamat |
| POST | `/addresses/{id}/default` | Jadikan alamat utama |
| DELETE | `/addresses/{id}` | Hapus alamat (jika utama, alamat lain dipromosikan) |

Body tambah/ubah: `label`, `recipient`, `phone` (format `08xx`/`+62`), `address` (minimal 15 karakter).

## 4. Pesanan dan Pembayaran (Bearer)

| Method | Endpoint | Fungsi |
|---|---|---|
| GET | `/orders` | 50 pesanan terakhir milik pengguna |
| POST | `/orders` | Buat pesanan dari keranjang |
| GET | `/orders/{code}` | Detail pesanan, tahap proses, dan item |
| POST | `/orders/{code}/pay` | Minta token Midtrans Snap dan `redirect_url` pembayaran |
| POST | `/orders/{code}/sync` | Sinkron status pembayaran ke Midtrans (pengganti webhook di localhost) |
| POST | `/orders/{code}/cancel` | Batalkan pesanan (hanya saat menunggu bayar atau di antrian) dan kembalikan stok |

**POST /orders**: body
```json
{
  "name": "Nadia Pramesti", "phone": "081234567890",
  "address": "Jl. Melati No. 5, Karawang, 41361",
  "payment": "online",
  "voucher": "HEMAT10", "gift_wrap": true, "card_message": "Selamat ulang tahun!",
  "items": [
    { "type": "coffee", "profile_id": 3, "grams": 250, "grind": "v60", "qty": 1 },
    { "type": "coffee", "profile_id": 3, "blend_profile_id": 9, "ratio": 70, "grams": 500, "grind": "whole_bean", "qty": 1 },
    { "type": "gear", "product_id": 7, "option": "Hitam", "qty": 2 }
  ]
}
```
`payment`: `online` atau `cod`. `grams`: 100, 200, 250, 500, 1000. `grind`: `whole_bean`, `v60`, `espresso`, `french_press`, `tubruk`, `aeropress`. Item blend memakai `blend_profile_id` (profil sangrai biji kedua) dan `ratio` (porsi biji pertama: 70, 60, atau 50). Syarat: dua kopi berbeda, aktif, dan tingkat sangrai sama. Gram dibagi `round(grams x ratio / 100)`, harga = harga biji pertama untuk porsinya + harga biji kedua untuk sisanya. Respons `201`: objek pesanan.

**Objek pesanan**: `code`, `status`, `status_label`, `progress`, `step`, `steps[]` (`key`, `label`), `payment_method`, `is_paid`, `can_pay`, `can_cancel`, `tracking_number`, `subtotal`, `shipping_cost`, `addon_cost`, `discount`, `voucher_code`, `total`, `gift_wrap`, `card_message`, `recipient{name, phone, address}`, `created_at`, `items[]`.

**Status**: `pending_payment`, `queued`, `roasting`, `grinding`, `packing`, `shipped`, `completed`, `cancelled`. Pesanan yang hanya berisi perlengkapan melewati tahap `roasting` dan `grinding`.

## 5. Alur Pembayaran Online (Midtrans Sandbox)

1. App memanggil `POST /orders` dengan `payment: online`, status awal `pending_payment`.
2. App memanggil `POST /orders/{code}/pay` dan mendapat `redirect_url`.
3. `redirect_url` dibuka di WebView; pelanggan membayar di halaman Midtrans Snap.
4. Setelah WebView ditutup, app memanggil `POST /orders/{code}/sync`; status berubah menjadi `queued` dan `is_paid = true`.
5. Pada server publik, notifikasi Midtrans masuk lewat webhook web yang sudah ada; `sync` tetap dipakai sebagai cadangan.

## 6. Ulasan Produk

| Method | Endpoint | Auth | Fungsi |
|---|---|---|---|
| GET | `/coffees/{slug}/reviews` | Opsional | `average`, `count`, `can_review`, `mine`, dan `data[]` ulasan |
| POST | `/coffees/{slug}/reviews` | Bearer | Tulis atau ubah ulasan sendiri: `rating` 1-5, `body` maksimal 600 karakter |

Ulasan hanya boleh ditulis pelanggan yang punya pesanan **selesai** berisi kopi tersebut (termasuk sebagai biji kedua blend).

## 7. Roaster dan Admin (Bearer, sesuai role)

| Method | Endpoint | Role | Fungsi |
|---|---|---|---|
| GET | `/staff/queue?stage=&q=&late=&sort=&page=` | roaster, admin | Antrian satu tahap per halaman (20 pesanan), ringkasan keempat tahap, statistik, rencana sangrai |
| GET | `/staff/orders/{code}` | roaster, admin | Detail pesanan untuk produksi |
| POST | `/staff/orders/{code}/advance` | roaster, admin | Maju ke tahap berikutnya (queued, roasting, grinding, packing) |
| POST | `/staff/orders/{code}/ship` | roaster, admin | Tandai dikirim, body `tracking_number` (resi) |
| POST | `/staff/orders/advance` | roaster, admin | Majukan banyak pesanan sekaligus, body `codes[]` (tahap Dikemas dilewati karena butuh resi) |
| GET | `/staff/stock` | roaster, admin | Stok biji mentah (sama dengan `/admin/stock`) |
| GET | `/admin/dashboard?days=7` | admin | Pendapatan, jumlah pesanan, perlu perhatian, grafik harian, kopi terlaris, stok menipis |
| GET | `/admin/orders?tab=&q=&page=` | admin | Semua pesanan dengan filter tab, pencarian, paginasi |
| GET | `/admin/stock` | admin | Stok kopi (gram) dan perlengkapan (unit) |
| POST | `/admin/orders/{code}/complete` | admin | Tandai pesanan selesai |
| POST | `/admin/orders/{code}/cancel` | admin | Batalkan pesanan dan kembalikan stok, body `reason` |

Pelanggan yang memanggil endpoint staff menerima `403`.

### Menu admin lainnya (role admin)

| Method | Endpoint | Fungsi |
|---|---|---|
| GET | `/admin/reports?preset=` | Laporan penjualan: ringkasan, selisih periode lalu, seri harian, per kopi/level/produk/voucher |
| GET | `/admin/customers?tab=&sort=&q=&page=` | Pelanggan beserta statistik, total belanja, terakhir pesan |
| GET | `/admin/users?role=&q=&page=` | Semua pengguna dan jumlah per peran |
| POST | `/admin/users/{id}/block` / `unblock` | Blokir atau buka blokir akun pembeli |
| GET, POST | `/admin/vouchers` | Daftar dan buat voucher |
| PUT, DELETE | `/admin/vouchers/{id}` | Ubah, hapus (hanya yang belum dipakai) |
| POST | `/admin/vouchers/{id}/toggle` | Aktif atau nonaktif |
| GET | `/admin/reviews?tampil=` | Moderasi ulasan |
| POST, DELETE | `/admin/reviews/{id}/toggle`, `/admin/reviews/{id}` | Sembunyikan atau hapus ulasan |
| GET | `/admin/coffees`, `/admin/products` | Daftar kopi dan produk |
| POST | `/admin/coffees/{id}/toggle`, `/admin/products/{id}/toggle` | Tampil atau sembunyi dari toko |
| GET | `/admin/logs?jenis=&page=` | Log aktivitas |
| GET, PUT | `/admin/settings` | Baca dan simpan pengaturan toko |
| GET | `/admin/reports/export?format=pdf\|xlsx&preset=` | Unduh laporan penjualan sebagai PDF atau Excel |
| GET | `/admin/stock/history?jenis=&kopi=&page=` | Riwayat stok masuk dan keluar beserta saldo |
| POST | `/admin/stock/coffees/{id}` | Stok biji: `mode` restock (masuk), waste (keluar), count (koreksi hitung), `amount` gram, `reason` |
| POST | `/admin/stock/products/{id}` | Tambah stok perlengkapan, `amount` unit |

## 8. Ringkasan

Total 58 endpoint: 6 autentikasi dan akun, 4 katalog, 5 buku alamat, 6 pesanan dan pembayaran, 2 ulasan, 11 roaster dan admin inti, 24 menu admin lainnya. Autentikasi memakai token personal Sanctum (tabel `personal_access_tokens`).
