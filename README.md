# BRÛLÉ Mobile

Aplikasi Flutter (Android) untuk BRÛLÉ Specialty Coffee Lab: satu aplikasi dengan tiga peran
(pelanggan, roaster, admin). Backend: Laravel Sanctum API (repo `brule-coffee-lab`, branch `feature/mobile-api`).

## Demo online

Server API sudah jalan di cloud (Render, paket gratis), jadi aplikasi bisa dicoba tanpa laptop menyala:

```
https://brule-coffee-lab.onrender.com
```

Bangun APK yang langsung terhubung ke server itu:

```
flutter build apk --release --dart-define=API_BASE=https://brule-coffee-lab.onrender.com
```

Atau pada aplikasi yang sudah terpasang: **UBAH ALAMAT SERVER**, isi alamat di atas (tanpa `/api`).

Catatan paket gratis:

- Server tidur setelah 15 menit tidak diakses. Permintaan pertama bisa butuh 30-60 detik, buka aplikasi satu menit sebelum demo.
- Data kembali ke data contoh seeder setiap server restart atau deploy ulang. Foto yang diunggah dan pesanan baru ikut hilang.
- Login Google/Facebook belum aktif di server online (redirect URL belum didaftarkan). Login email berfungsi normal.
- Akun demo di bawah berlaku sama di server online.

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

**Pelanggan:** katalog kopi dan perlengkapan, racik blend, keranjang, checkout (COD atau Midtrans),
voucher, garis waktu pesanan, tanggal "terbaik dinikmati sebelum", unduh struk (muncul setelah resi
diisi), beli lagi dari pesanan lama, lacak pesanan lewat kode tanpa login, ulasan, login "ingat saya" dan Google/Facebook, buku alamat, **Bantuan (FAQ)**.

**Roaster dan admin:** dashboard penjualan, antrian per tahap dengan aksi massal, detail pesanan,
isi resi dan unduh label paket, stok biji (masuk, keluar, hitung ulang) dengan riwayat,
laporan PDF/Excel, ekspor daftar pesanan, unduh invoice, kelola voucher, ulasan, kopi dan perlengkapan
(tambah/ubah lengkap dengan foto, asal-usul, dan level sangrai), akun staf, dan pengaturan toko.

**Notifikasi dalam aplikasi:** pesanan baru, pesanan lebih dari 24 jam, stok menipis, ulasan baru.
Tampil sebagai lencana di ikon lonceng.

**Daftar rapi:** riwayat, pesanan, notifikasi, dan ulasan dikelompokkan per hari
(HARI INI, KEMARIN, lalu tanggal). Tombol simpan atau aksi utama selalu di bawah layar.

## Batasan yang diketahui

- **Notifikasi dorong (push)** belum ada. Notifikasi hanya muncul di dalam aplikasi (lonceng, dipolling), karena push butuh akun Firebase.
- **Login Google/Facebook** di HP asli hanya jalan lewat kabel USB (alamat server lokal); di server publik jalan normal.
- Pesan error dari server sudah diterjemahkan lewat `lang/en.json` di API; pesan baru yang ditambahkan nanti perlu ditambah ke file itu juga, kalau tidak tetap Indonesia.

## Tampilan dan bahasa

Sama seperti di web: **mode gelap/terang** dan **bahasa Indonesia/English**. Pilihan tersimpan di HP.
Bahasa bawaan Indonesia, tema bawaan mengikuti setelan HP sampai kamu memilih sendiri.

| Peran | Tempat mengubah |
|---|---|
| Pelanggan | **Akun → Pengaturan** (juga ikon bulan/matahari di header Beranda) |
| Roaster | **Akun → Pengaturan** |
| Admin | **Menu → Pengaturan → TAMPILAN** |

Pengaturan berbentuk daftar berkelompok: ketuk baris **Tema** atau **Bahasa** untuk memilih lewat
bottom sheet. Admin juga melihat kelompok **TOKO** (identitas, kontak, ongkir dan stok, kesegaran kopi,
add-on, COD), tiap kelompok punya form sendiri dengan tombol simpan di bawah.

