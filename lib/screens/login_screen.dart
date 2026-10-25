import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  /// true: dibuka dari dalam app (mis. saat mau belanja), tutup dan kembali setelah masuk.
  final bool popOnSuccess;
  final String? reason;
  const LoginScreen({super.key, this.popOnSuccess = false, this.reason});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const RegisterScreen()));
    if (ok != true || !mounted) return;
    if (widget.popOnSuccess) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email dan password wajib diisi.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.login(email, pass);
      if (!mounted) return;
      if (widget.popOnSuccess) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Brule.mono(11)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(width: 18, height: 3, color: Brule.amber),
                      const SizedBox(width: 10),
                      Text('BRÛLÉ', style: Brule.condensed(26, spacing: 3)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('SPECIALTY COFFEE LAB', style: Brule.mono(11)),
                  const SizedBox(height: 32),
                  Text('Masuk', style: Brule.condensed(30)),
                  const SizedBox(height: 6),
                  if (widget.reason != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Brule.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Brule.amber.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: Brule.amber),
                          const SizedBox(width: 10),
                          Expanded(child: Text(widget.reason!)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Pantau pesanan dan belanja kopi sangrai segar.',
                    style:
                        TextStyle(color: Brule.kraft.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 24),
                  _label('EMAIL'),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        hintText: 'contoh: nadia@email.com'),
                  ),
                  const SizedBox(height: 18),
                  _label('PASSWORD'),
                  TextField(
                    controller: _pass,
                    obscureText: _hide,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _busy ? null : _submit(),
                    decoration: InputDecoration(
                      hintText: 'password akun BRÛLÉ kamu',
                      suffixIcon: IconButton(
                        tooltip: _hide
                            ? 'Tampilkan password'
                            : 'Sembunyikan password',
                        icon: Icon(_hide
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Brule.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: Brule.red.withValues(alpha: 0.5)),
                      ),
                      child:
                          Text(_error!, style: const TextStyle(color: Brule.red)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: Brule.cream),
                          )
                        : const Text('MASUK'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _busy ? null : _register,
                    child: const Text('BELUM PUNYA AKUN? DAFTAR'),
                  ),
                  if (widget.popOnSuccess) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                      child: const Text('KEMBALI KE KATALOG'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Aplikasi ini khusus pelanggan. Staf masuk lewat web.',
                    textAlign: TextAlign.center,
                    style: Brule.mono(11),
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
