import 'package:flutter/material.dart';
import '../api.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';

/// Daftar akun baru. Berhasil = langsung masuk, lalu layar ini menutup dengan hasil true.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'Nama wajib diisi.';
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Email tidak valid. Contoh: nama@email.com';
    }
    final phone = _phone.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^(\+62|62|0)8[0-9]{7,12}$').hasMatch(phone)) {
      return 'Nomor WhatsApp tidak valid. Contoh: 0812xxxxxxxx';
    }
    if (_pass.text.length < 8) return 'Password minimal 8 karakter.';
    if (_pass.text != _confirm.text) return 'Konfirmasi password tidak sama.';
    return null;
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.register(
        name: _name.text.trim(),
        email: _email.text.trim().toLowerCase(),
        phone: _phone.text.trim(),
        password: _pass.text,
        confirmation: _confirm.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String hint, {bool eye = false}) => InputDecoration(
        hintText: hint,
        suffixIcon: eye
            ? IconButton(
                tooltip: _hide ? 'Tampilkan password' : 'Sembunyikan password',
                icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _hide = !_hide),
              )
            : null,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DAFTAR AKUN')),
      body: Narrow(
        maxWidth: 480,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Reveal(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buat akun BRÛLÉ', style: Brule.condensed(28)),
                  const SizedBox(height: 6),
                  Text('Sekali daftar, langsung bisa belanja dan memantau pesanan.',
                      style: TextStyle(color: Brule.kraft.withValues(alpha: 0.85))),
                ],
              ),
            ),
            Reveal(
              index: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            const Label('NAMA LENGKAP'),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: _dec('contoh: Nadia Pramesti'),
            ),
                ],
              ),
            ),
            Reveal(
              index: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            const Label('EMAIL'),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: _dec('contoh: nadia@email.com'),
            ),
                ],
              ),
            ),
            Reveal(
              index: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            const Label('NOMOR WHATSAPP (OPSIONAL)'),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: _dec('contoh: 081234567890'),
            ),
                ],
              ),
            ),
            Reveal(
              index: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            const Label('PASSWORD'),
            TextField(
              controller: _pass,
              obscureText: _hide,
              textInputAction: TextInputAction.next,
              decoration: _dec('minimal 8 karakter', eye: true),
            ),
                ],
              ),
            ),
            Reveal(
              index: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            const Label('ULANGI PASSWORD'),
            TextField(
              controller: _confirm,
              obscureText: _hide,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _busy ? null : _submit(),
              decoration: _dec('ketik ulang password'),
            ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _error == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(padding: const EdgeInsets.only(top: 16), child: ErrorBox(_error!)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _busy
                    ? SizedBox(
                        key: ValueKey('spin'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Brule.cream),
                      )
                    : const Text('DAFTAR SEKARANG', key: ValueKey('txt')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
