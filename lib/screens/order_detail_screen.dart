import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import '../api.dart';
import '../cart.dart';
import '../models.dart';
import '../order_timeline.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import '../staff/download.dart';
import 'payment_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final String code;
  const OrderDetailScreen({super.key, required this.code});

  Future<Order> _load() async => Order.fromJson(await Api.get('/orders/$code'));

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pay(BuildContext context, Future<void> Function() reload) async {
    try {
      final r = await Api.post('/orders/$code/pay');
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PaymentScreen(url: '${r['redirect_url']}')),
      );
      await Api.post('/orders/$code/sync');
      AppEvents.ordersChanged.value++;
      await reload();
    } on ApiException catch (e) {
      if (context.mounted) _toast(context, e.message);
    }
  }

  Future<void> _sync(BuildContext context, Future<void> Function() reload) async {
    try {
      await Api.post('/orders/$code/sync');
      AppEvents.ordersChanged.value++;
      await reload();
    } on ApiException catch (e) {
      if (context.mounted) _toast(context, e.message);
    }
  }

  Future<void> _cancel(BuildContext context, Future<void> Function() reload) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: const Text('Stok dan voucher akan dikembalikan. Aksi ini tidak bisa diulang.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('TIDAK')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('YA, BATALKAN'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.post('/orders/$code/cancel');
      AppEvents.ordersChanged.value++;
      await reload();
    } on ApiException catch (e) {
      if (context.mounted) _toast(context, e.message);
    }
  }

  Widget _money(String label, int v, {bool bold = false, bool minus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: Brule.mono(12)),
          const Spacer(),
          Text('${minus ? '- ' : ''}${rupiah(v)}',
              style: bold ? Brule.condensed(22) : const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(code)),
      body: Loader<Order>(
        load: _load,
        builder: (context, o, reload) {
          // Struk baru keluar setelah roaster mengisi nomor resi (pesanan sudah dikirim).
          final canReceipt = o.status != 'cancelled' && (o.trackingNumber ?? '').isNotEmpty;
          final list = RefreshIndicator(
            color: Brule.amber,
            onRefresh: reload,
            child: Narrow(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(o.statusLabel, style: Brule.condensed(28))),
                      Tag(o.paymentMethod == 'cod' ? 'COD' : 'ONLINE'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(dateTime(o.createdAt), style: Brule.mono(11)),
                  const SizedBox(height: 16),
                  if (o.canPay) ...[
                    FilledButton(
                      onPressed: () => _pay(context, reload),
                      child: const Text('BAYAR SEKARANG'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => _sync(context, reload),
                      child: const Text('CEK STATUS PEMBAYARAN'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (o.status == 'cancelled') ...[
                    const ErrorBox('Pesanan ini dibatalkan.'),
                    const SizedBox(height: 16),
                  ] else ...[
                    const Label('TAHAP PESANAN'),
                    OrderTimeline(
                      keys: o.stepKeys,
                      labels: o.steps,
                      times: o.stepTimes,
                      step: o.step,
                      tracking: o.trackingNumber,
                      bestBefore: o.bestBefore == null ? null : fullDate(o.bestBefore),
                    ),
                  ],
                  const Label('ITEM'),
                  for (final it in o.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.name, style: Brule.condensed(17)),
                                if (it.detail.isNotEmpty)
                                  Text(
                                    it.isGear ? it.detail : '${it.detail} · ${it.grams} g',
                                    style: Brule.mono(10, color: Brule.amber),
                                  ),
                              ],
                            ),
                          ),
                          Text(rupiah(it.lineTotal)),
                        ],
                      ),
                    ),
                  const Divider(height: 28),
                  _money('Subtotal', o.subtotal),
                  _money('Ongkir', o.shipping),
                  if (o.addon > 0) _money('Kado & kartu', o.addon),
                  if (o.discount > 0)
                    _money(o.voucherCode == null ? 'Diskon' : 'Voucher ${o.voucherCode}',
                        o.discount,
                        minus: true),
                  const SizedBox(height: 4),
                  _money('TOTAL', o.total, bold: true),
                  const Label('PENERIMA'),
                  Text('${o.recipient['name'] ?? ''}'),
                  const SizedBox(height: 2),
                  Text('${o.recipient['phone'] ?? ''}', style: Brule.mono(12)),
                  const SizedBox(height: 6),
                  Text('${o.recipient['address'] ?? ''}',
                      style: TextStyle(color: Brule.kraft.withValues(alpha: 0.95), height: 1.4)),
                  if (o.giftWrap && o.cardMessage != null && o.cardMessage!.isNotEmpty) ...[
                    const Label('KARTU UCAPAN'),
                    Text(o.cardMessage!),
                  ],
                  if (o.canCancel) ...[
                    const SizedBox(height: 28),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Brule.red,
                        side: BorderSide(color: Brule.red.withValues(alpha: 0.6)),
                      ),
                      onPressed: () => _cancel(context, reload),
                      child: const Text('BATALKAN PESANAN'),
                    ),
                  ],
                ],
              ),
            ),
          );
          if (!canReceipt) return list;
          return Column(
            children: [
              Expanded(child: list),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(
                  color: Brule.sheet,
                  border: Border(top: BorderSide(color: Brule.hair(0.1))),
                ),
                child: SafeArea(
                  top: false,
                  child: Narrow(
                    child: OutlinedButton.icon(
                      onPressed: () => downloadAndShare(context, '/orders/$code/receipt', {}),
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: const Text('UNDUH STRUK (PDF)'),
                    ),
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
