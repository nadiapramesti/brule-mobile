import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import '../api.dart';
import '../auth_gate.dart';
import '../cart.dart';
import '../models.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

const _kRatios = [70, 60, 50];

const _kFlavorLabels = {
  'floral': 'FLORAL',
  'citrus': 'JERUK',
  'berry': 'BERI',
  'chocolate': 'COKELAT',
  'nutty': 'KACANG',
  'spice': 'REMPAH',
};

/// Racik blend sendiri: dua kopi dengan tingkat sangrai sama, dicampur dengan porsi 70/60/50.
class BlendScreen extends StatefulWidget {
  const BlendScreen({super.key});

  @override
  State<BlendScreen> createState() => _BlendScreenState();
}

class _BlendScreenState extends State<BlendScreen> {
  Coffee? _a;
  Coffee? _b;
  String _level = 'medium';
  int _ratio = 70;
  int _grams = 250;
  String _grind = 'whole_bean';
  int _qty = 1;

  Future<List<Coffee>> _load() async {
    final res = await Api.get('/coffees');
    return (res['data'] as List)
        .map((e) => Coffee.fromJson(e as Map<String, dynamic>))
        .where((c) => c.inStock && c.profiles.isNotEmpty)
        .toList();
  }

  RoastProfile? _profile(Coffee? c) {
    if (c == null) return null;
    for (final p in c.profiles) {
      if (p.level == _level) return p;
    }
    return null;
  }

  /// Tingkat sangrai yang dimiliki biji utama (blend wajib satu level).
  List<RoastProfile> _levels() => _a?.profiles ?? const [];

  void _pickA(Coffee c) {
    setState(() {
      _a = c;
      if (!c.profiles.any((p) => p.level == _level)) _level = c.profiles.first.level;
      if (_b != null && (_b!.id == c.id || _profile(_b) == null)) _b = null;
    });
  }

  int get _ga => (_grams * _ratio / 100).round();

  int _price() {
    final pa = _profile(_a);
    if (pa == null) return 0;
    final pb = _profile(_b);
    if (pb == null) return pa.priceFor(_grams);
    return pa.priceFor(_ga) + pb.priceFor(_grams - _ga);
  }

  Map<String, int> _mix() {
    final pa = _profile(_a);
    final pb = _profile(_b);
    if (pa == null) return {};
    if (pb == null) return pa.flavor;
    final keys = {...pa.flavor.keys, ...pb.flavor.keys};
    return {
      for (final k in keys)
        k: ((pa.flavor[k] ?? 0) * _ratio / 100 + (pb.flavor[k] ?? 0) * (100 - _ratio) / 100)
            .round(),
    };
  }

  List<String> _notes() {
    final pa = _profile(_a);
    final pb = _profile(_b);
    if (pa == null) return const [];
    if (pb == null) return pa.notes;
    final na = pa.notes.take(_ratio >= 60 ? 3 : 2);
    final nb = pb.notes.take(2);
    return {...na, ...nb}.toList();
  }

  Future<void> _add() async {
    final a = _a;
    final pa = _profile(a);
    if (a == null || pa == null) return;
    if (!await requireLogin(context, reason: 'Masuk dulu untuk memesan blend.')) return;
    if (!mounted) return;
    final b = _b;
    final pb = _profile(b);
    final blend = b != null && pb != null;
    final name = blend ? '${a.shortName} $_ratio / ${b.shortName} ${100 - _ratio}' : a.name;
    Cart.I.add(CartLine(
      kind: 'coffee',
      refId: pa.id,
      name: name,
      detail:
          '${pa.levelLabel} · $_grams g · ${kGrinds[_grind]}${blend ? ' · ${_ga}g + ${_grams - _ga}g' : ''}',
      unit: _price(),
      image: a.image,
      grams: _grams,
      grind: _grind,
      blendId: blend ? pb.id : null,
      ratio: blend ? _ratio : null,
      qty: _qty,
    ));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$name masuk keranjang')));
    Navigator.of(context).pop();
  }

