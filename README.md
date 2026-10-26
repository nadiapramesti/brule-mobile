# BRÛLÉ Mobile

Aplikasi Flutter (Android) untuk BRÛLÉ Specialty Coffee Lab: satu aplikasi dengan tiga peran
(pelanggan, roaster, admin). Backend: Laravel Sanctum API (repo `brule-coffee-lab`, branch `feature/mobile-api`).

## Akun demo

Semua password: `password`. Akun dibuat oleh seeder (`php artisan db:seed`).

| Peran | Email | Bisa apa |
|---|---|---|
| Admin | `admin@brule.test` | Semua menu: dashboard, pesanan, antrian, stok, laporan, pengguna, voucher, ulasan, produk, pengaturan |
| Roaster | `roaster@brule.test` | Antrian sangrai, detail pesanan, stok biji, label paket |
| Pelanggan | `customer@brule.test` | Belanja, keranjang, checkout, lacak pesanan, struk |
| Pelanggan | `raka@brule.test`, `sinta@brule.test` | Sama, dengan riwayat pesanan berbeda |

Akun staf baru dibuat admin lewat **Menu → Pengguna → Tambah akun staf**. Admin juga bisa
mengubah peran, mengganti kata sandi, dan menghapus akun staf di sana.

## Fitur

**Pelanggan:** katalog kopi dan perlengkapan, keranjang, checkout (COD atau Midtrans), voucher,
garis waktu pesanan, tanggal "terbaik dinikmati sebelum", unduh struk (muncul setelah resi diisi),
ulasan, login "ingat saya" dan Google/Facebook.

**Roaster dan admin:** dashboard penjualan, antrian per tahap dengan aksi massal, detail pesanan,
isi resi dan unduh label paket, stok biji (masuk, keluar, hitung ulang) dengan riwayat,
laporan PDF/Excel, kelola voucher, ulasan, perlengkapan (termasuk foto), akun staf, dan pengaturan toko.

**Notifikasi dalam aplikasi:** pesanan baru, pesanan lebih dari 24 jam, stok menipis, ulasan baru.
Tampil sebagai lencana di ikon lonceng.

## Menjalankan

API (di folder `brule-api`):

```
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8001
```

Aplikasi:

```
flutter pub get
flutter run
```

**Lewat WiFi (paling mudah):** buka aplikasi, saat muncul "tidak terhubung" tekan
**UBAH ALAMAT SERVER**, isi `http://IP-LAPTOP:8001` (cek dengan `ipconfig`). Tersimpan di HP.
HP dan laptop harus di WiFi yang sama.

**Lewat kabel USB:** `adb reverse tcp:8001 tcp:8001`, lalu alamat bawaan `http://127.0.0.1:8001`
sudah cukup. Login Google/Facebook hanya berfungsi dengan cara ini (butuh `localhost`).

Alamat server juga bisa diberikan saat build: `flutter run --dart-define=API_BASE=http://IP-LAPTOP:8001`.

## Dokumentasi

- `docs/ENDPOINT_API.md`: daftar endpoint API
- `docs/DAFTAR_LAYAR.md`: daftar layar dan perilakunya

## Kredit

Dibuat dengan bantuan AI (Claude).
