import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'screens/notifications_screen.dart';
import 'theme.dart';
import 'util.dart';

/// Notifikasi dalam aplikasi: menghitung yang belum dibaca (polling saat app terbuka)
/// dan memunculkan banner saat ada notifikasi baru.
class Notices {
  Notices._();

  static final navKey = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Jumlah belum dibaca, dipakai lencana di ikon bel.
  static final unread = ValueNotifier<int>(0);

  /// Permintaan pindah tab dari layar notifikasi: 'queue' atau 'stock'.
  static final goto = ValueNotifier<String?>(null);

  static Timer? _timer;
  static bool _first = true;

  static void init() {
    Api.session.addListener(_onSession);
    _onSession();
  }

  static void _onSession() {
    _timer?.cancel();
    _timer = null;
    _first = true;
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
      final grew = !_first && n > unread.value;
      unread.value = n;
      _first = false;
      if (grew) _banner(n);
    } on ApiException {
      // diam: jaringan bisa putus sebentar
    }
  }

  static Future<void> _banner(int n) async {
    var text = 'Ada notifikasi baru';
    try {
      final r = await Api.get('/notices');
      final list = ((r['data'] ?? []) as List).cast<Map<String, dynamic>>();
      final first = list.where((e) => e['read'] != true).firstOrNull;
      if (first != null) {
        text = '${first['title']}${first['body'] == null ? '' : ' · ${first['body']}'}';
      }
    } on ApiException {
      // pakai teks bawaan
    }
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active_outlined, size: 20, color: Brule.amber),
              const SizedBox(width: 12),
              Expanded(child: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis)),
            ],
          ),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: 'LIHAT', onPressed: open),
        ),
      );
  }

  static void open() {
    navKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }
}
