import 'package:flutter/material.dart';
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
                      const Label('BIJI UTAMA'),
                      ChipPicker<Coffee>(
                        items: coffees,
                        value: _a,
                        label: (c) => c.shortName,
                        onChanged: (c) => _pickA(c),
                      ),
                      if (_a != null) ...[
                        const Label('TINGKAT SANGRAI'),
                        ChipPicker<RoastProfile>(
                          items: _levels(),
                          value: _profile(_a),
                          label: (p) => p.levelLabel,
                          onChanged: (p) => setState(() {
                            _level = p.level;
                            if (_b != null && _profile(_b) == null) _b = null;
                          }),
                        ),
                        const Label('BIJI KEDUA (OPSIONAL)'),
                        if (partners.isEmpty)
                          Text('Tidak ada kopi lain dengan sangrai ini.', style: Brule.mono(10))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('TANPA BLEND'),
                                selected: _b == null,
                                onSelected: (_) => setState(() => _b = null),
                              ),
                              for (final c in partners)
                                ChoiceChip(
                                  label: Text(c.shortName),
                                  selected: _b?.id == c.id,
                                  onSelected: (_) => setState(() => _b = c),
                                ),
                            ],
                          ),
                        if (blend) ...[
                          const Label('PORSI'),
                          ChipPicker<int>(
                            items: _kRatios,
                            value: _ratio,
                            label: (r) => '$r / ${100 - r}',
                            onChanged: (r) => setState(() => _ratio = r),
                          ),
                        ],
                        const Label('BERAT'),
                        ChipPicker<int>(
                          items: kGrams,
                          value: _grams,
                          label: (g) => '$g g',
                          onChanged: (g) => setState(() => _grams = g),
                        ),
                        const Label('GILINGAN'),
                        ChipPicker<String>(
                          items: kGrinds.keys.toList(),
                          value: _grind,
                          label: (k) => kGrinds[k]!,
                          onChanged: (k) => setState(() => _grind = k),
                        ),
                        const Label('PRATINJAU RASA'),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Brule.field,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                blend
                                    ? '${_a!.shortName} $_ratio / ${_b!.shortName} ${100 - _ratio}'
                                    : _a!.name,
                                style: Brule.condensed(20),
                              ),
                              if (blend) ...[
                                const SizedBox(height: 4),
                                Text('$_ga g + ${_grams - _ga} g', style: Brule.mono(10)),
                              ],
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [for (final n in _notes()) Tag(n)],
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
              if (_a != null)
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
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
                            onPressed: _add,
                            child: Text('TAMBAH · ${rupiah(total)}'),
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
                backgroundColor: Colors.white.withValues(alpha: 0.08),
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