**Cara kerja bahasa.** Semua teks lewat widget `Text` pengganti (`lib/i18n.dart`) yang menerjemahkan
lewat kamus `lib/i18n_en.dart`. Aplikasi juga mengirim header `Accept-Language` ke API, jadi notifikasi,
pesan galat, dan FAQ dari server ikut berbahasa sama.

Menambah atau memperbaiki terjemahan:

1. Buka `lib/i18n_en.dart`.
2. Tambah baris di `kEn`: `'Teks Indonesia persis': 'English text',`
3. Untuk teks yang disisipi data, pakai pola di `kEnPatterns` dengan `{}` sebagai pengganti nilainya:
   `('{} pesanan', '{} orders'),`

Teks dari data toko (nama kopi, deskripsi, cerita) tampil apa adanya. Teks yang tidak ada di kamus
tetap berbahasa Indonesia, jadi aplikasi tidak pernah kosong.

**Warna.** Semua warna ada di `lib/theme.dart` (`Brule.*`), dibaca saat layar dibangun. Mengganti tema
atau bahasa membangun ulang seluruh layar tanpa menutup halaman yang sedang dibuka.

## Bantuan (FAQ)

**Akun → Pengaturan → BANTUAN** (juga untuk tamu yang belum masuk). Pertanyaan
dikelompokkan, bisa dibuka satu per satu dan dicari. Di bawahnya ada Pengiriman dan pengembalian,
Syarat dan ketentuan, dan Kebijakan privasi. Isinya diambil dari API (`GET /api/help/{page}`), sama
dengan halaman Bantuan di web (`lang/{id,en}/pages.php`), jadi cukup diubah di satu tempat.

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

## APK rilis (untuk dibagikan atau dikumpulkan)

Ikon aplikasi dan splash BRÛLÉ sudah terpasang. Build satu kali:

```
flutter build apk --release
```

Hasilnya di `build/app/outputs/flutter-apk/app-release.apk`, bisa dikirim ke HP lain dan diinstal langsung.
Alamat server tersimpan di HP, jadi pada HP lain isi dulu lewat **UBAH ALAMAT SERVER** (atau build dengan
`--dart-define=API_BASE=http://IP-ATAU-DOMAIN:8001`).

**Tanda tangan sendiri (opsional, wajib untuk Play Store):**

```
keytool -genkey -v -keystore brule-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias brule
```

Lalu buat `android/key.properties` (sudah di `.gitignore`, jangan di-commit):

```
storeFile=../../brule-release.jks
keyAlias=brule
storePassword=...
keyPassword=...
```

Tanpa berkas itu, build rilis memakai kunci debug dan tetap bisa diinstal.

## Kalau ada masalah

| Gejala | Penyebab dan solusi |
|---|---|
| "Tidak bisa terhubung ke server" | API belum jalan, atau IP laptop berubah. Jalankan `php artisan serve --host=0.0.0.0 --port=8001`, cek `ipconfig`, lalu **UBAH ALAMAT SERVER** di aplikasi |
| Alamat benar tapi tetap gagal | Firewall Windows. Izinkan PHP di jaringan Private, dan pastikan HP dan laptop di WiFi yang sama |
| Lewat USB tiba-tiba putus | `adb reverse` hilang tiap kabel dicabut. Jalankan lagi `adb reverse tcp:8001 tcp:8001` |
| Setelah `git pull` muncul error aneh | Hentikan aplikasi lalu `flutter pub get` dan `flutter run` penuh (hot reload tidak cukup untuk paket baru) |
| Notifikasi atau FAQ masih Indonesia saat mode English | API belum di-pull dan di-restart (butuh middleware `ApiLocale` dan endpoint `/help`) |
| Teks tertentu belum diterjemahkan | Tambah ke `lib/i18n_en.dart` (lihat bagian Bahasa) |
| Akun demo lama masih bernama lama | `php artisan db:seed --class=UserSeeder` |

