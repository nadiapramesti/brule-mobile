import 'package:flutter/material.dart';
import '../api.dart';
import '../widgets.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_new.text.length < 8) {
      setState(() => _error = 'Password baru minimal 8 karakter.');
      return;
    }
    if (_new.text != _confirm.text) {
      setState(() => _error = 'Konfirmasi password tidak sama.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.put('/me/password', {
        'current_password': _current.text,
        'password': _new.text,
        'password_confirmation': _confirm.text,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        suffixIcon: IconButton(
          tooltip: _hide ? 'Tampilkan' : 'Sembunyikan',
          icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _hide = !_hide),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UBAH PASSWORD')),
      body: Narrow(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const Label('PASSWORD SAAT INI'),
            TextField(
              controller: _current,
              obscureText: _hide,
              textInputAction: TextInputAction.next,
              decoration: _dec('password yang kamu pakai sekarang'),
            ),
            const Label('PASSWORD BARU'),
            TextField(
              controller: _new,
              obscureText: _hide,
              textInputAction: TextInputAction.next,
              decoration: _dec('minimal 8 karakter'),
            ),
            const Label('ULANGI PASSWORD BARU'),
            TextField(
              controller: _confirm,
              obscureText: _hide,
              decoration: _dec('ketik ulang password baru'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              ErrorBox(_error!),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'MENYIMPAN...' : 'UBAH PASSWORD'),
            ),
          ],
        ),
      ),
    );
  }
}
