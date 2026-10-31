import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'cart.dart';
import 'notices.dart';
import 'prefs.dart';
import 'root_gate.dart';
import 'splash_gate.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Frame pertama digambar secepat mungkin (warna sama dengan splash Android), baru muat data lokal.
  runApp(const BruleApp());
}

class BruleApp extends StatefulWidget {
  const BruleApp({super.key});

  @override
  State<BruleApp> createState() => _BruleAppState();
}

class _BruleAppState extends State<BruleApp> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await AppPrefs.load();
    await Api.loadToken();
    await Cart.I.load();
    Notices.init();
    if (mounted) setState(() => _ready = true);
    // Pemeriksaan token jalan di belakang intro (tidak menahan layar polos di awal).
    unawaited(Api.restore().catchError((_) => false).whenComplete(() => Api.ready.value = true));
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const ColoredBox(color: Color(0xFF121212));
    return ListenableBuilder(
      listenable: Listenable.merge([AppPrefs.light, AppPrefs.lang]),
      builder: (context, _) => MaterialApp(
        themeAnimationDuration: Duration.zero,
        title: 'BRÛLÉ',
        navigatorKey: Notices.navKey,
        scaffoldMessengerKey: Notices.messengerKey,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const SplashGate(child: RootGate()),
      ),
    );
  }
}
