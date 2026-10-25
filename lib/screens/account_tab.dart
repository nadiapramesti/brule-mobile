import 'package:flutter/material.dart';
import '../api.dart';
import '../cart.dart';
import '../theme.dart';
import '../widgets.dart';
import 'login_screen.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  Future<void> _logout(BuildContext context) async {
    final nav = Navigator.of(context);
    await Api.logout();
    Cart.I.clear();
    AppEvents.ordersChanged.value++;
    nav.pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final u = Api.user ?? {};
    return SafeArea(
      child: Narrow(
        maxWidth: 480,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            OutlinedButton(
              onPressed: () => _logout(context),
              child: const Text('KELUAR'),
            ),
            const SizedBox(height: 32),
            Text('Halo, ${u['name'] ?? ''}', style: Brule.condensed(28)),
            const SizedBox(height: 6),
            Text('${u['email'] ?? ''}', style: Brule.mono(12)),
            if (u['phone'] != null) ...[
              const SizedBox(height: 4),
              Text('${u['phone']}', style: Brule.mono(12)),
            ],
            const SizedBox(height: 4),
            Text('role: ${u['role'] ?? ''}', style: Brule.mono(12, color: Brule.amber)),
            const SizedBox(height: 32),
            Text('SERVER: ${Api.base}', style: Brule.mono(10)),
          ],
        ),
      ),
    );
  }
}
