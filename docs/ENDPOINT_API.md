# Dokumen Endpoint API BRÛLÉ Mobile

Base URL (development): `http://127.0.0.1:8001/api` (lewat `adb reverse tcp:8001 tcp:8001`)
Format: JSON. Autentikasi: Laravel Sanctum, header `Authorization: Bearer <token>`.
Bahasa respons mengikuti header `Accept-Language: id|en` (notifikasi, pesan galat, FAQ). Pesan error validasi memakai status `422` dengan bentuk `{ "message": "...", "errors": { "field": ["..."] } }`.

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
| POST | `/recommend` | Kuis "Temukan kopimu". Body `drink` (`hitam`/`susu`), `taste` (`buah`/`bunga`/`cokelat`/`kacang`), `acid` (`suka`/`sedikit`/`tidak`). Respons `data[]` maksimal 3: `slug`, `name`, `image`, `profile_id`, `level`, `level_label`, `price_per_100g`, `tasting_notes[]`, `why`. Logika sama dengan `Recommend::rank()` di web. Nilai di luar pilihan dijawab 422 |
| GET | `/cart/shipping?subtotal=` | Ongkir dan sisa belanja untuk gratis ongkir dari subtotal keranjang: `shipping`, `free_shipping_from`, `free_shipping_gap` (0 bila sudah gratis atau promo dimatikan, yaitu batas 0) |
| GET | `/store` | Info toko publik: `name` dan `whatsapp` (format 62..., dari Pengaturan `contact_whatsapp`) untuk tombol chat |

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

**Objek pesanan**: `code`, `status`, `status_label`, `progress`, `step`, `steps[]` (`key`, `label`), `payment_method`, `is_paid`, `can_pay`, `can_cancel`, `can_request_cancel`, `cancel_requested_at`, `cancel_request_reason`, `invoice_url`, `tracking_number`, `subtotal`, `shipping_cost`, `addon_cost`, `discount`, `voucher_code`, `total`, `gift_wrap`, `card_message`, `recipient{name, phone, address}`, `created_at`, `items[]`.

**`can_cancel`** true hanya saat status `pending_payment` atau `queued`. Dari `roasting` sampai `completed` false, dan `POST /orders/{code}/cancel` dijawab 422 (stok biji yang sudah disangrai tidak bisa dikembalikan).

**`can_request_cancel`** true hanya saat status `roasting`, `grinding`, atau `packing` dan belum pernah diajukan (`Order::canRequestCancel()`). Pelanggan memanggil `POST /orders/{code}/cancel-request` dengan body `reason` (opsional, maksimal 160 karakter); hanya pemilik pesanan, selain itu 404. Ditolak 422 bila tidak boleh diajukan. Setelah diajukan `cancel_requested_at` dan `cancel_request_reason` terisi dan admin mendapat notifikasi. Di `GET /track/{code}` (tanpa login) `can_request_cancel` selalu false dan alasan selalu `null`.

**Jawab permintaan batal (admin)**: `POST /staff/orders/{code}/cancel-request/approve` membatalkan pesanan tanpa mengembalikan biji yang sudah disangrai (stok perlengkapan non-kopi tetap kembali), dan `/reject` menghapus permintaan sehingga pesanan lanjut. Hanya admin (roaster dan pelanggan 403); tanpa permintaan aktif dijawab 422. Detail staff memuat `can_resolve_cancel` dan `track_url` (`/lacak/{kode}`, dipakai tombol "Kirim resi via WA").

**`invoice_url`** link invoice bertanda tangan (`/invoice/{kode}?signature=...`, bisa dibuka tanpa login). Terisi hanya bila pesanan boleh dicetak (lunas atau COD, bukan batal), selain itu `null`. Selalu `null` di `GET /track/{code}` karena kode pesanan saja tidak boleh membuka invoice. Aplikasi membukanya di browser luar, bukan WebView.

**Status**: `pending_payment`, `queued`, `roasting`, `grinding`, `packing`, `shipped`, `completed`, `cancelled`. Pesanan yang hanya berisi perlengkapan melewati tahap `roasting` dan `grinding`.

### Favorit (Bearer)

| Method | Endpoint | Fungsi |
|---|---|---|
| GET | `/favorites` | `data[]` berisi id kopi favorit milik pengguna |
| POST | `/favorites/{coffee}` | Toggle favorit. `{coffee}` boleh slug atau id; hanya kopi aktif (selain itu 404). Respons `favorited` (true/false) dan `data[]` terbaru |

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
| POST | `/staff/orders/{code}/cancel-request/approve` | admin | Setujui permintaan batal dari pelanggan (biji yang sudah disangrai tidak kembali ke stok) |
| POST | `/staff/orders/{code}/cancel-request/reject` | admin | Tolak permintaan batal, pesanan lanjut |

Pelanggan yang memanggil endpoint staff menerima `403`.

### Menu admin lainnya (role admin)

