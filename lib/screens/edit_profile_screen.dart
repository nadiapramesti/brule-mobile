import 'package:flutter/material.dart';
import '../api.dart';
import '../widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _name = TextEditingController(text: '${Api.user?['name'] ?? ''}');
  final _email = TextEditingController(text: '${Api.user?['email'] ?? ''}');
  final _phone = TextEditingController(text: '${Api.user?['phone'] ?? ''}');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || !_email.text.contains('@')) {
      setState(() => _error = 'Nama dan email wajib diisi dengan benar.');
      return;
    }
    final phone = _phone.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^(\+62|62|0)8[0-9]{7,12}$').hasMatch(phone)) {
      setState(() => _error = 'Nomor WhatsApp tidak valid. Contoh: 0812xxxxxxxx');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await Api.put('/me', {
        'name': _name.text.trim(),
        'email': _email.text.trim().toLowerCase(),
        'phone': phone.isEmpty ? null : phone,
      });
      Api.user = res;
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EDIT PROFIL')),
      body: Narrow(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const Label('NAMA LENGKAP'),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'contoh: Nadia Pramesti'),
            ),
            const Label('EMAIL'),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'contoh: nadia@email.com'),
            ),
            const Label('NOMOR WHATSAPP (OPSIONAL)'),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'contoh: 081234567890'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              ErrorBox(_error!),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'MENYIMPAN...' : 'SIMPAN PERUBAHAN'),
            ),
          ],
        ),
      ),
    );
  }
}
