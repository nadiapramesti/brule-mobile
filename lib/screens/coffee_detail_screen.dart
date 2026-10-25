import 'package:flutter/material.dart';
import '../cart.dart';
import '../models.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

class CoffeeDetailScreen extends StatefulWidget {
  final Coffee coffee;
  const CoffeeDetailScreen({super.key, required this.coffee});

  @override
  State<CoffeeDetailScreen> createState() => _CoffeeDetailScreenState();
}

class _CoffeeDetailScreenState extends State<CoffeeDetailScreen> {
  late RoastProfile _profile;
  int _grams = 250;
  String _grind = 'whole_bean';
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    final ps = widget.coffee.profiles;
    _profile = ps.firstWhere((p) => p.level == 'medium', orElse: () => ps.first);
  }

  void _add() {
    final c = widget.coffee;
    Cart.I.add(CartLine(
      kind: 'coffee',
      refId: _profile.id,
      name: c.name,
      detail: '${_profile.levelLabel} · $_grams g · ${kGrinds[_grind]}',
      unit: _profile.priceFor(_grams),
      image: c.image,
      grams: _grams,
      grind: _grind,
      qty: _qty,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ditambahkan ke keranjang')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coffee;
    final total = _profile.priceFor(_grams) * _qty;

    return Scaffold(
      appBar: AppBar(title: const Text('DETAIL KOPI')),
      body: Narrow(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(aspectRatio: 16 / 9, child: NetImage(url: c.image)),
            ),
            const SizedBox(height: 16),
            Text(c.name, style: Brule.condensed(28)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (c.cupping != null)
                  Tag('CUPPING ${c.cupping!.toStringAsFixed(1)}', color: Brule.amber),
                if (_profile.agtron != null) Tag('AGTRON ${_profile.agtron}'),
                if (!c.inStock) const Tag('STOK HABIS', color: Brule.red),
              ],
            ),
            if (_profile.notes.isNotEmpty) ...[
              const Label('NOTES RASA'),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [for (final n in _profile.notes) Tag(n, color: Brule.blueText)],
              ),
            ],
            const Label('TINGKAT SANGRAI'),
            ChipPicker<RoastProfile>(
              items: c.profiles,
              value: _profile,
              label: (p) => p.levelLabel,
              onChanged: (p) => setState(() => _profile = p),
            ),
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
            const Label('JUMLAH'),
            Align(
              alignment: Alignment.centerLeft,
              child: QtyStepper(qty: _qty, onChanged: (q) => setState(() => _qty = q.clamp(1, 20).toInt())),
            ),
            const SizedBox(height: 20),
            Text(rupiah(total), style: Brule.condensed(26)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: c.inStock ? _add : null,
              child: Text(c.inStock ? 'TAMBAH KE KERANJANG' : 'STOK HABIS'),
            ),
            if (c.story != null && c.story!.isNotEmpty) ...[
              const Label('CERITA'),
              Text(c.story!,
                  style: TextStyle(color: Brule.kraft.withValues(alpha: 0.95), height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}
