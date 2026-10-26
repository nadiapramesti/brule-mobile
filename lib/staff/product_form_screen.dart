import 'package:flutter/material.dart';
import '../api.dart';
import '../motion.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'admin_kit.dart';

/// Tambah atau ubah perlengkapan (alat seduh, filter, merchandise, dll).
/// Foto produk masih diatur lewat panel web.
class ProductFormScreen extends StatefulWidget {
  final int? id; // null = produk baru
  final Map<String, String> categories;
  const ProductFormScreen({super.key, this.id, required this.categories});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _optLabel = TextEditingController();
  final _options = TextEditingController();
  String _category = '';
  bool _active = true;
  String? _nameEn;
  String? _descEn;

  bool _loading = false;
  bool _busy = false;
  String? _error;

  bool get _isNew => widget.id == null;

  @override
  void initState() {
    super.initState();
    _category = widget.categories.keys.firstOrNull ?? 'brewer';
    if (!_isNew) _fetch();
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _price, _stock, _optLabel, _options]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final r = await Api.get('/admin/products/${widget.id}');
      final p = (r['data'] ?? {}) as Map;
      if (!mounted) return;
      setState(() {
        _name.text = '${p['name'] ?? ''}';
        _desc.text = '${p['description'] ?? ''}';
        _price.text = '${asInt(p['price'])}';
        _stock.text = '${asInt(p['stock'])}';
        _optLabel.text = '${p['option_label'] ?? ''}';
        _options.text = ((p['options'] ?? []) as List).join(', ');
        _category = '${p['category']}';
        _active = p['is_active'] == true;
        _nameEn = p['name_en'] as String?;
        _descEn = p['description_en'] as String?;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _desc.text.trim().isEmpty || _price.text.trim().isEmpty) {
      setState(() => _error = 'Nama, deskripsi, dan harga wajib diisi.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = {
      'name': _name.text.trim(),
      'name_en': _nameEn,
      'category': _category,
      'description': _desc.text.trim(),
      'description_en': _descEn,
      'price': int.tryParse(_price.text.trim()),
      'stock': int.tryParse(_stock.text.trim()) ?? 0,
      'option_label': _optLabel.text.trim().isEmpty ? null : _optLabel.text.trim(),
      'options': _options.text.trim().isEmpty ? null : _options.text.trim(),
      'is_active': _active,
    };
    try {
      if (_isNew) {
        await Api.post('/admin/products', body);
      } else {
        await Api.put('/admin/products/${widget.id}', body);
      }
      if (!mounted) return;
      toast(context, _isNew ? 'Perlengkapan ditambahkan' : 'Perubahan disimpan');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(String label, TextEditingController c, String hint,
      {bool number = false, int? maxLength, int lines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Label(label),
        TextField(
          controller: c,
          keyboardType: number ? TextInputType.number : (lines > 1 ? TextInputType.multiline : TextInputType.text),
          maxLength: maxLength,
          minLines: lines,
          maxLines: lines,
          textCapitalization: number ? TextCapitalization.none : TextCapitalization.sentences,
          decoration: InputDecoration(hintText: hint, counterText: ''),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: _isNew ? 'Perlengkapan baru' : 'Ubah perlengkapan',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Brule.amber))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // aksi utama di atas halaman
                Reveal(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Brule.cream))
                        : const Icon(Icons.check, size: 18),
                    label: Text(_busy ? 'MENYIMPAN...' : (_isNew ? 'SIMPAN PERLENGKAPAN' : 'SIMPAN PERUBAHAN')),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: _error == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(padding: const EdgeInsets.only(top: 10), child: ErrorBox(_error!)),
                ),
                const SizedBox(height: 4),
                Reveal(
                  index: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field('NAMA PRODUK', _name, 'contoh: Hario V60 02 Keramik', maxLength: 100),
                      const SizedBox(height: 14),
                      PickField<String>(
                        label: 'KATEGORI',
                        options: widget.categories,
                        value: widget.categories.containsKey(_category) ? _category : widget.categories.keys.first,
                        all: '',
                        onChanged: (k) => setState(() => _category = k),
                      ),
                      _field('DESKRIPSI SINGKAT', _desc, 'contoh: Dripper keramik tahan panas untuk 1-4 cangkir',
                          maxLength: 400, lines: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _field('HARGA (Rp)', _price, 'contoh: 185000', number: true)),
                          const SizedBox(width: 10),
                          Expanded(child: _field(_isNew ? 'STOK AWAL' : 'STOK', _stock, 'contoh: 20', number: true)),
                        ],
                      ),
                      const Label('VARIAN (OPSIONAL)'),
                      Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Isi kalau produk punya pilihan, misalnya warna atau ukuran.', style: Brule.mono(9.5)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _optLabel,
                              maxLength: 30,
                              decoration: const InputDecoration(
                                  labelText: 'Nama pilihan', hintText: 'contoh: Warna', counterText: ''),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _options,
                              maxLength: 200,
                              decoration: const InputDecoration(
                                  labelText: 'Isi pilihan, pisahkan dengan koma',
                                  hintText: 'contoh: Hitam, Putih, Krem',
                                  counterText: ''),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tampil di toko'),
                        subtitle: Text('Matikan untuk menyembunyikan dari pelanggan', style: Brule.mono(9.5)),
                        value: _active,
                        onChanged: (v) => setState(() => _active = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
