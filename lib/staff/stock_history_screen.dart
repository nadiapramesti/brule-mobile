import 'package:flutter/material.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'admin_kit.dart';

/// Riwayat stok biji: setiap barang masuk dan keluar beserta saldo, pelaku, dan alasannya.
class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  String _type = '';
  int _coffee = 0;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Riwayat stok',
      child: PagedList(
        key: ValueKey('$_type|$_coffee'),
        path: '/admin/stock/history',
        params: {'jenis': _type, if (_coffee > 0) 'kopi': '$_coffee'},
        empty: 'Belum ada pergerakan stok.',
        header: (meta) {
          final types = ((meta?['types'] ?? []) as List).cast<Map<String, dynamic>>();
          final coffees = ((meta?['coffees'] ?? []) as List).cast<Map<String, dynamic>>();
          final tl = {'': 'Semua jenis', for (final t in types) '${t['key']}': '${t['label']}'};
          final cl = {0: 'Semua kopi', for (final c in coffees) asInt(c['id']): '${c['name']}'};
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChipPicker<String>(
                items: tl.keys.toList(),
                value: _type,
                label: (k) => tl[k]!,
                onChanged: (k) => setState(() => _type = k),
              ),
              const SizedBox(height: 8),
              ChipPicker<int>(
                items: cl.keys.toList(),
                value: _coffee,
                label: (k) => cl[k]!,
                onChanged: (k) => setState(() => _coffee = k),
              ),
            ],
          );
        },
        item: (context, m, refresh) {
          final g = asInt(m['grams']);
          final inbound = g >= 0;
          final color = inbound ? Brule.blueText : Brule.amber;
          return Panel(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(inbound ? Icons.south_west : Icons.north_east, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${m['coffee']}', style: Brule.condensed(17)),
                      const SizedBox(height: 2),
                      Text(
                        [
                          '${m['type_label']}',
                          if (m['order_code'] != null) '${m['order_code']}',
                          if ('${m['reason'] ?? ''}'.isNotEmpty) '${m['reason']}',
                        ].join(' · '),
                        style: Brule.mono(9.5),
                      ),
                      const SizedBox(height: 2),
                      Text('${m['by'] ?? 'Sistem'} · ${dateTime('${m['created_at']}')}', style: Brule.mono(9)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${inbound ? '+' : ''}${gram(g)}', style: Brule.condensed(17, color: color)),
                    const SizedBox(height: 2),
                    Text('saldo ${gram(asInt(m['balance_after']))}', style: Brule.mono(9)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
