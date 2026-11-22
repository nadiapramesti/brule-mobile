import 'package:flutter/foundation.dart';
import 'api.dart';

/// Kopi favorit pelanggan (tombol hati di katalog). Disimpan di server, ditiru di sini
/// supaya kartu kopi bisa langsung berubah tanpa menunggu daftar dimuat ulang.
class Favorites extends ChangeNotifier {
  Favorites._() {
    // Login/logout mengganti pemilik daftar favorit.
    Api.session.addListener(refresh);
  }
  static final Favorites I = Favorites._();

  final Set<int> _ids = {};
  bool _busy = false;

  bool has(int coffeeId) => _ids.contains(coffeeId);
  int get count => _ids.length;

  /// Muat daftar dari server. Tanpa login daftar kosong.
  Future<void> refresh() async {
    if (!Api.loggedIn) {
      if (_ids.isNotEmpty) {
        _ids.clear();
        notifyListeners();
      }
      return;
    }
    try {
      final r = await Api.get('/favorites');
      _replace(r['data']);
    } on ApiException {
      // Daftar lama dibiarkan; tombol hati tetap bisa dipakai.
    }
  }

  /// Toggle favorit satu kopi. Tampilan berubah dulu, dibalikkan bila server menolak.
  /// Melempar [ApiException] supaya pemanggil bisa menampilkan pesannya.
  Future<void> toggle(int coffeeId, String slug) async {
    if (_busy) return;
    _busy = true;
    final was = _ids.contains(coffeeId);
    if (was) {
      _ids.remove(coffeeId);
    } else {
      _ids.add(coffeeId);
    }
    notifyListeners();
    try {
      final r = await Api.post('/favorites/$slug');
      _replace(r['data']);
    } on ApiException {
      if (was) {
        _ids.add(coffeeId);
      } else {
        _ids.remove(coffeeId);
      }
      notifyListeners();
      rethrow;
    } finally {
      _busy = false;
    }
  }

  void _replace(dynamic data) {
    if (data is! List) return;
    _ids
      ..clear()
      ..addAll(data.map((e) => e is num ? e.toInt() : int.tryParse('$e') ?? 0));
    notifyListeners();
  }
}
