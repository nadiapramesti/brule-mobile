import 'package:flutter/material.dart';
import '../motion.dart';
import '../api.dart';
import '../cart.dart';
import '../models.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import '../auth_gate.dart';
import '../staff/admin_kit.dart' show GroupTitle;
import 'order_detail_screen.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  Future<List<Order>> _load() async {
    final res = await Api.get('/orders');
    return (res['data'] as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(width: 18, height: 3, color: Brule.amber),
                const SizedBox(width: 10),
                Text('PESANAN', style: Brule.condensed(22, spacing: 2)),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: Api.session,
              builder: (context, _, _) => !Api.loggedIn
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 56, color: Brule.kraft.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            const Text('Masuk untuk melihat pesananmu.'),
                            const SizedBox(height: 4),
                            Text('Status sangrai sampai kirim bisa dipantau di sini.',
                                textAlign: TextAlign.center, style: Brule.mono(11)),
                            const SizedBox(height: 20),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size(180, 48)),
                              onPressed: () => requireLogin(context,
                                  reason: 'Masuk untuk melihat pesananmu.'),
                              child: const Text('MASUK'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _list(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list() => ValueListenableBuilder<int>(
              valueListenable: AppEvents.ordersChanged,
              builder: (context, version, _) {
                return Loader<List<Order>>(
                  key: ValueKey(version),
                  load: _load,
                  builder: (context, list, reload) {
                    return RefreshIndicator(
                      color: Brule.amber,
                      onRefresh: reload,
                      child: list.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(child: Text('Belum ada pesanan.')),
                                ),
                              ],
                            )
                          : Narrow(
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                                itemCount: list.length,
                                itemBuilder: (context, i) {
                                  final g = dayTitleOf(list[i].createdAt);
                                  final head = i == 0 || dayTitleOf(list[i - 1].createdAt) != g;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (head) GroupTitle(g, first: i == 0),
                                      Reveal(index: i, child: _OrderCard(order: list[i])),
                                    ],
                                  );
                                },
                              ),
                            ),
                    );
                  },
                );
              },
            );
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final first = order.items.isEmpty ? '' : order.items.first.name;
    final more = order.items.length > 1 ? ' +${order.items.length - 1} lainnya' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Brule.field,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderDetailScreen(code: order.code)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(order.code, style: Brule.mono(12, color: Brule.cream))),
                    Tag(order.statusLabel.toUpperCase(), color: statusColor(order.status)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('$first$more', style: Brule.condensed(17)),
                const SizedBox(height: 4),
                Text(dateTime(order.createdAt), style: Brule.mono(10)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(order.paymentMethod == 'cod' ? 'COD' : 'ONLINE',
                        style: Brule.mono(10)),
                    const Spacer(),
                    Text(rupiah(order.total), style: Brule.condensed(20)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
