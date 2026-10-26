# Daftar Layar Aplikasi BRÛLÉ Mobile dan Checklist Screenshot

Aplikasi Android (Flutter). Katalog bisa dijelajahi tanpa login; belanja dan checkout butuh akun.

| No | Layar | File | Isi singkat | Perlu login |
|---|---|---|---|---|
| 1 | Beranda | `home_tab.dart` | Pencarian, banner geser, pintasan, rak Kopi Pilihan dan Perlengkapan, jaminan, tahap setelah bayar | Tidak |
| 2 | Katalog Kopi | `catalog_tab.dart` | Cari, filter proses, kartu kopi dengan ilustrasi kantong dan tombol tambah | Tidak |
| 3 | Katalog Perlengkapan | `gear_tab.dart` | Cari alat seduh, kartu produk dengan tombol tambah | Tidak |
| 4 | Detail Kopi | `coffee_detail_screen.dart` | Pilih sangrai, berat, gilingan, jumlah; detail lot dan asal biji | Tambah ke keranjang |
| 5 | Detail Perlengkapan | `gear_detail_screen.dart` | Gambar, pilihan varian, jumlah | Tambah ke keranjang |
| 6 | Sheet Pilihan Tambah | `add_sheet.dart` | Menu pilihan cepat dari kartu (sangrai/berat/gilingan atau varian) | Ya |
| 7 | Keranjang | `cart_tab.dart` | Daftar barang, ubah jumlah, hapus, bar total dan tombol Checkout di bawah | Checkout |
| 8 | Checkout | `checkout_screen.dart` | Kartu alamat tersimpan, pembayaran, voucher, kado, ringkasan, Buat Pesanan | Ya |
| 9 | Pembayaran Midtrans | `payment_screen.dart` | WebView Snap sandbox | Ya |
| 10 | Daftar Pesanan | `orders_tab.dart` | Riwayat pesanan beserta status | Ya |
| 11 | Detail Pesanan | `order_detail_screen.dart` | Tahap proses (antrian sampai kirim), item, rincian biaya, bayar/batalkan | Ya |
| 12 | Akun | `account_tab.dart` | Kartu profil, menu, keluar; tampilan tamu bila belum masuk | Sebagian |
| 13 | Edit Profil | `edit_profile_screen.dart` | Ubah nama, email, nomor WhatsApp | Ya |
| 14 | Ubah Password | `password_screen.dart` | Password lama dan baru | Ya |
| 15 | Buku Alamat | `addresses_screen.dart` | Daftar alamat, tambah, edit, jadikan utama, hapus; mode pilih dari checkout | Ya |
| 16 | Form Alamat | `addresses_screen.dart` | Tambah atau ubah alamat | Ya |
| 17 | Masuk | `login_screen.dart` | Form login dan tautan daftar | Tidak |
| 18 | Daftar Akun | `register_screen.dart` | Form pendaftaran pelanggan baru | Tidak |
| 19 | Racik Blend | `blend_screen.dart` | Pilih dua kopi, tingkat sangrai, porsi 70/60/50, pratinjau rasa dan harga, tambah ke keranjang | Tambah ke keranjang |
| 20 | Ulasan Pembeli | `reviews_section.dart` | Rata-rata bintang, daftar ulasan, sheet tulis atau ubah ulasan (di Detail Kopi) | Menulis ulasan |
| 21 | Antrian Roaster | `staff/queue_tab.dart` | Antrian produksi, rencana sangrai, cari dan filter terlambat, pilih banyak lalu lanjutkan sekaligus | Ya (roaster/admin) |
| 22 | Detail Pesanan Staf | `staff/staff_order_screen.dart` | Item, alamat, aksi maju tahap, kirim dengan resi, selesai, batalkan | Ya (roaster/admin) |
| 23 | Dashboard Admin | `staff/admin_dashboard_tab.dart` | KPI, grafik pendapatan harian, status, kopi terlaris, stok menipis | Ya (admin) |
| 24 | Pesanan Admin | `staff/admin_orders_tab.dart` | Semua pesanan, filter tab, pencarian, paginasi | Ya (admin) |
| 25 | Stok Admin | `staff/admin_stock_tab.dart` | Stok kopi dan perlengkapan, penanda stok menipis | Ya (admin) |
| 26 | Menu Admin | `staff/admin_menu_tab.dart` | Pintu ke semua menu panel web, kartu akun, keluar | Ya (admin) |
| 27 | Laporan | `staff/admin_report_screen.dart` | Omzet, pembanding periode lalu, grafik, kopi terlaris, unduh PDF dan Excel | Ya (admin) |
| 28 | Pelanggan | `staff/admin_customers_screen.dart` | Statistik, filter, urutan, pencarian | Ya (admin) |
| 29 | Pengguna | `staff/admin_users_screen.dart` | Semua peran, blokir/buka blokir | Ya (admin) |
| 30 | Voucher | `staff/admin_vouchers_screen.dart` | Daftar, buat, ubah, aktif/mati, hapus | Ya (admin) |
| 31 | Ulasan Admin | `staff/admin_reviews_screen.dart` | Sembunyikan, tampilkan, hapus ulasan | Ya (admin) |
| 32 | Kopi dan Produk | `staff/admin_catalog_screen.dart` | Harga, stok, tampil/sembunyi dari toko | Ya (admin) |
| 33 | Log Aktivitas | `staff/admin_logs_screen.dart` | Riwayat perubahan dengan filter jenis | Ya (admin) |
| 34 | Pengaturan Toko | `staff/admin_settings_screen.dart` | Identitas, kontak, ongkir, add-on, COD, batas stok | Ya (admin) |
| 35 | Riwayat Stok | `staff/stock_history_screen.dart` | Barang masuk dan keluar, saldo, pelaku, alasan; filter jenis dan kopi | Ya (admin) |
| 36 | Form Stok | `staff/stock_sheets.dart` | Masuk (restock), keluar (susut), koreksi hitung, tambah unit perlengkapan | Ya (admin) |

