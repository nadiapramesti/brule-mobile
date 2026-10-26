import 'package:flutter/material.dart';
import 'api.dart';
import 'cart.dart';
import 'notices.dart';
import 'prefs.dart';
import 'root_gate.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPrefs.load();
  await Api.loadToken();
  await Cart.I.load();
  await Api.restore();
  Notices.init();
  runApp(const BruleApp());
}

class BruleApp extends StatelessWidget {
  const BruleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppPrefs.light,
      builder: (context, _, _) => MaterialApp(
        title: 'BRÛLÉ',
        navigatorKey: Notices.navKey,
        scaffoldMessengerKey: Notices.messengerKey,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const RootGate(),
      ),
    );
  }
}
