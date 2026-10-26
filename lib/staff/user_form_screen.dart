import 'package:flutter/material.dart';
import '../api.dart';
import '../motion.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin_kit.dart';

const _kStaffRoles = {'roaster': 'Roaster', 'admin': 'Admin'};
const _kAllRoles = {'roaster': 'Roaster', 'admin': 'Admin', 'customer': 'Customer'};

/// Buat akun staf baru, atau ubah akun: nama, email, telepon, kata sandi, dan peran.
/// Data diri hanya bisa diubah untuk akun staf; akun pembeli hanya bisa diubah perannya.
class UserFormScreen extends StatefulWidget {
  final Map<String, dynamic>? user; // null = akun baru
  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  late final Map<String, dynamic>? _u = widget.user;
  late final _name = TextEditingController(text: '${_u?['name'] ?? ''}');
  late final _email = TextEditingController(text: '${_u?['email'] ?? ''}');
  late final _phone = TextEditingController(text: '${_u?['phone'] ?? ''}');
  final _pass = TextEditingController();
  late String _role = '${_u?['role'] ?? 'roaster'}';
  bool _busy = false;
  bool _show = false;
  String? _error;

  bool get _isNew => _u == null;
  bool get _isMe => _u?['is_me'] == true;
  bool get _isCustomer => '${_u?['role']}' == 'customer';

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'role': _role,
      if (_pass.text.isNotEmpty) 'password': _pass.text,
    };
    try {
      if (_isNew) {
        await Api.post('/admin/users', body);
      } else {
        await Api.put('/admin/users/${_u!['id']}', body);
      }
      if (!mounted) return;
      toast(context, _isNew ? 'Akun dibuat' : 'Perubahan disimpan');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(context, 'Hapus akun ${_u!['name']}?',
        'Akun staf ini dihapus permanen dan tidak bisa masuk lagi.',
        ok: 'HAPUS', danger: true);
    if (!ok || !mounted) return;
    final done = await runAction(context, () => Api.delete('/admin/users/${_u['id']}'), done: 'Akun dihapus');
    if (done && mounted) Navigator.of(context).pop(true);
  }

  Widget _field(String label, TextEditingController c, String hint,
      {TextInputType type = TextInputType.text, bool obscure = false, Widget? suffix, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Label(label),
        TextField(
          controller: c,
          enabled: enabled,
          keyboardType: type,
          obscureText: obscure,
          autocorrect: false,
          decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final roles = _isNew ? _kStaffRoles : _kAllRoles;
    return AdminPage(
      title: _isNew ? 'Akun staf baru' : 'Ubah akun',
      child: Column(
        children: [
          Expanded(
            child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Reveal(
            index: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isCustomer)
                  Panel(
                    child: Text(
                      'Ini akun pembeli. Nama, email, dan kata sandinya dikelola pembeli sendiri; admin hanya bisa mengubah perannya.',
                      style: Brule.mono(10),
                    ),
                  ),
                _field('NAMA', _name, 'contoh: Raka Roaster', enabled: !_isCustomer),
                _field('EMAIL', _email, 'contoh: roaster@brule.id', type: TextInputType.emailAddress, enabled: !_isCustomer),
                if (!_isNew && !_isCustomer)
                  _field('TELEPON (OPSIONAL)', _phone, 'contoh: 081234567890', type: TextInputType.phone),
                const SizedBox(height: 14),
                IgnorePointer(
                  ignoring: _isMe,
                  child: Opacity(
                    opacity: _isMe ? 0.5 : 1,
                    child: PickField<String>(
                      label: 'PERAN',
                      options: roles,
                      value: roles.containsKey(_role) ? _role : roles.keys.first,
                      all: '',
                      onChanged: (k) => setState(() => _role = k),
                    ),
                  ),
                ),
                if (_isMe)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Peran akunmu sendiri tidak bisa diubah.', style: Brule.mono(9.5)),
                  ),
                if (!_isCustomer)
                  _field(
                    _isNew ? 'KATA SANDI SEMENTARA' : 'KATA SANDI BARU (OPSIONAL)',
                    _pass,
                    _isNew ? 'contoh: minimal 8 karakter' : 'kosongkan jika tidak diganti',
                    obscure: !_show,
                    suffix: IconButton(
                      tooltip: _show ? 'Sembunyikan' : 'Tampilkan',
                      icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: () => setState(() => _show = !_show),
                    ),
                  ),
                if (_isNew)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Berikan kata sandi sementara ke orangnya dan minta diganti setelah masuk.',
                        style: Brule.mono(9.5)),
                  ),
                if (!_isNew && !_isCustomer && !_isMe) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Brule.red,
                      side: BorderSide(color: Brule.red.withValues(alpha: 0.6)),
                    ),
                    onPressed: _busy ? null : _delete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('HAPUS AKUN'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
          ),
          BottomBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.bottomCenter,
                  child: _error == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(padding: const EdgeInsets.only(bottom: 10), child: ErrorBox(_error!)),
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: _busy
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Brule.cream))
                      : const Icon(Icons.check, size: 18),
                  label: Text(_busy ? 'MENYIMPAN...' : (_isNew ? 'BUAT AKUN' : 'SIMPAN PERUBAHAN')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
