import 'package:flutter/material.dart';
import 'api.dart';
import 'screens/home_screen.dart';
import 'splash_gate.dart';
import 'staff/staff_shell.dart';

/// Memilih tampilan sesuai peran: pelanggan/tamu ke toko, roaster ke antrian, admin ke panel.
/// Setiap kali pengguna baru selesai login, intro BRÛLÉ versi lebih singkat diputar
/// sebelum dashboard tampil.
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  bool _was = Api.loggedIn;
  int _logins = 0;

  @override
  void initState() {
    super.initState();
    Api.session.addListener(_onSession);
  }

  @override
  void dispose() {
    Api.session.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() {
    final now = Api.loggedIn;
    if (now && !_was && mounted) setState(() => _logins++);
    _was = now;
  }

  @override
  Widget build(BuildContext context) {
    final page = ValueListenableBuilder<int>(
      valueListenable: Api.session,
      builder: (context, _, _) {
        final role = Api.loggedIn ? '${Api.user?['role']}' : 'guest';
        switch (role) {
          case 'admin':
            return const StaffShell(key: ValueKey('admin'), admin: true);
          case 'roaster':
            return const StaffShell(key: ValueKey('roaster'), admin: false);
          default:
            return const HomeScreen(key: ValueKey('shop'));
        }
      },
    );
    if (_logins == 0) return page;
    return SplashGate(key: ValueKey('login$_logins'), always: true, speed: 1.5, child: page);
  }
}
