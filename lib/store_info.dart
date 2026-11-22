import 'api.dart';

/// Info toko yang boleh dibaca tanpa login (GET /store), dimuat sekali dan disimpan.
class StoreInfo {
  /// Nomor WhatsApp toko dari Pengaturan admin, format 62812... Null sampai berhasil dimuat.
  static String? whatsapp;
  static bool _loading = false;

  static Future<void> load() async {
    if (_loading || whatsapp != null) return;
    _loading = true;
    try {
      final r = await Api.get('/store');
      final n = '${r['whatsapp'] ?? ''}'.replaceAll(RegExp(r'[^0-9]'), '');
      whatsapp = n.length >= 10 ? n : null;
    } on ApiException {
      // Tombol chat saja yang tidak muncul; toko tetap jalan.
    } finally {
      _loading = false;
    }
  }
}