  /// Daftar biji dalam bottom sheet (menggantikan deretan chip yang bisa digeser).
  Future<_Pick?> _sheet(List<Coffee> items, Coffee? current, {required String title, bool allowNone = false}) {
    return showModalBottomSheet<_Pick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Brule.sheet,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 14),
                decoration: BoxDecoration(color: Brule.hair(0.2), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(title, style: Brule.condensed(22)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  if (allowNone)
                    _BeanRow(
                      title: 'TANPA BLEND',
                      sub: 'Pakai satu biji saja',
                      selected: current == null,
                      onTap: () => Navigator.of(ctx).pop(const _Pick(null)),
                    ),
                  for (final c in items)
                    _BeanRow(
                      title: c.name,
                      sub: c.process ?? '',
                      price: '${rupiah(c.fromPrice)} / 100 g',
                      selected: current?.id == c.id,
                      onTap: () => Navigator.of(ctx).pop(_Pick(c)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseA(List<Coffee> coffees) async {
    final r = await _sheet(coffees, _a, title: 'Pilih biji utama');
    if (r?.c != null) _pickA(r!.c!);
  }

  Future<void> _chooseB(List<Coffee> partners) async {
    final r = await _sheet(partners, _b, title: 'Pilih biji kedua', allowNone: true);
    if (r != null) setState(() => _b = r.c);
  }

  /// Ringkasan blend yang selalu tampil di atas: nama, batang porsi, dan gram tiap biji.
  Widget _summary() {
    final a = _a;
    final b = _b;
    final blend = a != null && b != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Brule.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Brule.hair(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BLEND KAMU', style: Brule.mono(9.5, color: Brule.amber)),
          const SizedBox(height: 8),
          Text(
            a == null ? 'Belum ada biji' : (blend ? '${a.shortName} + ${b!.shortName}' : a.name),
            style: Brule.condensed(24),
          ),
          const SizedBox(height: 4),
          Text(
            a == null ? 'Pilih biji utama untuk mulai meracik.' : '${_profile(a)?.levelLabel ?? ''} · $_grams g',
            style: Brule.mono(10),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: a == null
                  ? ColoredBox(color: Brule.hair(0.08))
                  : Row(
                      children: [
                        Expanded(flex: blend ? _ratio : 100, child: ColoredBox(color: Brule.amber)),
                        if (blend) const SizedBox(width: 2),
                        if (blend)
                          Expanded(flex: 100 - _ratio, child: ColoredBox(color: Brule.kraft.withValues(alpha: 0.55))),
                      ],
                    ),
            ),
          ),
          if (a != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(blend ? '$_ga g' : '$_grams g', style: Brule.mono(9.5, color: Brule.amber)),
                if (blend) Text('${_grams - _ga} g', style: Brule.mono(9.5)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Racik Blend', style: Brule.condensed(22))),
      body: Loader<List<Coffee>>(
        load: _load,
        builder: (context, coffees, reload) {
          if (coffees.length < 2) {
            return const Center(child: Text('Belum cukup kopi tersedia untuk diracik.'));
          }
          final partners = _a == null
              ? <Coffee>[]
              : coffees
                  .where((c) => c.id != _a!.id && c.profiles.any((p) => p.level == _level))
                  .toList();
          final total = _price() * _qty;
          final mix = _mix();
          final blend = _b != null;
          var n = 0;
          String step(String t) => '${(++n).toString().padLeft(2, '0')} · $t';

          return Column(
            children: [
              Expanded(
                child: Narrow(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      Text(
                        'Campur dua kopi dengan tingkat sangrai yang sama. Harga mengikuti porsi masing-masing biji.',
                        style: TextStyle(color: Brule.kraft.withValues(alpha: 0.9), height: 1.45),
                      ),
                      const SizedBox(height: 16),
                      _summary(),
                      Label(step('BIJI UTAMA')),
                      _Slot(
                        badge: 'A',
                        title: _a?.name ?? 'Belum dipilih',
                        sub: _a == null ? 'Ketuk PILIH untuk melihat daftar' : _a!.process,
                        filled: _a != null,
                        onTap: () => _chooseA(coffees),
                      ),
                      Label(step('TINGKAT SANGRAI')),
                      if (_a == null)
                        Text('Pilih biji utama dulu.', style: Brule.mono(10))
                      else
                        _Choices<RoastProfile>(
                          items: _levels(),
                          value: _profile(_a),
                          label: (p) => p.levelLabel,
                          onChanged: (p) => setState(() {
                            _level = p.level;
                            if (_b != null && _profile(_b) == null) _b = null;
                          }),
                        ),
                      Label(step('BIJI KEDUA (OPSIONAL)')),
                      if (_a == null)
                        Text('Pilih biji utama dulu.', style: Brule.mono(10))
                      else if (partners.isEmpty)
                        Text('Tidak ada kopi lain dengan sangrai ini.', style: Brule.mono(10))
                      else
                        _Slot(
                          badge: 'B',
                          title: _b?.name ?? 'TANPA BLEND',
                          sub: _b == null ? 'Pakai satu biji saja' : _b!.process,
                          filled: _b != null,
                          onTap: () => _chooseB(partners),
                        ),
                      if (blend) ...[
                        Label(step('PORSI')),
                        _Choices<int>(
                          items: _kRatios,
                          value: _ratio,
                          label: (r) => '$r / ${100 - r}',
                          onChanged: (r) => setState(() => _ratio = r),
                        ),
                      ],
                      Label(step('BERAT')),
                      _Choices<int>(
                        items: kGrams,
                        value: _grams,
                        label: (g) => '$g g',
                        onChanged: (g) => setState(() => _grams = g),
                      ),
                      Label(step('GILINGAN')),
                      _Choices<String>(
                        items: kGrinds.keys.toList(),
                        value: _grind,
                        label: (k) => kGrinds[k]!,
                        onChanged: (k) => setState(() => _grind = k),
                      ),
                      if (_a != null) ...[
                        const Label('PRATINJAU RASA'),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Brule.field,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Brule.hair(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [for (final note in _notes()) Tag(note)],
                              ),
                              const SizedBox(height: 14),
                              for (final e in _kFlavorLabels.entries)
                                if (mix.containsKey(e.key)) _FlavorBar(e.value, mix[e.key]!),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  decoration: BoxDecoration(
                    color: Brule.sheet,
                    border: Border(top: BorderSide(color: Brule.hair(0.1))),
                  ),
                  child: Row(
                    children: [
                      QtyStepper(
                        qty: _qty,
                        onChanged: (q) => setState(() => _qty = q.clamp(1, 20).toInt()),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FilledButton(
                          onPressed: _a == null ? null : _add,
                          child: Text(_a == null ? 'PILIH BIJI DULU' : 'TAMBAH · ${rupiah(total)}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Hasil pilihan dari bottom sheet (c == null artinya "tanpa blend").
class _Pick {
  final Coffee? c;
  const _Pick(this.c);
}

/// Pilihan jenis tombol yang membungkus ke baris berikutnya, tidak perlu digeser.
class _Choices<T> extends StatelessWidget {
  final List<T> items;
  final T? value;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  const _Choices({required this.items, required this.value, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final i in items)
          ChoiceChip(
            label: Text(label(i)),
            selected: i == value,
            onSelected: (_) => onChanged(i),
          ),
      ],
    );
  }
}

/// Kartu pilihan biji: lencana huruf, nama, dan tombol PILIH/GANTI yang jelas terlihat sebagai tombol.
class _Slot extends StatelessWidget {
  final String badge;
  final String title;
  final String? sub;
  final bool filled;
  final VoidCallback onTap;
  const _Slot({required this.badge, required this.title, this.sub, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Brule.amber;
    return Material(
      color: Brule.field,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: filled ? accent.withValues(alpha: 0.6) : Brule.hair(0.16)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: filled ? accent.withValues(alpha: 0.12) : null,
                  border: Border.all(color: filled ? accent : Brule.hair(0.25)),
                ),
                child: Text(badge, style: Brule.mono(13, color: filled ? accent : null)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Brule.condensed(18), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (sub != null && sub!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(sub!, style: Brule.mono(9.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accent),
                ),
                child: Text(filled ? 'GANTI' : 'PILIH', style: Brule.mono(10, color: accent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BeanRow extends StatelessWidget {
  final String title;
  final String sub;
  final String? price;
  final bool selected;
  final VoidCallback onTap;
  const _BeanRow({required this.title, required this.sub, this.price, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Brule.amber;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? accent.withValues(alpha: 0.10) : Brule.field,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: selected ? accent : Brule.hair(0.12), width: selected ? 1.4 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Brule.condensed(18)),
                      if (sub.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(sub, style: Brule.mono(9.5)),
                      ],
                    ],
                  ),
                ),
                if (price != null) ...[
                  const SizedBox(width: 10),
                  Text(price!, style: Brule.mono(10)),
                ],
                const SizedBox(width: 10),
                Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                    size: 20, color: selected ? accent : Brule.hair(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlavorBar extends StatelessWidget {
  final String label;
  final int value;
  const _FlavorBar(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: Brule.mono(9))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (value / 100).clamp(0, 1).toDouble(),
                minHeight: 6,
                backgroundColor: Brule.hair(0.08),
                color: Brule.amber,
              ),
            ),
          ),
          SizedBox(
            width: 34,
            child: Text('$value', textAlign: TextAlign.right, style: Brule.mono(9)),
          ),
        ],
      ),
    );
  }
}
