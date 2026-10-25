import 'package:flutter/material.dart';
import 'api.dart';
import 'screens/home_screen.dart';
import 'staff/staff_shell.dart';

/// Memilih tampilan sesuai peran: pelanggan/tamu ke toko, roaster ke antrian, admin ke panel.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
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
  }
}
