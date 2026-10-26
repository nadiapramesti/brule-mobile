import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'auth_gate.dart';
import 'cart.dart';
import 'models.dart';
import 'theme.dart';
import 'util.dart';
import 'widgets.dart';

/// Perlengkapan tanpa pilihan: langsung masuk keranjang. Kalau ada pilihan (warna, ukuran),
/// buka menu pilihan dulu.
Future<void> addGearQuick(BuildContext context, Gear g) async {
  if (!await requireLogin(context)) return;
  if (!context.mounted) return;
  if (g.options.isEmpty) {
    Cart.I.add(CartLine(
      kind: 'gear',
      refId: g.id,
      name: g.name,
      detail: g.category,
      unit: g.price,
      image: g.image,
    ));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${g.name} masuk keranjang')));
    return;
  }
  await _open(context, _GearSheet(gear: g));
}

/// Kopi selalu punya pilihan (sangrai, berat, gilingan), jadi selalu lewat menu pilihan.
Future<void> addCoffeeSheet(BuildContext context, Coffee c) async {
  if (!await requireLogin(context)) return;
  if (!context.mounted) return;
  await _open(context, _CoffeeSheet(coffee: c));
}

Future<void> _open(BuildContext context, Widget child) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Brule.sheet,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (_) => child,
  );
}

class _SheetFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SheetFrame({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: Brule.condensed(22))),
                IconButton(
                  tooltip: tr('Tutup'),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _CoffeeSheet extends StatefulWidget {
  final Coffee coffee;
  const _CoffeeSheet({required this.coffee});

  @override
  State<_CoffeeSheet> createState() => _CoffeeSheetState();
}

class _CoffeeSheetState extends State<_CoffeeSheet> {
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
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text('${c.name} masuk keranjang')));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coffee;
    final total = _profile.priceFor(_grams) * _qty;

    return _SheetFrame(
      title: c.name,
      children: [
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
        const SizedBox(height: 18),
        Row(
          children: [
            QtyStepper(qty: _qty, onChanged: (q) => setState(() => _qty = q.clamp(1, 20).toInt())),
            const Spacer(),
            Text(rupiah(total), style: Brule.condensed(24)),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: c.inStock ? _add : null,
          child: Text(c.inStock ? 'TAMBAH KE KERANJANG' : 'STOK HABIS'),
        ),
      ],
    );
  }
}

class _GearSheet extends StatefulWidget {
  final Gear gear;
  const _GearSheet({required this.gear});

  @override
  State<_GearSheet> createState() => _GearSheetState();
}

class _GearSheetState extends State<_GearSheet> {
  String? _option;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    if (widget.gear.options.isNotEmpty) _option = widget.gear.options.first;
  }

  void _add() {
    final g = widget.gear;
    Cart.I.add(CartLine(
      kind: 'gear',
      refId: g.id,
      name: g.name,
      detail: _option ?? g.category,
      unit: g.price,
      image: (_option != null ? g.optionImages[_option] : null) ?? g.image,
      option: _option,
      qty: _qty,
    ));
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text('${g.name} masuk keranjang')));
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.gear;
    final maxQty = g.stock < 1 ? 1 : g.stock.clamp(1, 20).toInt();

    return _SheetFrame(
      title: g.name,
      children: [
        Label((g.optionLabel ?? 'PILIHAN').toUpperCase()),
        ChipPicker<String>(
          items: g.options,
          value: _option,
          label: (o) => o,
          onChanged: (o) => setState(() => _option = o),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            QtyStepper(
              qty: _qty,
              onChanged: (q) => setState(() => _qty = q.clamp(1, maxQty).toInt()),
            ),
            const Spacer(),
            Text(rupiah(g.price * _qty), style: Brule.condensed(24)),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: g.inStock ? _add : null,
          child: Text(g.inStock ? 'TAMBAH KE KERANJANG' : 'STOK HABIS'),
        ),
      ],
    );
  }
}
