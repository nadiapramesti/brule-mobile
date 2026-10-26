import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'screens/notifications_screen.dart';
import 'util.dart';

/// Notifikasi dalam aplikasi: menghitung yang belum dibaca (polling saat app terbuka)
/// dan mengabarkannya lewat lencana + getar di ikon bel. Tidak ada banner/pop-up yang menutupi layar.
class Notices {
  Notices._();

  static final navKey = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Jumlah belum dibaca, dipakai lencana di ikon bel.
  static final unread = ValueNotifier<int>(0);

  /// Permintaan pindah tab dari layar notifikasi: 'queue' atau 'stock'.
  static final goto = ValueNotifier<String?>(null);

  static Timer? _timer;

  static void init() {
    Api.session.addListener(_onSession);
    _onSession();
  }

  static void _onSession() {
    _timer?.cancel();
    _timer = null;
    if (!Api.loggedIn) {
      unread.value = 0;
      return;
    }
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => refresh());
  }

  static Future<void> refresh() async {
    if (!Api.loggedIn) return;
    try {
      final r = await Api.get('/notices/unread');
      final n = asInt(r['unread']);
      unread.value = n;
    } on ApiException {
      // diam: jaringan bisa putus sebentar
    }
  }

  static void open() {
    navKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }
}