## Struktur kode

```
lib/
  main.dart            titik masuk, tema dan bahasa dibangun ulang saat berubah
  theme.dart           warna Brule.* (gelap/terang) dan ThemeData
  prefs.dart           pilihan tema dan bahasa (tersimpan), switch kecil
  i18n.dart            tr() dan widget Text yang menerjemahkan
  i18n_en.dart         kamus Indonesia -> English
  settings_screen.dart Pengaturan berkelompok dan bottom sheet pilihan
  api.dart             klien HTTP (token, Accept-Language, unggah, unduh)
  screens/             layar pelanggan: beranda, katalog, keranjang, checkout, pesanan, akun, bantuan
  staff/               layar roaster dan admin: dashboard, antrian, stok, laporan, pengguna, pengaturan toko
```

## Tes otomatis

```
flutter test
```

Isinya tes unit untuk terjemahan (`tr()`, pola `{}`, konsistensi kamus) dan helper rupiah/tanggal di `test/`.

## Proses pengembangan

### 1. Metode

Dikerjakan **sendirian** dengan pendekatan **iteratif-inkremental ala Agile solo**, bukan Scrum penuh:
tidak ada sprint formal, product owner, atau daily stand-up. Pekerjaan dipecah menjadi potongan kecil
yang langsung bisa dicoba (satu fitur, satu layar), dicoba di HP asli, diperbaiki, lalu lanjut ke
potongan berikutnya. Web (Laravel) dibangun lebih dulu, lalu API dan aplikasi mobile menyusul.
Kerangka waktu: web mulai 18 Oktober 2026, aplikasi mulai 25 Oktober, demo online 30 Oktober.

Praktik pendukung:

- **PRD ringkas** di [`docs/PRD.md`](docs/PRD.md) (latar belakang, user story, lingkup, aturan bisnis), dirapikan setelah fitur inti berjalan, jadi berfungsi sebagai acuan dan dokumentasi, bukan kontrak di awal.
- **User story** per peran (pelanggan, roaster, admin) yang dipakai sebagai daftar fitur.
- **Pengujian:** tes fitur Pest di API, unit test di aplikasi, `flutter analyze`, dan uji manual di HP asli setiap iterasi.
- **Git:** commit kecil dengan pesan berawalan `feat` / `fix` / `docs`; API dikembangkan di branch `feature/mobile-api` terpisah dari web di `main`.
- **Pair programming dengan AI (Claude):** AI membantu menulis kode; keputusan produk, alur, tampilan, dan pengujian di perangkat dipegang pengembang.

### 2. Tahapan pembuatan

| Tahap | Yang dikerjakan | Hasil di repo |
|---|---|---|
| Ide dan masalah | Pemesanan kopi sangrai-sesuai-pesanan lewat chat sulit dilacak: stok biji tidak rapi, status pesanan tidak jelas | PRD bagian Latar belakang |
| Riset | Riset ringan alur toko kopi spesialti online (level sangrai, ukuran, metode giling). Belum ada survei pengguna formal | Aturan bisnis di PRD |
| PRD | Tujuan, pengguna, user story, aturan bisnis | `docs/PRD.md` |
| Lingkup MVP | Pilih yang inti (katalog, pesan, bayar, antrian, stok, laporan); tunda push notification dan iOS | PRD bagian Lingkup |
| Perancangan | ERD basis data, daftar endpoint API, daftar layar | `docs/erd.png`, `docs/ENDPOINT_API.md`, `docs/DAFTAR_LAYAR.md` |
| Desain UI/UX | Tema gelap/terang bernuansa kraft dan emas, tombol aksi di bawah, daftar per hari, animasi splash | `lib/theme.dart`, `lib/splash_gate.dart` |
| Implementasi | Web Laravel + Livewire, API Sanctum, aplikasi Flutter tiga peran, dua bahasa | `lib/`, repo `brule-coffee-lab` |
| Pengujian | Tes Pest di API, unit test di aplikasi, analisis statis, uji manual di HP | `test/`, `tests/` di repo API |
| Rilis | Debug/release APK, Docker image, deploy ke Render | `Dockerfile`, `render.yaml`, bagian Demo online |
| Pemeliharaan | Perbaikan dari uji di HP, terjemahan pesan server, dokumentasi diperbarui tiap perubahan | riwayat commit |

