import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin_kit.dart';

enum SettingsSection { identity, contact, shipping, fresh, addons, cod }

const _sectionTitles = {
  SettingsSection.identity: 'Identitas toko',
  SettingsSection.contact: 'Kontak',
  SettingsSection.shipping: 'Ongkir dan stok',
  SettingsSection.fresh: 'Kesegaran kopi',
  SettingsSection.addons: 'Add-on',
  SettingsSection.cod: 'Bayar di tempat (COD)',
};

/// Satu kelompok pengaturan toko (sama dengan halaman Pengaturan di web).
class AdminSettingsScreen extends StatelessWidget {
  final SettingsSection section;
  const AdminSettingsScreen({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: _sectionTitles[section]!,
      child: Loader<Map<String, dynamic>>(
        load: () => Api.get('/admin/settings'),
        builder: (context, d, reload) => _SettingsForm(initial: d, section: section),
      ),
    );
  }
}

class _SettingsForm extends StatefulWidget {
  final Map<String, dynamic> initial;
  final SettingsSection section;
  const _SettingsForm({required this.initial, required this.section});

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  static const _text = [
    'store_name', 'tagline', 'city', 'address', 'email', 'whatsapp', 'instagram',
    'shipping_flat', 'free_from', 'low_stock', 'best_before_days', 'gift_wrap_price', 'card_price', 'cod_max',
  ];
  late final Map<String, TextEditingController> _c = {
    for (final k in _text) k: TextEditingController(text: '${widget.initial[k] ?? ''}'),
  };
  late bool _addons = widget.initial['addons_enabled'] == true;
  late bool _cod = widget.initial['cod_enabled'] == true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  static const _numeric = {'shipping_flat', 'free_from', 'low_stock', 'best_before_days', 'gift_wrap_price', 'card_price', 'cod_max'};

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = <String, dynamic>{
      for (final k in _text)
        k: _numeric.contains(k) ? (int.tryParse(_c[k]!.text.trim()) ?? _c[k]!.text.trim()) : _c[k]!.text.trim(),
      'addons_enabled': _addons,
      'cod_enabled': _cod,
    };
    try {
      final res = await Api.put('/admin/settings', body);
      for (final k in _text) {
        _c[k]!.text = '${res[k] ?? _c[k]!.text}';
      }
      if (mounted) toast(context, 'Pengaturan tersimpan');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _f(String key, String label, String hint, {bool number = false, int? maxLength, int lines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Label(label),
        TextField(
          controller: _c[key],
          keyboardType: number ? TextInputType.number : TextInputType.text,
          maxLength: maxLength,
          maxLines: lines,
          decoration: InputDecoration(hintText: tr(hint), counterText: ''),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            children: _fields(),
          ),
        ),
        BottomBar(
          child: FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'MENYIMPAN...' : 'SIMPAN PENGATURAN'),
          ),
        ),
      ],
    );
  }

  List<Widget> _fields() {
    final note = Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text('Footer, checkout, dan invoice di web langsung memakai nilai baru.', style: Brule.mono(10)),
    );
    return [
      if (_error != null) ...[const SizedBox(height: 8), ErrorBox(_error!)],
      ...switch (widget.section) {
        SettingsSection.identity => [
            _f('store_name', 'NAMA TOKO', 'contoh: BRÛLÉ', maxLength: 40),
            _f('tagline', 'TAGLINE', 'contoh: Specialty Coffee Lab', maxLength: 60),
            _f('city', 'KOTA', 'contoh: Bandung', maxLength: 40),
            _f('address', 'ALAMAT', 'contoh: Roastery BRÛLÉ, Bandung, Jawa Barat', maxLength: 160, lines: 2),
          ],
        SettingsSection.contact => [
            _f('email', 'EMAIL', 'contoh: halo@brule.id'),
            _f('whatsapp', 'WHATSAPP', 'contoh: 081234567890', number: true),
            _f('instagram', 'INSTAGRAM (TANPA @)', 'contoh: brule.coffeelab'),
          ],
        SettingsSection.shipping => [
            _f('shipping_flat', 'ONGKIR FLAT (Rp)', 'contoh: 15000', number: true),
            _f('free_from', 'GRATIS ONGKIR DI ATAS (Rp)', 'contoh: 500000', number: true),
            _f('low_stock', 'BATAS STOK MENIPIS (gram)', 'contoh: 5000', number: true),
          ],
        SettingsSection.fresh => [
            _f('best_before_days', 'MASA SEGAR SETELAH SANGRAI (hari)', 'contoh: 30', number: true),
          ],
        SettingsSection.addons => [
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Add-on aktif (bungkus kado, kartu ucapan)'),
              value: _addons,
              onChanged: (v) => setState(() => _addons = v),
            ),
            _f('gift_wrap_price', 'HARGA BUNGKUS KADO (Rp)', 'contoh: 15000', number: true),
            _f('card_price', 'HARGA KARTU UCAPAN (Rp)', 'contoh: 5000', number: true),
          ],
        SettingsSection.cod => [
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('COD aktif'),
              value: _cod,
              onChanged: (v) => setState(() => _cod = v),
            ),
            _f('cod_max', 'BATAS NILAI COD (Rp, 0 = tanpa batas)', 'contoh: 500000', number: true),
          ],
      },
      note,
    ];
  }
}
