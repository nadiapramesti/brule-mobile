import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import '../theme.dart';
import '../util.dart';
import 'admin_kit.dart';

/// Riwayat stok biji: barang masuk dan keluar dikelompokkan per hari, satu baris ringkas per kejadian.
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
        groupBy: dayGroup,
        header: (meta) {
          final types = ((meta?['types'] ?? []) as List).cast<Map<String, dynamic>>();
          final coffees = ((meta?['coffees'] ?? []) as List).cast<Map<String, dynamic>>();
          final tl = <String, String>{'': 'Semua jenis', for (final t in types) '${t['key']}': '${t['label']}'};
          final cl = <int, String>{0: 'Semua kopi', for (final c in coffees) asInt(c['id']): '${c['name']}'};
          return Row(
            children: [
              Expanded(
                child: PickField<String>(
                  label: 'JENIS',
                  options: tl,
                  value: tl.containsKey(_type) ? _type : '',
                  all: '',
                  onChanged: (k) => setState(() => _type = k),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PickField<int>(
                  label: 'KOPI',
                  options: cl,
                  value: cl.containsKey(_coffee) ? _coffee : 0,
                  all: 0,
                  onChanged: (k) => setState(() => _coffee = k),
                ),
              ),
            ],
          );
        },
        item: (context, m, refresh) {
          final g = asInt(m['grams']);
          final inbound = g >= 0;
          final color = inbound ? Brule.blueText : Brule.amber;
          final label = '${m['type_label']}';
          final reason = '${m['reason'] ?? ''}';
          final note = [
            label,
            if (m['order_code'] != null) '${m['order_code']}',
            if (reason.isNotEmpty && reason.toLowerCase() != label.toLowerCase()) reason,
          ].join(' · ');
          return Panel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(inbound ? Icons.south_west : Icons.north_east, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${m['coffee']}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: Brule.condensed(16)),
                      const SizedBox(height: 2),
                      Text(note, maxLines: 1, overflow: TextOverflow.ellipsis, style: Brule.mono(9.5)),
                      const SizedBox(height: 1),
                      Text('${m['by'] ?? 'Sistem'} · ${clockOf(m['created_at'])}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: Brule.mono(9)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${inbound ? '+' : ''}${gram(g)}', style: Brule.condensed(16, color: color)),
                    const SizedBox(height: 2),
                    Text(gram(asInt(m['balance_after'])), style: Brule.mono(9)),
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