### 3. Kelemahan yang diketahui

Sudah dicek ke kode, bukan perkiraan:

- **Token login disimpan di `SharedPreferences`** (teks biasa di penyimpanan aplikasi), belum memakai Android Keystore / `flutter_secure_storage`.
- **Hanya Android.** Tidak ada proyek iOS.
- **Cakupan tes aplikasi tipis:** hanya 9 unit test (terjemahan dan helper rupiah/tanggal). Belum ada widget test atau integration test untuk layar.
- **Belum ada CI** (tidak ada GitHub Actions) di kedua repo; tes dijalankan manual.
- **Notifikasi dipoll tiap 45 detik** selama aplikasi terbuka, bukan push, jadi tidak muncul saat aplikasi ditutup.
- **Tanpa cache dan mode offline:** semua layar butuh koneksi ke server.
- **Tanpa paket state management:** state memakai `setState` (sekitar 200 pemanggilan) dan beberapa layar besar (mis. `home_tab.dart` ±800 baris), jadi sulit dites dan dirawat kalau fitur bertambah.
- **Daftar kopi `/api/coffees` dikirim sekaligus tanpa paginasi.** Aman untuk puluhan kopi, tidak untuk ribuan.
- **`usesCleartextTraffic` aktif** (supaya bisa memakai server lokal `http://`), dan build rilis tanpa berkas `key.properties` ditandatangani dengan kunci debug, jadi belum layak untuk Play Store.
- **Server demo bersifat sementara:** Render gratis tidur setelah 15 menit, SQLite dan foto unggahan hilang saat restart. Notifikasi pembayaran Midtrans (mode sandbox) dan login Google/Facebook belum dikonfigurasi untuk alamat online.
- **Terjemahan English memakai kamus manual:** teks baru yang lupa ditambahkan ke `lib/i18n_en.dart` atau `lang/en.json` tetap tampil Indonesia.
- **Belum diuji pengguna sungguhan.** Ukuran keberhasilan di PRD masih teknis.

### 4. Pengembangan lebih lanjut

Urutan prioritas yang disarankan:

1. Simpan token di penyimpanan aman (`flutter_secure_storage`) dan matikan cleartext untuk build rilis.
2. Tambah widget/integration test untuk alur utama (login, checkout, antrian) dan CI GitHub Actions yang menjalankan `flutter analyze`, `flutter test`, dan Pest.
3. Pindah demo ke penyimpanan permanen: database terkelola (MySQL/PostgreSQL) dan object storage untuk foto, lalu atur notifikasi Midtrans dan redirect login sosial ke alamat publik.
4. Notifikasi dorong lewat Firebase Cloud Messaging menggantikan polling.
5. Paginasi dan cache di katalog, serta mode offline sederhana untuk katalog yang sudah dibuka.
6. Rapikan state (mis. Riverpod/Bloc) dan pecah layar besar.
7. Tanda tangan rilis resmi dan publikasi ke Play Store; pertimbangkan iOS.
8. Integrasi ongkir dan pelacakan kurir otomatis, serta uji coba dengan roastery nyata untuk mengukur ukuran keberhasilan di PRD.

## Dokumentasi

- `docs/PRD.md`: ringkasan kebutuhan produk (latar belakang, user story, lingkup, aturan bisnis)
- `docs/ENDPOINT_API.md`: daftar endpoint API
- `docs/DAFTAR_LAYAR.md`: daftar layar dan perilakunya

## Kredit

Dibuat dengan bantuan AI (Claude).
