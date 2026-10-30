# PRD BRÛLÉ — Specialty Coffee Lab (web + aplikasi Android)

Dokumen ringkas (Product Requirements Document) untuk versi MVP. Isinya merangkum kebutuhan yang
sudah diwujudkan di kode, bukan janji fitur masa depan. Rencana lanjutan ada di README bagian
"Proses pengembangan".

| | |
|---|---|
| Produk | BRÛLÉ: toko kopi sangrai-sesuai-pesanan (web Laravel + aplikasi Flutter Android) |
| Penulis | Nadia Pramesti (pengembang tunggal) |
| Repo | `brule-coffee-lab` (web + API, branch `feature/mobile-api`), `brule-mobile` (aplikasi) |
| Status | MVP selesai, demo online di Render (paket gratis) |

## 1. Latar belakang

Roastery kecil biasanya menerima pesanan lewat chat: pelanggan menyebut kopi, level sangrai, ukuran,
dan cara seduh; pemilik mencatat manual, menghitung stok biji, lalu memberi kabar status satu per satu.
Akibatnya pesanan mudah terlewat, stok biji tidak tercatat rapi, dan pelanggan tidak tahu kopinya
sudah sampai tahap mana.

BRÛLÉ memindahkan alur itu ke satu sistem: pelanggan memesan kopi yang disangrai **setelah dipesan**
(level sangrai dan metode giling dipilih sendiri), sedangkan roaster dan admin memantau antrian,
stok, dan penjualan.

## 2. Tujuan

1. Pelanggan bisa memesan kopi (pilih level sangrai, ukuran, giling) dan melacak statusnya sendiri.
2. Roaster tahu apa yang harus disangrai berikutnya tanpa mencatat manual.
3. Admin punya angka penjualan dan stok biji yang akurat, dan bisa mengelola katalog sendiri.
4. Semua peran bisa dipakai dari HP lewat satu aplikasi.

Bukan tujuan MVP: marketplace banyak penjual, pengiriman terintegrasi kurir, notifikasi dorong, iOS.

## 3. Pengguna

| Peran | Siapa | Kebutuhan utama |
|---|---|---|
| Pelanggan | Penikmat kopi, pembeli rumahan atau kafe kecil | Pilih kopi dan level sangrai, bayar mudah, tahu status pesanan |
| Roaster | Orang yang menyangrai dan mengemas | Antrian per tahap, detail pesanan, stok biji, label paket |
| Admin | Pemilik toko | Dashboard, laporan, kelola kopi, voucher, ulasan, akun staf, pengaturan toko |

Pengunjung tanpa akun hanya bisa melihat katalog dan melacak pesanan dengan kode.

## 4. User story

**Pelanggan**
- Sebagai pelanggan, saya ingin melihat katalog kopi beserta asal-usul dan catatan rasa, supaya bisa memilih.
- Sebagai pelanggan, saya ingin memilih level sangrai, ukuran, dan metode giling, supaya kopi sesuai cara seduh saya.
- Sebagai pelanggan, saya ingin meracik blend dari beberapa kopi, supaya bisa membuat rasa sendiri.
- Sebagai pelanggan, saya ingin memakai voucher dan membayar lewat COD atau online, supaya checkout fleksibel.
- Sebagai pelanggan, saya ingin melihat garis waktu pesanan dan tanggal "terbaik dinikmati sebelum", supaya tahu kapan kopi siap dan kapan sebaiknya diseduh.
- Sebagai pelanggan, saya ingin melacak pesanan dengan kode tanpa login, supaya bisa dicek dari pesan yang dikirim ke teman atau keluarga.
- Sebagai pelanggan, saya ingin mengulas kopi dan membeli ulang pesanan lama, supaya belanja berikutnya cepat.

**Roaster**
- Sebagai roaster, saya ingin antrian pesanan per tahap (antri, sangrai, giling, kemas, kirim), supaya tahu urutan kerja.
- Sebagai roaster, saya ingin memindahkan beberapa pesanan sekaligus ke tahap berikutnya, supaya hemat waktu.
- Sebagai roaster, saya ingin mengisi resi dan mencetak label paket.
- Sebagai roaster, saya ingin mencatat stok biji masuk, keluar, dan hitung ulang, lengkap dengan riwayatnya.

**Admin**
- Sebagai admin, saya ingin dashboard penjualan dan laporan PDF/Excel, supaya tahu performa toko.
- Sebagai admin, saya ingin menambah dan mengubah kopi (foto, asal-usul, proses, level sangrai dan harga per level), supaya katalog selalu terbaru tanpa bantuan pengembang.
- Sebagai admin, saya ingin mengelola voucher, ulasan, akun staf, dan pengaturan toko.
- Sebagai admin, saya ingin diberi tahu saat ada pesanan baru, pesanan tertahan lebih dari 24 jam, stok menipis, atau ulasan baru.