| Method | Endpoint | Fungsi |
|---|---|---|
| GET | `/admin/reports?preset=` | Laporan penjualan: ringkasan, selisih periode lalu, seri harian, per kopi/level/produk/voucher |
| GET | `/admin/customers?tab=&sort=&q=&page=` | Pelanggan beserta statistik, total belanja, terakhir pesan |
| GET | `/admin/users?role=&q=&page=` | Semua pengguna dan jumlah per peran |
| POST | `/admin/users` | Buat akun staf: name, email, role (admin/roaster), password (admin) |
| PUT | `/admin/users/{id}` | Ubah peran; untuk akun staf juga name, email, phone, password (admin) |
| DELETE | `/admin/users/{id}` | Hapus akun staf (admin, bukan akun sendiri, sisakan minimal satu admin) |
| POST | `/admin/users/{id}/block` / `unblock` | Blokir atau buka blokir akun pembeli |
| GET, POST | `/admin/vouchers` | Daftar dan buat voucher |
| PUT, DELETE | `/admin/vouchers/{id}` | Ubah, hapus (hanya yang belum dipakai) |
| POST | `/admin/vouchers/{id}/toggle` | Aktif atau nonaktif |
| GET | `/admin/reviews?tampil=` | Moderasi ulasan |
| POST, DELETE | `/admin/reviews/{id}/toggle`, `/admin/reviews/{id}` | Sembunyikan atau hapus ulasan |
| GET | `/admin/coffees`, `/admin/products` | Daftar kopi dan produk |
| GET | `/admin/coffees/meta` | Daftar level sangrai, kunci rasa, dan pilihan proses untuk form kopi baru |
| GET | `/admin/coffees/{id}` | Detail kopi lengkap (cerita, asal-usul, profil per level sangrai) untuk form ubah (admin) |
| POST | `/admin/coffees` | Tambah kopi: name, story, stock, asal-usul (farmer, region, altitude, varietal, process), `profiles` per level (price, agtron, notes, flavors); stok awal dicatat sebagai pergerakan stok (admin) |
| PUT | `/admin/coffees/{id}` | Ubah kopi; level yang sudah pernah dipesan tidak bisa dimatikan (admin) |
| POST | `/admin/coffees/{id}/photo` | Unggah foto kopi (multipart, field `photo`, JPG/PNG/WebP maks 3 MB) |
| DELETE | `/admin/coffees/{id}/photo` | Hapus foto kopi |
| POST | `/admin/coffees/{id}/toggle`, `/admin/products/{id}/toggle` | Tampil atau sembunyi dari toko |
| GET | `/admin/products/{id}` | Detail perlengkapan untuk form ubah (admin) |
| POST | `/admin/products` | Tambah perlengkapan: name, category, description, price, stock, option_label, options (pisah koma), is_active (admin) |
| PUT | `/admin/products/{id}` | Ubah perlengkapan (admin) |
| POST | `/admin/products/{id}/photo` | Unggah foto produk (multipart, field `photo`, JPG/PNG/WebP maks 3 MB) |
| DELETE | `/admin/products/{id}/photo` | Hapus foto produk |
| GET | `/admin/logs?jenis=&page=` | Log aktivitas |
| GET, PUT | `/admin/settings` | Baca dan simpan pengaturan toko |
| GET | `/admin/reports/export?format=pdf\|xlsx&preset=` | Unduh laporan penjualan sebagai PDF atau Excel |
| GET | `/admin/stock/history?jenis=&kopi=&page=` | Riwayat stok masuk dan keluar beserta saldo |
| POST | `/admin/stock/coffees/{id}` | Stok biji: `mode` restock (masuk), waste (keluar), count (koreksi hitung), `amount` gram, `reason` |
| POST | `/admin/stock/products/{id}` | Tambah stok perlengkapan, `amount` unit |

## 8. Notifikasi, dokumen, dan login sosial

| Method | Path | Fungsi |
|---|---|---|
| GET | `/notices` | Daftar notifikasi pengguna (pesanan baru, pesanan >24 jam, stok menipis, ulasan, status) |
| GET | `/notices/unread` | Jumlah belum dibaca + notifikasi terbaru (dipolling tiap 45 detik) |
| POST | `/notices/{id}/read` | Tandai satu notifikasi dibaca |
| POST | `/notices/read-all` | Tandai semua dibaca |
| GET | `/orders/{code}/receipt` | Unduh struk PDF (pesanan lunas atau COD) |
| POST | `/orders/{code}/reorder` | Beli lagi: isi pesanan lama jadi baris keranjang (`lines[]`), `skipped` = jumlah item yang sudah tidak tersedia |
| GET | `/track/{code}` | Lacak pesanan publik tanpa login (tahapan dan isi pesanan saja, tanpa data penerima), throttle 30/menit |
| GET | `/help/{page}` | Isi halaman bantuan: `faq` atau halaman kebijakan (mengikuti `Accept-Language`) |
| GET | `/admin/orders/export?format=xlsx\|pdf&tab=&q=` | Ekspor daftar pesanan sesuai tab dan pencarian (admin) |
| GET | `/staff/labels?codes=A,B` | Unduh label paket PDF untuk satu atau banyak pesanan |
| POST | `/auth/exchange` | Tukar kode sekali pakai hasil login Google/Facebook jadi token |
| GET | `/auth/{google\|facebook}/mobile` (web) | Awal alur OAuth di Chrome Custom Tab, kembali ke `brule://oauth?code=` |

## 9. Ringkasan

Total 74 endpoint: 6 autentikasi dan akun, 7 katalog dan info toko, 5 buku alamat, 7 pesanan dan pembayaran, 2 favorit, 2 ulasan, 13 roaster dan admin inti, 24 menu admin lainnya. Autentikasi memakai token personal Sanctum (tabel `personal_access_tokens`).

## Bantuan dan bahasa

| Method | Endpoint | Auth | Fungsi |
|---|---|---|---|
| GET | `/help/{page}` | - | Isi halaman bantuan. `page`: `faq`, `shipping`, `terms`, `privacy`. Respons `{ data: { title, intro, groups|sections } }` |

`faq` berisi `groups[].items[]` (`q`, `a`); halaman lain berisi `sections[]` (`h`, `p[]`, `li[]`).
Kontak, ongkir, dan COD diisi dari Pengaturan toko. Bahasa mengikuti `Accept-Language`.
