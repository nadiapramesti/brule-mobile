import 'dart:typed_data';
import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import 'package:image_picker/image_picker.dart';
import '../api.dart';
import '../motion.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'admin_kit.dart';

/// Tambah atau ubah kopi: cerita, asal-usul (ketertelusuran), level sangrai beserta harga, rasa, dan foto.
/// Aturan isiannya sama dengan form di panel web.
class CoffeeFormScreen extends StatefulWidget {
  final int? id; // null = kopi baru
  const CoffeeFormScreen({super.key, this.id});

  @override
  State<CoffeeFormScreen> createState() => _CoffeeFormScreenState();
}

class _Level {
  bool on = false;
  final price = TextEditingController();
  final agtron = TextEditingController();
  final notes = TextEditingController();
  Map<String, int> flavors = {};
  void dispose() {
    price.dispose();
    agtron.dispose();
    notes.dispose();
  }
}

class _CoffeeFormScreenState extends State<CoffeeFormScreen> {
  final _name = TextEditingController();
  final _story = TextEditingController();
  final _storyEn = TextEditingController();
  final _stock = TextEditingController(text: '0');
  final _cupping = TextEditingController();
  final _farmer = TextEditingController();
  final _region = TextEditingController();
  final _altitude = TextEditingController();
  final _varietal = TextEditingController();
  final _harvest = TextEditingController();
  final _qgrader = TextEditingController();
  String _process = 'Washed';
  bool _active = true;
  String? _slug;

  Map<String, String> _levelNames = {};
  Map<String, String> _processes = {'Washed': 'Washed'};
  List<String> _flavorKeys = const ['floral', 'citrus', 'berry', 'chocolate', 'nutty', 'spice'];
  final Map<String, _Level> _levels = {};

  String? _image;
  XFile? _picked;
  bool _removePhoto = false;

  bool _loading = true;
  bool _busy = false;
  String? _error;

