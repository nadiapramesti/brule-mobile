import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await Api.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = Api.user ?? {};
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton(
                    onPressed: () => _logout(context),
                    child: const Text('KELUAR'),
                  ),
                  const SizedBox(height: 32),
                  Text('Halo, ${u['name'] ?? ''}', style: Brule.condensed(28)),
                  const SizedBox(height: 6),
                  Text('${u['email'] ?? ''}', style: Brule.mono(12)),
                  const SizedBox(height: 4),
                  Text('role: ${u['role'] ?? ''}',
                      style: Brule.mono(12, color: Brule.amber)),
                  const SizedBox(height: 24),
                  Text(
                    'Login berhasil. Katalog menyusul di langkah berikutnya.',
                    style:
                        TextStyle(color: Brule.kraft.withValues(alpha: 0.85)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
