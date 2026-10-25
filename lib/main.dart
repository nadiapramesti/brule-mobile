import 'package:flutter/material.dart';
import 'api.dart';
import 'cart.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.loadToken();
  await Cart.I.load();
  final ok = await Api.restore();
  runApp(BruleApp(loggedIn: ok));
}

class BruleApp extends StatelessWidget {
  final bool loggedIn;
  const BruleApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BRÛLÉ',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: loggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
