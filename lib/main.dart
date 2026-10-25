import 'package:flutter/material.dart';
import 'api.dart';
import 'cart.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.loadToken();
  await Cart.I.load();
  await Api.restore();
  runApp(const BruleApp());
}

class BruleApp extends StatelessWidget {
  const BruleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BRÛLÉ',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}
