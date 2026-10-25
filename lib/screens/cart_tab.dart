import 'package:flutter/material.dart';
import '../cart.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'checkout_screen.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: Cart.I,
        builder: (context, _) {
          final lines = Cart.I.lines;
          return Narrow(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Row(
                  children: [
                    Container(width: 18, height: 3, color: Brule.amber),
                    const SizedBox(width: 10),
                    Text('KERANJANG', style: Brule.condensed(22, spacing: 2)),
                  ],
                ),
                const SizedBox(height: 16),
                if (lines.isEmpty) ...[
                  const SizedBox(height: 48),
                  Icon(Icons.shopping_basket_outlined,
                      size: 56, color: Brule.kraft.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  const Center(child: Text('Keranjang masih kosong.')),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('Pilih kopi di tab KOPI dulu.',
                        style: Brule.mono(11)),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Brule.field,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('SUBTOTAL (${Cart.I.count} ITEM)', style: Brule.mono(11)),
                        const SizedBox(height: 4),
                        Text(rupiah(Cart.I.subtotal), style: Brule.condensed(28)),
                        const SizedBox(height: 4),
                        Text('Ongkir dan diskon dihitung saat pesanan dibuat.',
                            style: Brule.mono(10)),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                          ),
                          child: const Text('LANJUT KE CHECKOUT'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final l in List.of(lines)) _Line(line: l),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final CartLine line;
  const _Line({required this.line});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(width: 64, height: 64, child: NetImage(url: line.image)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.name, style: Brule.condensed(17)),
                    const SizedBox(height: 4),
                    Text(line.detail, style: Brule.mono(10, color: Brule.amber)),
                    const SizedBox(height: 4),
                    Text('${rupiah(line.unit)} / item',
                        style: TextStyle(color: Brule.kraft.withValues(alpha: 0.9), fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Hapus',
                onPressed: () => Cart.I.remove(line),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              QtyStepper(qty: line.qty, onChanged: (q) => Cart.I.setQty(line, q)),
              const Spacer(),
              Text(rupiah(line.total), style: Brule.condensed(20)),
            ],
          ),
        ],
      ),
    );
  }
}
