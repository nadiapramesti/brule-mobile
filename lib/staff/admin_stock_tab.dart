import 'package:flutter/material.dart';
import '../api.dart';
import '../motion.dart';
import '../theme.dart';
import '../util.dart';
import 'admin_kit.dart';
import '../widgets.dart';
import 'stock_history_screen.dart';
import 'stock_sheets.dart';

/// Stok biji mentah dan perlengkapan untuk admin.
class AdminStockTab extends StatefulWidget {
  final String path;
  final bool products;
  final bool manage; // admin: tambah/kurangi stok dan lihat riwayat
  const AdminStockTab({super.key, this.path = '/admin/stock', this.products = true, this.manage = true});

  @override
  State<AdminStockTab> createState() => _AdminStockTabState();
}

class _AdminStockTabState extends State<AdminStockTab> {
  String _q = '';
  bool _low = false;
  int _v = 0;

  Future<void> _after(Future<bool> f, String done) async {
    if (await f && mounted) {
      setState(() => _v++);
      toast(context, done);
    }
  }

  Color _state(String s) => s == 'soldout'
      ? Brule.red
      : s == 'low'
          ? Brule.amber
          : Brule.blueText;

  String _stateLabel(String s) => s == 'soldout' ? 'HABIS' : (s == 'low' ? 'MENIPIS' : 'AMAN');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Loader<Map<String, dynamic>>(
        key: ValueKey(_v),
        load: () => Api.get(widget.path),
        builder: (context, d, reload) {
          final sum = (d['summary'] ?? {}) as Map;
          final max = asInt(sum['max']) == 0 ? 1 : asInt(sum['max']);
          final allCoffees = ((d['coffees'] ?? []) as List).cast<Map<String, dynamic>>();
          final q = _q.toLowerCase();
          final coffees = allCoffees.where((c) {
            if (_low && '${c['state']}' == 'ok') return false;
            if (q.isEmpty) return true;
            return '${c['name']} ${c['process'] ?? ''} ${c['region'] ?? ''}'.toLowerCase().contains(q);
          }).toList();
          final products = ((d['products'] ?? []) as List).cast<Map<String, dynamic>>();

          return RefreshIndicator(
            color: Brule.amber,
            onRefresh: reload,
            child: Narrow(
              maxWidth: 720,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Row(
                    children: [
                      Container(width: 18, height: 3, color: Brule.amber),
                      const SizedBox(width: 10),
                      Text('STOK', style: Brule.condensed(22, spacing: 2)),
                      const Spacer(),
                      if (widget.manage)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const StockHistoryScreen())),
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('RIWAYAT'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TileRow(
                    children: [
                      _sum('BIJI AKTIF', '${sum['total'] ?? 0}'),
                      _sum('TOTAL', '${sum['kg'] ?? 0} kg'),
                      _sum('MENIPIS', '${sum['low'] ?? 0}', warn: asInt(sum['low']) > 0),
                      _sum('HABIS', '${sum['soldout'] ?? 0}', warn: asInt(sum['soldout']) > 0),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SearchBox(
                    hint: 'cari biji, contoh: Natural',
                    onChanged: (v) => setState(() => _q = v.trim()),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilterChip(
                      label: const Text('HANYA MENIPIS / HABIS'),
                      selected: _low,
                      onSelected: (v) => setState(() => _low = v),
                    ),
                  ),
                  const Label('BIJI MENTAH (STOK TERENDAH DI ATAS)'),
                  if (coffees.isEmpty) Text('Tidak ada biji yang cocok.', style: Brule.mono(10)),
                  for (final (i, c) in coffees.indexed)
                    Reveal(
                      index: i,
                      child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Brule.field,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Brule.hair(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text('${c['name']}', style: Brule.condensed(17))),
                              Tag(_stateLabel('${c['state']}'), color: _state('${c['state']}')),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (c['process'] != null) '${c['process']}',
                              if (c['region'] != null) '${c['region']}',
                            ].join(' · '),
                            style: Brule.mono(9.5),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: (asInt(c['grams']) / max).clamp(0.0, 1.0).toDouble()),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) => LinearProgressIndicator(
                                value: v,
                                minHeight: 6,
                                color: _state('${c['state']}'),
                                backgroundColor: Brule.hair(0.08),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(gram(asInt(c['grams'])), style: Brule.mono(11, color: Brule.cream)),
                              const Spacer(),
                              if (c['days_left'] != null)
                                Text(
                                  asInt(c['days_left']) > 365
                                      ? 'cukup > 1 tahun'
                                      : '≈ ${c['days_left']} hari lagi',
                                  style: Brule.mono(9.5),
                                ),
                            ],
                          ),
                          if (widget.manage) ...[
                            const SizedBox(height: 10),
                            MenuButton(
                              label: 'ATUR STOK',
                              actions: [
                                MenuAction('Stok masuk', 'Tambah biji dari pembelian atau panen', Icons.add_circle_outline,
                                    () => _after(showCoffeeStockSheet(context, c), 'Stok ${c['name']} diperbarui')),
                                MenuAction('Stok keluar', 'Catat biji rusak, sampel, atau terbuang', Icons.remove_circle_outline,
                                    () => _after(showCoffeeStockSheet(context, c, mode: 'waste'), 'Stok ${c['name']} diperbarui')),
                                MenuAction('Hitung ulang', 'Samakan stok dengan hasil timbang', Icons.fact_check_outlined,
                                    () => _after(showCoffeeStockSheet(context, c, mode: 'count'), 'Stok ${c['name']} dikoreksi')),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    ),
                  if (widget.products && products.isNotEmpty) ...[
                    const Label('PERLENGKAPAN'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Brule.field,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Brule.hair(0.1)),
                      ),
                      child: Column(
                        children: [
                          for (final p in products)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${p['name']}'),
                                        Text('${p['category']}'.toUpperCase(),
                                            style: Brule.mono(9)),
                                      ],
                                    ),
                                  ),
                                  Tag(
                                    asInt(p['stock']) == 0 ? 'HABIS' : '${p['stock']} PCS',
                                    color: asInt(p['stock']) == 0
                                        ? Brule.red
                                        : (asInt(p['stock']) < 5 ? Brule.amber : Brule.blueText),
                                  ),
                                  if (widget.manage)
                                    IconButton.filledTonal(
                                      tooltip: 'Tambah stok',
                                      onPressed: () =>
                                          _after(showProductStockSheet(context, p), 'Stok ${p['name']} ditambah'),
                                      icon: const Icon(Icons.add, size: 18),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _sum(String label, String value, {bool warn = false}) => Stat(label, value, warn: warn);
