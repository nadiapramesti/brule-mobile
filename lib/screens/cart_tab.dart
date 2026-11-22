import 'dart:async';
import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import '../api.dart';
import '../auth_gate.dart';
import '../cart.dart';
import '../models.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'checkout_screen.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Cart.I,
        builder: (context, _) {
          final lines = Cart.I.lines;
          return Column(
            children: [
              Expanded(
                child: Narrow(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                          child: Text('Pilih kopi di tab KATALOG dulu.',
                              style: Brule.mono(11)),
                        ),
                      ] else
                        for (final l in List.of(lines)) _Line(line: l),
                    ],
                  ),
                ),
              ),
              if (lines.isNotEmpty) _ShippingHint(subtotal: Cart.I.subtotal),
              if (lines.isNotEmpty) const _Summary(),
            ],
          );
        },
      ),
    );
  }
}

/// "Belanja Rp X lagi untuk gratis ongkir" dengan batang kemajuan. Angkanya dari server
/// (GET /cart/shipping), jadi ikut batas gratis ongkir yang diatur admin.
class _ShippingHint extends StatefulWidget {
  final int subtotal;
  const _ShippingHint({required this.subtotal});

  @override
  State<_ShippingHint> createState() => _ShippingHintState();
}

class _ShippingHintState extends State<_ShippingHint> {
  ShippingQuote? _quote;
  Timer? _debounce;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    _fetch(immediately: true);
  }

  @override
  void didUpdateWidget(covariant _ShippingHint old) {
    super.didUpdateWidget(old);
    if (old.subtotal != widget.subtotal) _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _fetch({bool immediately = false}) {
    _debounce?.cancel();
    _debounce = Timer(immediately ? Duration.zero : const Duration(milliseconds: 300), () async {
      final seq = ++_seq;
      try {
        final r = await Api.get('/cart/shipping', {'subtotal': '${widget.subtotal}'});
        if (mounted && seq == _seq) setState(() => _quote = ShippingQuote.fromJson(r));
      } on ApiException {
        // Petunjuk saja; tanpa data server, kartunya disembunyikan.
        if (mounted && seq == _seq) setState(() => _quote = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _quote;
    if (q == null || !q.hasPromo) return const SizedBox.shrink();
    final free = q.gap == 0;
    final progress = (widget.subtotal / q.freeFrom).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Brule.amber.withValues(alpha: 0.08),
        border: Border(top: BorderSide(color: Brule.hair(0.12))),
      ),
      child: Narrow(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(free ? Icons.check_circle_outline : Icons.local_shipping_outlined,
                    size: 18, color: Brule.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    free ? 'Ongkir gratis untuk pesanan ini' : 'Belanja ${rupiah(q.gap)} lagi untuk gratis ongkir',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: Brule.amber,
                backgroundColor: Brule.hair(0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Brule.field,
        border: Border(top: BorderSide(color: Brule.hair(0.12))),
      ),
      child: Narrow(
        child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL · ${Cart.I.count} ITEM', style: Brule.mono(10)),
                const SizedBox(height: 2),
                Text(rupiah(Cart.I.subtotal), style: Brule.condensed(22)),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () async {
              if (!await requireLogin(context, reason: 'Masuk dulu untuk checkout.')) return;
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              );
            },
            icon: const Icon(Icons.arrow_forward, size: 18),
            iconAlignment: IconAlignment.end,
            label: const Text('CHECKOUT'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
          ),
        ],
        ),
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
        border: Border.all(color: Brule.hair(0.1)),
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
                tooltip: tr('Hapus'),
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
