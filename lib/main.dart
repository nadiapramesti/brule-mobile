import 'package:flutter/material.dart';
import 'api.dart';
import 'cart.dart';
import 'notices.dart';
import 'root_gate.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
      title: 'BRÛLÉ',
      navigatorKey: Notices.navKey,
      scaffoldMessengerKey: Notices.messengerKey,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const RootGate(),
    );
  }
}