## 5. Lingkup

**Termasuk (MVP)**
- Web: landing, katalog, racik blend, perlengkapan, keranjang, checkout, lacak pesanan, akun, panel admin dan roaster.
- Aplikasi Android: tiga peran dalam satu aplikasi, mengikuti fitur web yang inti, ditambah FAQ, mode gelap/terang, bahasa Indonesia/English.
- Pembayaran COD dan online (Midtrans Snap, mode sandbox).
- Login email, "ingat saya", Google dan Facebook.
- Notifikasi dalam aplikasi (lonceng, diperbarui berkala).

**Tidak termasuk**
- Notifikasi dorong (push), aplikasi iOS.
- Integrasi tarif dan pelacakan kurir otomatis (ongkir memakai tarif tetap, resi diisi manual).
- Banyak toko atau banyak penjual.
- Mode offline.

## 6. Aturan bisnis

- Kopi punya lima level sangrai (light, medium light, medium, medium dark, dark), masing-masing dengan harga per 100 g, tingkat sangrai (Agtron), dan catatan rasa sendiri.
- Kopi dijual dalam berbagai ukuran gram dan metode giling (mis. V60, espresso, French press, AeroPress, tubruk, biji utuh); stok dicatat dalam **gram biji hijau**.
- Alur pesanan: Menunggu pembayaran (hanya online) → Antri → Sangrai → Giling → Kemas → Kirim → Selesai. COD langsung masuk Antri.
- Pesanan hanya bisa dibatalkan (oleh admin) saat Menunggu pembayaran atau Antri; pembatalan mengembalikan stok biji. Menandai pesanan Selesai juga tugas admin.
- Pembayaran online dikonfirmasi lewat notifikasi Midtrans; COD dianggap sah tanpa menunggu pembayaran.
- Tanggal "terbaik dinikmati sebelum" dihitung dari tanggal sangrai ditambah sejumlah hari (bawaan 30, bisa diubah admin).
- Ongkir tetap (bawaan Rp15.000) dan gratis mulai belanja tertentu (bawaan Rp500.000); keduanya bisa diubah admin.
- Stok dianggap menipis di bawah batas tertentu (bawaan 5.000 g).
- Voucher bertipe persen atau potongan tetap, dengan minimal belanja, batas diskon maksimum, kuota, dan masa berlaku.
- Level sangrai yang sudah punya pesanan tidak bisa dimatikan.
- Struk dan label paket baru bisa diunduh setelah resi diisi.
- Peran dibatasi di sisi server (bukan hanya menyembunyikan menu): roaster tidak bisa membuka menu khusus admin, pelanggan tidak bisa membuka menu staf.

## 7. Kebutuhan non-fungsional

- **Platform:** Android (Flutter) dan web modern; backend Laravel 13 dengan Sanctum.
- **Keamanan:** autentikasi token Sanctum; pembatasan laju (throttle) pada login, daftar, lacak, dan tukar token; otorisasi per peran di server; kata sandi di-hash; `.env` tidak masuk git.
- **Bahasa dan tema:** Indonesia dan English, gelap dan terang; pilihan tersimpan di perangkat.
- **Kegunaan:** tombol aksi utama selalu di bawah layar; daftar dikelompokkan per hari; contoh isian (placeholder) di setiap kolom; pesan error dari server ikut diterjemahkan.
- **Pemeliharaan:** tes otomatis di API (Pest) dan unit test di aplikasi; dokumentasi endpoint, daftar layar, dan ERD ada di `docs/`.
- **Deployment demo:** Docker di Render paket gratis; server tidur setelah 15 menit tanpa akses dan data kembali ke data contoh saat restart.

## 8. Ukuran berhasil

Karena belum ada pengguna sungguhan, ukuran berhasil MVP bersifat teknis dan bisa dicek:

1. Pelanggan demo bisa dari katalog sampai checkout (COD) dan melihat pesanannya berpindah tahap di HP asli.
2. Roaster demo bisa memindahkan pesanan dari Antri sampai Kirim, admin menandainya Selesai, dan stok biji berubah sesuai.
3. Admin demo bisa menambah kopi baru lengkap dengan foto dan level sangrai dari aplikasi.
4. `flutter analyze` tanpa temuan, `flutter test` dan tes Pest di API lulus.
5. API dan aplikasi bisa dipakai lewat server online tanpa laptop menyala.

Ukuran yang belum bisa dinilai: kepuasan pengguna nyata, jumlah pesanan, dan waktu pengerjaan pesanan
dibanding cara manual. Itu butuh uji coba dengan roastery sungguhan.
