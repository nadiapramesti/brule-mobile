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

Tips: aktifkan mode jam tetap/baterai penuh sebelum screenshot, dan pakai data uji yang rapi (nama dan alamat yang wajar).

## Bahan lain di folder ini

- `ENDPOINT_API.md`: daftar endpoint, body, dan alur pembayaran
- `erd.png` dan `erd.mmd`: ERD database (gambar dan sumber Mermaid)