  bool get _isNew => widget.id == null;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    for (final c in [_name, _story, _storyEn, _stock, _cupping, _farmer, _region, _altitude, _varietal, _harvest, _qgrader]) {
      c.dispose();
    }
    for (final l in _levels.values) {
      l.dispose();
    }
    super.dispose();
  }

  Map<String, String> _strMap(dynamic m) =>
      m is Map ? {for (final e in m.entries) '${e.key}': '${e.value}'} : <String, String>{};

  Future<void> _fetch() async {
    try {
      final r = _isNew ? await Api.get('/admin/coffees/meta') : await Api.get('/admin/coffees/${widget.id}');
      if (!mounted) return;
      setState(() {
        _levelNames = _strMap(r['levels']);
        _processes = _strMap({for (final p in (r['processes'] ?? []) as List) p: p});
        _flavorKeys = ((r['flavor_keys'] ?? _flavorKeys) as List).map((e) => '$e').toList();
        for (final k in _levelNames.keys) {
          _levels[k] = _Level()..flavors = {for (final f in _flavorKeys) f: 50};
        }
        if (!_isNew) {
          _name.text = '${r['name'] ?? ''}';
          _slug = r['slug'] as String?;
          _story.text = '${r['story'] ?? ''}';
          _storyEn.text = '${r['story_en'] ?? ''}';
          _stock.text = '${asInt(r['stock'])}';
          _cupping.text = r['cupping'] == null ? '' : '${r['cupping']}';
          _active = r['is_active'] == true;
          _image = r['image'] as String?;
          _farmer.text = '${r['farmer'] ?? ''}';
          _region.text = '${r['region'] ?? ''}';
          _altitude.text = r['altitude'] == null ? '' : '${r['altitude']}';
          _varietal.text = '${r['varietal'] ?? ''}';
          _process = '${r['process'] ?? 'Washed'}';
          _harvest.text = '${r['harvest_date'] ?? ''}';
          _qgrader.text = '${r['q_grader'] ?? ''}';
          final pr = r['profiles'];
          if (pr is Map) {
            for (final e in pr.entries) {
              final l = _levels['${e.key}'];
              final p = e.value as Map;
              if (l == null) continue;
              l.on = true;
              l.price.text = '${asInt(p['price'])}';
              l.agtron.text = p['agtron'] == null ? '' : '${p['agtron']}';
              l.notes.text = '${p['notes'] ?? ''}';
              final f = p['flavors'];
              if (f is Map) {
                for (final k in _flavorKeys) {
                  l.flavors[k] = asInt(f[k]);
                }
              }
            }
          }
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final need = <String, TextEditingController>{
      'Nama kopi': _name,
      'Cerita': _story,
      'Petani': _farmer,
      'Daerah': _region,
      'Ketinggian': _altitude,
      'Varietas': _varietal,
    };
    for (final e in need.entries) {
      if (e.value.text.trim().isEmpty) {
        setState(() => _error = '${tr(e.key)}: ${tr('wajib diisi')}.');
        return;
      }
    }
    final on = _levels.entries.where((e) => e.value.on).toList();
    if (on.isEmpty) {
      setState(() => _error = 'Aktifkan minimal satu level sangrai.');
      return;
    }
    for (final e in on) {
      if (e.value.price.text.trim().isEmpty || e.value.notes.text.trim().isEmpty) {
        setState(() => _error = 'Level ${_levelNames[e.key]}: harga dan catatan rasa wajib diisi.');
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = {
      'name': _name.text.trim(),
      if (_slug != null) 'slug': _slug,
      'story': _story.text.trim(),
      'story_en': _storyEn.text.trim().isEmpty ? null : _storyEn.text.trim(),
      'stock': int.tryParse(_stock.text.trim()) ?? 0,
      'cupping': _cupping.text.trim().isEmpty ? null : double.tryParse(_cupping.text.trim().replaceAll(',', '.')),
      'is_active': _active,
      'farmer': _farmer.text.trim(),
      'region': _region.text.trim(),
      'altitude': int.tryParse(_altitude.text.trim()),
      'varietal': _varietal.text.trim(),
      'process': _process,
      'harvest_date': _harvest.text.trim().isEmpty ? null : _harvest.text.trim(),
      'q_grader': _qgrader.text.trim().isEmpty ? null : _qgrader.text.trim(),
      'profiles': {
        for (final e in on)
          e.key: {
            'price': int.tryParse(e.value.price.text.trim()),
            'agtron': e.value.agtron.text.trim().isEmpty ? null : int.tryParse(e.value.agtron.text.trim()),
            'notes': e.value.notes.text.trim(),
            'flavors': e.value.flavors,
          },
      },
    };
    try {
      int? id = widget.id;
      if (_isNew) {
        final r = await Api.post('/admin/coffees', body);
        id = asInt((r['data'] ?? {})['id']);
      } else {
        await Api.put('/admin/coffees/${widget.id}', body);
      }
      if (id != null && id > 0) {
        try {
          if (_picked != null) {
            await Api.upload('/admin/coffees/$id/photo', 'photo', await _picked!.readAsBytes(), _picked!.name);
          } else if (_removePhoto && _image != null) {
            await Api.delete('/admin/coffees/$id/photo');
          }
        } on ApiException catch (e) {
          if (mounted) toast(context, 'Kopi tersimpan, tapi foto gagal: ${e.message}');
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
      }
      if (!mounted) return;
      toast(context, _isNew ? 'Kopi ditambahkan' : 'Perubahan disimpan');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPhoto(ImageSource src) async {
    try {
      final f = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 85);
      if (f != null && mounted) {
        setState(() {
          _picked = f;
          _removePhoto = false;
        });
      }
    } catch (_) {
      if (mounted) toast(context, 'Tidak bisa membuka ${src == ImageSource.camera ? 'kamera' : 'galeri'}.');
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_harvest.text) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (d != null) {
      setState(() => _harvest.text =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
    }
  }

  Widget _photo() {
    final hasNew = _picked != null;
    final hasOld = _image != null && !_removePhoto;
    Widget preview;
    if (hasNew) {
      preview = FutureBuilder<List<int>>(
        future: _picked!.readAsBytes(),
        builder: (context, s) => s.hasData
            ? Image.memory(Uint8List.fromList(s.data!), fit: BoxFit.cover)
            : Center(child: CircularProgressIndicator(color: Brule.amber)),
      );
    } else if (hasOld) {
      preview = Image.network(_image!, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(child: Icon(Icons.broken_image_outlined, color: Brule.kraft)));
    } else {
      preview = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 34, color: Brule.kraft.withValues(alpha: 0.6)),
          const SizedBox(height: 6),
          Text('Belum ada foto', style: Brule.mono(10)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Label('FOTO KOPI'),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 180,
            color: Brule.field,
            child: KeyedSubtree(key: ValueKey('${_picked?.path}$hasOld'), child: preview),
          ),
        ),
        const SizedBox(height: 10),
        ButtonRow(
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickPhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('GALERI'),
            ),
            OutlinedButton.icon(
              onPressed: () => _pickPhoto(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('KAMERA'),
            ),
            if (hasNew || hasOld)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Brule.red),
                onPressed: () => setState(() {
                  _picked = null;
                  _removePhoto = _image != null;
                }),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('HAPUS'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController c, String hint,
      {bool number = false, int? maxLength, int lines = 1, bool decimal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Label(label),
        TextField(
          controller: c,
          keyboardType: number
              ? TextInputType.numberWithOptions(decimal: decimal)
              : (lines > 1 ? TextInputType.multiline : TextInputType.text),
          maxLength: maxLength,
          minLines: lines,
          maxLines: lines,
          textCapitalization: number ? TextCapitalization.none : TextCapitalization.sentences,
          decoration: InputDecoration(hintText: tr(hint), counterText: ''),
        ),
      ],
    );
  }

  Widget _levelCard(String key) {
    final l = _levels[key]!;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(tr(_levelNames[key] ?? key), style: Brule.condensed(18))),
              Switch(value: l.on, onChanged: (v) => setState(() => l.on = v)),
            ],
          ),
          if (l.on) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _field('HARGA / 100 g (Rp)', l.price, 'contoh: 45000', number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field('AGTRON', l.agtron, 'contoh: 65', number: true)),
              ],
            ),
            _field('CATATAN RASA', l.notes, 'contoh: Jeruk, melati, madu', maxLength: 200),
            const Label('PROFIL RASA'),
            for (final f in _flavorKeys)
              Row(
                children: [
                  SizedBox(width: 82, child: Text(tr(f), style: Brule.mono(10))),
                  Expanded(
                    child: Slider(
                      value: (l.flavors[f] ?? 50).toDouble().clamp(0, 100),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: Brule.amber,
                      onChanged: (v) => setState(() => l.flavors[f] = v.round()),
                    ),
                  ),
                  SizedBox(width: 30, child: Text('${l.flavors[f] ?? 50}', style: Brule.mono(10))),
                ],
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: _isNew ? 'Kopi baru' : 'Ubah kopi',
      child: _loading
          ? Center(child: CircularProgressIndicator(color: Brule.amber))
          : Column(
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
                            _photo(),
                            const SizedBox(height: 4),
                            _field('NAMA KOPI', _name, 'contoh: Gayo Wine Natural', maxLength: 80),
                            const SizedBox(height: 14),
                            _field('CERITA', _story, 'contoh: Ditanam di dataran tinggi Gayo, dijemur 21 hari...',
                                maxLength: 1500, lines: 4),
                            const SizedBox(height: 14),
                            _field('CERITA (ENGLISH, OPSIONAL)', _storyEn,
                                'e.g. Grown in the Gayo highlands, sun-dried for 21 days...',
                                maxLength: 1500, lines: 3),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                    child: _field(_isNew ? 'STOK AWAL (gram)' : 'STOK (gram)', _stock, 'contoh: 5000',
                                        number: true)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _field('SKOR CUPPING', _cupping, 'contoh: 86.5',
                                        number: true, decimal: true)),
                              ],
                            ),
                            const Label('ASAL-USUL'),
                            _field('PETANI / KOPERASI', _farmer, 'contoh: Koperasi Ketiara', maxLength: 120),
                            const SizedBox(height: 14),
                            _field('DAERAH', _region, 'contoh: Takengon, Aceh Tengah', maxLength: 120),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _field('KETINGGIAN (mdpl)', _altitude, 'contoh: 1400', number: true)),
                                const SizedBox(width: 10),
                                Expanded(child: _field('VARIETAS', _varietal, 'contoh: Ateng, Typica', maxLength: 120)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            PickField<String>(
                              label: 'PROSES',
                              options: _processes,
                              value: _processes.containsKey(_process) ? _process : _processes.keys.first,
                              all: '',
                              onChanged: (k) => setState(() => _process = k),
                            ),
                            const Label('TANGGAL PANEN (OPSIONAL)'),
                            TextField(
                              controller: _harvest,
                              readOnly: true,
                              onTap: _pickDate,
                              decoration: InputDecoration(
                                hintText: tr('contoh: 2026-06-15'),
                                suffixIcon: _harvest.text.isEmpty
                                    ? const Icon(Icons.event_outlined, size: 20)
                                    : IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () => setState(() => _harvest.clear())),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _field('Q GRADER (OPSIONAL)', _qgrader, 'contoh: Rina Wulandari', maxLength: 120),
                            const Label('LEVEL SANGRAI'),
                            Text('Aktifkan level yang dijual. Minimal satu.', style: Brule.mono(9.5)),
                            const SizedBox(height: 8),
                            for (final k in _levelNames.keys) _levelCard(k),
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
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Brule.cream))
                            : const Icon(Icons.check, size: 18),
                        label: Text(_busy ? 'MENYIMPAN...' : (_isNew ? 'SIMPAN KOPI' : 'SIMPAN PERUBAHAN')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
