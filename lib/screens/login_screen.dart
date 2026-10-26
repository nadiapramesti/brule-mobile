import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api.dart';
import '../brand_logo.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';
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
  final _passFocus = FocusNode();
  bool _busy = false;
  String? _provider; // provider sosial yang sedang diproses
  bool _hide = true;
  bool _remember = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getString('remember_email');
    if (!mounted) return;
    setState(() {
      _remember = p.getBool('remember_on') ?? true;
      if (saved != null && _email.text.isEmpty) _email.text = saved;
    });
  }

  void _done() {
    if (!mounted) return;
    if (widget.popOnSuccess) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _register() async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const RegisterScreen()));
    if (ok == true) _done();
  }

  /// Login Google/Facebook lewat Chrome Custom Tab (Google melarang WebView), lalu tukar kode.
  Future<void> _social(String provider) async {
    setState(() {
      _busy = true;
      _provider = provider;
      _error = null;
    });
    try {
      final base = Api.base.replaceFirst('127.0.0.1', 'localhost');
      final result = await FlutterWebAuth2.authenticate(
        url: '$base/auth/$provider/mobile',
        callbackUrlScheme: 'brule',
      );
      final q = Uri.parse(result).queryParameters;
      if (q['error'] != null) {
        if (mounted) setState(() => _error = q['error']);
      } else if (q['code'] != null) {
        await Api.exchange(q['code']!);
        _done();
      } else if (mounted) {
        setState(() => _error = 'Login $provider gagal. Coba lagi.');
      }
    } on PlatformException catch (e) {
      if (e.code != 'CANCELED' && mounted) {
        setState(() => _error = 'Login $provider dibatalkan atau gagal dibuka.');
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _provider = null;
        });
      }
    }
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email dan password wajib diisi.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.login(email, pass, remember: _remember);
      final p = await SharedPreferences.getInstance();
      await p.setBool('remember_on', _remember);
      if (_remember) {
        await p.setString('remember_email', email);
      } else {
        await p.remove('remember_email');
      }
      _done();
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
    final emailBusy = _busy && _provider == null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Reveal(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: BrandLogo(height: widget.popOnSuccess ? 40 : 52),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Reveal(
                    index: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Masuk', style: Brule.condensed(34)),
                        const SizedBox(height: 4),
                        Text(
                          'Pantau pesanan dan belanja kopi sangrai segar.',
                          style: TextStyle(color: Brule.kraft.withValues(alpha: 0.9)),
                        ),
                        if (widget.reason != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Brule.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(widget.reason!,
                                    style: Brule.mono(11, color: Brule.amber)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Reveal(
                    index: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label('EMAIL'),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passFocus.requestFocus(),
                          decoration: InputDecoration(hintText: tr('contoh: nadia@email.com')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Reveal(
                    index: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label('PASSWORD'),
                        TextField(
                          controller: _pass,
                          focusNode: _passFocus,
                          obscureText: _hide,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _busy ? null : _submit(),
                          decoration: InputDecoration(
                            hintText: tr('password akun BRÛLÉ kamu'),
                            suffixIcon: IconButton(
                              tooltip: _hide ? 'Tampilkan password' : 'Sembunyikan password',
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: Icon(
                                  _hide ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  key: ValueKey(_hide),
                                ),
                              ),
                              onPressed: () => setState(() => _hide = !_hide),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Reveal(
                    index: 4,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: _busy ? null : () => setState(() => _remember = !_remember),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _remember,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: _busy ? null : (v) => setState(() => _remember = v ?? true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('Ingat saya', style: Brule.mono(12, color: Brule.cream)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('tetap masuk di HP ini',
                                  overflow: TextOverflow.ellipsis, style: Brule.mono(10)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _error == null
                          ? const SizedBox(width: double.infinity, key: ValueKey('no-error'))
                          : Padding(
                              key: ValueKey(_error),
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: ErrorBox(_error!),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Reveal(
                    index: 5,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: emailBusy
                            ? SizedBox(
                                key: ValueKey('spin'),
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: Brule.cream),
                              )
                            : const Text('MASUK', key: ValueKey('txt')),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Reveal(
                    index: 6,
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('ATAU LANJUT DENGAN', style: Brule.mono(10)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Reveal(
                    index: 7,
                    child: ButtonRow(
                      children: [
                        _SocialButton(
                          label: 'GOOGLE',
                          mark: const _Mark('G', Colors.white, Color(0xFF4285F4)),
                          busy: _provider == 'google',
                          onTap: _busy ? null : () => _social('google'),
                        ),
                        _SocialButton(
                          label: 'FACEBOOK',
                          mark: const _Mark('f', Color(0xFF1877F2), Colors.white),
                          busy: _provider == 'facebook',
                          onTap: _busy ? null : () => _social('facebook'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Reveal(
                    index: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton(
                          onPressed: _busy ? null : _register,
                          child: const Text('BELUM PUNYA AKUN? DAFTAR'),
                        ),
                        if (widget.popOnSuccess) ...[
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                            child: const Text('KEMBALI KE KATALOG'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Reveal(
                    index: 9,
                    child: Text(
                      'Admin dan roaster masuk dengan email & password.\nGoogle dan Facebook hanya untuk akun pelanggan.',
                      textAlign: TextAlign.center,
                      style: Brule.mono(9.5),
                    ),
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

/// Lingkaran kecil berisi huruf merek (G / f) sebagai penanda tombol sosial.
class _Mark extends StatelessWidget {
  final String letter;
  final Color bg;
  final Color fg;
  const _Mark(this.letter, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(letter,
          style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w800, height: 1.1)),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget mark;
  final bool busy;
  final VoidCallback? onTap;
  const _SocialButton({required this.label, required this.mark, required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          busy
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Brule.amber),
                )
              : mark,
          const SizedBox(width: 10),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
