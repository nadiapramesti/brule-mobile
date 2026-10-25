import 'package:flutter/material.dart';
import '../cart.dart';
import '../models.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

class GearDetailScreen extends StatefulWidget {
  final Gear gear;
  const GearDetailScreen({super.key, required this.gear});

  @override
  State<GearDetailScreen> createState() => _GearDetailScreenState();
}

class _GearDetailScreenState extends State<GearDetailScreen> {
  String? _option;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    final o = widget.gear.options;
    if (o.isNotEmpty) _option = o.first;
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ditambahkan ke keranjang')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.gear;
    final image = (_option != null ? g.optionImages[_option] : null) ?? g.image;

    return Scaffold(
      appBar: AppBar(title: const Text('DETAIL PRODUK')),
      body: Narrow(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(aspectRatio: 16 / 9, child: NetImage(url: image)),
            ),
            const SizedBox(height: 16),
            Text(g.name, style: Brule.condensed(28)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                Tag(g.category.toUpperCase()),
                if (!g.inStock) const Tag('STOK HABIS', color: Brule.red),
              ],
            ),
            if (g.options.isNotEmpty) ...[
              Label((g.optionLabel ?? 'PILIHAN').toUpperCase()),
              ChipPicker<String>(
                items: g.options,
                value: _option,
                label: (o) => o,
                onChanged: (o) => setState(() => _option = o),
              ),
            ],
            const Label('JUMLAH'),
            Align(
              alignment: Alignment.centerLeft,
              child: QtyStepper(
                qty: _qty,
                onChanged: (q) => setState(() => _qty = q.clamp(1, g.stock < 1 ? 1 : g.stock.clamp(1, 20).toInt()).toInt()),
              ),
            ),
            const SizedBox(height: 20),
            Text(rupiah(g.price * _qty), style: Brule.condensed(26)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: g.inStock ? _add : null,
              child: Text(g.inStock ? 'TAMBAH KE KERANJANG' : 'STOK HABIS'),
            ),
            if (g.description != null && g.description!.isNotEmpty) ...[
              const Label('DESKRIPSI'),
              Text(g.description!,
                  style: TextStyle(color: Brule.kraft.withValues(alpha: 0.95), height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}
