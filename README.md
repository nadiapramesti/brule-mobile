# BRÛLÉ Mobile

Aplikasi Flutter (Android) untuk pelanggan BRÛLÉ Specialty Coffee Lab.
Backend: Laravel Sanctum API (repo `brule-coffee-lab`, branch `feature/mobile-api`).

## Fitur

- Login pelanggan (token Sanctum, tersimpan di perangkat)
- Katalog kopi sangrai dan perlengkapan, pencarian, detail (tingkat sangrai, berat, gilingan)
- Keranjang (disimpan di perangkat) dan checkout (COD atau bayar online, voucher, bungkus kado)
- Daftar pesanan, tahap pesanan, batalkan pesanan
- Pembayaran Midtrans Snap lewat WebView, lalu cek status ke server

## Menjalankan

```
adb reverse tcp:8001 tcp:8001
flutter pub get
flutter run
```

API lokal: `php artisan serve --port=8001`. Untuk WiFi, pakai
`flutter run --dart-define=API_BASE=http://IP-LAPTOP:8001`.

## Kredit

Dibuat dengan bantuan AI (Claude).