## Checklist screenshot untuk laporan

Urutan alur disarankan:

1. Beranda (atas) dan beranda (rak produk, scroll ke bawah)
2. Katalog Kopi dan Katalog Perlengkapan
3. Detail Kopi (pilihan sangrai, berat, gilingan) dan Sheet Pilihan Tambah
4. Layar Masuk dengan keterangan "Masuk dulu untuk mulai belanja" (mode tamu)
5. Daftar Akun
6. Keranjang dengan 2-3 barang (bar total di bawah)
7. Buku Alamat dan Form Alamat
8. Checkout (kartu alamat, ringkasan, tombol Buat Pesanan)
9. Pembayaran Midtrans (halaman Snap sandbox)
10. Detail Pesanan sesudah bayar (stepper Antrian sampai Kirim, status Indonesia)
11. Daftar Pesanan
12. Akun, Edit Profil, Ubah Password
13. Racik Blend (pilih dua kopi, pratinjau rasa) dan Detail Kopi bagian ulasan
14. Akun **roaster** (`roaster@brule.test`): Antrian (termasuk pilih banyak), Stok biji, Detail Pesanan Staf (sebelum dan sesudah ubah status)
15. Akun **admin** (`admin@brule.test`): Dashboard, Pesanan, Antrian, Stok

Tips: aktifkan mode jam tetap/baterai penuh sebelum screenshot, dan pakai data uji yang rapi (nama dan alamat yang wajar).

## Tambahan terbaru

- **Notifikasi**: ikon lonceng di header (pelanggan dan staf), halaman daftar notifikasi, banner saat ada yang baru
- **Linimasa pesanan**: tahap vertikal bertanda waktu, sama seperti di web (pelanggan dan staf)
- **Login**: kotak "Ingat saya", tombol Google dan Facebook
- **Struk dan label**: tombol Unduh Struk (pelanggan, bawah layar), Unduh Label Paket (staf, hanya di detail pesanan setelah nomor resi diisi)

- **Motion**: transisi halaman (fade + geser), daftar muncul bertahap, perpindahan tab memudar, bel bergoyang saat ada notifikasi baru, grafik dan bar stok tumbuh saat dibuka
- **Pilihan (chip)**: selalu satu baris; bila melebihi layar bisa digeser dan muncul tombol panah > di tepi

## Bahan lain di folder ini

- `ENDPOINT_API.md`: daftar endpoint, body, dan alur pembayaran
- `erd.png` dan `erd.mmd`: ERD database (gambar dan sumber Mermaid)

## Daftar bergrup per hari (gaya Riwayat stok)
Judul kelompok punya titik aksen, garis, dan ringkasan (jumlah pesanan, total) di kanan; baris pesanan punya strip warna status di kiri.
Notifikasi, Semua Pesanan (admin), Pesanan (pelanggan), Ulasan, dan Riwayat stok memakai judul kelompok HARI INI / KEMARIN / tanggal (`GroupTitle`, `dayGroup` di util.dart). Pelanggan memakai dua kotak pilihan FILTER + URUTKAN (`PickField`) menggantikan dua baris chip. Notifikasi tidak lagi memunculkan banner; lonceng memakai lencana + getar.

## Best before kopi (sama seperti web)
Detail pesanan (pelanggan dan staf) menampilkan "Terbaik dinikmati sebelum <tanggal>" di bawah tahap Sangrai setelah pesanan mulai disangrai. Detail staf juga punya baris TGL SANGRAI dan TERBAIK SEBELUM, dan label paket (PDF) mencetak keduanya. Lama masa segar (default 30 hari) diatur admin di Pengaturan > Kesegaran kopi. Pesanan tanpa kopi (hanya perlengkapan) tidak punya tanggal ini.
