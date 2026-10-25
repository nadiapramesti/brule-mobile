import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'admin_kit.dart';

const _kPresets = {
  '7d': '7 hari',
  '30d': '30 hari',
  '90d': '90 hari',
  'month': 'Bulan ini',
  'lastmonth': 'Bulan lalu',
};

/// Laporan penjualan seperti halaman Laporan di web: omzet, pembanding periode lalu, dan rincian.
class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  String _preset = '30d';

  List<Map<String, dynamic>> _list(dynamic v) => ((v ?? []) as List).cast<Map<String, dynamic>>();

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Laporan',
      child: Loader<Map<String, dynamic>>(
        key: ValueKey(_preset),
        load: () => Api.get('/admin/reports', {'preset': _preset}),
        builder: (context, d, reload) {
          final s = (d['summary'] ?? {}) as Map;
          final dl = (d['delta'] ?? {}) as Map;
          final series = _list(d['series']);
          final coffee = _list(d['by_coffee']);
          final level = _list(d['by_level']);
          final product = _list(d['by_product']);
          final voucher = _list(d['by_voucher']);
          final maxV = series.fold<int>(1, (m, e) => asInt(e['total']) > m ? asInt(e['total']) : m);

          return RefreshIndicator(
            color: Brule.amber,
            onRefresh: reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                ChipPicker<String>(
                  items: _kPresets.keys.toList(),
                  value: _preset,
                  label: (k) => _kPresets[k]!,
                  onChanged: (k) => setState(() => _preset = k),
                ),
                const SizedBox(height: 6),
                Text('${dayMonth('${d['from']}')} – ${dayMonth('${d['to']}')}', style: Brule.mono(10)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Kpi('OMZET', rupiah(asInt(s['revenue'])), dl['revenue']),
                    _Kpi('PESANAN', '${asInt(s['orders'])}', dl['orders']),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Kpi('RATA-RATA / PESANAN', rupiah(asInt(s['aov'])), dl['aov']),
                    _Kpi('KOPI TERJUAL', '${(asInt(s['grams']) / 1000).toStringAsFixed(1)} kg', null),
                  ],
                ),
                const Label('RINCIAN OMZET'),
                Panel(
                  child: Column(
                    children: [
                      _Row('Barang', rupiah(asInt(s['goods']))),
                      _Row('Ongkir', rupiah(asInt(s['shipping']))),
                      _Row('Add-on', rupiah(asInt(s['addons']))),
                      _Row('Diskon', '− ${rupiah(asInt(s['discount']))}'),
                    ],
                  ),
                ),
                const Label('OMZET PER HARI'),
                Panel(
                  child: SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final e in series)
                          Expanded(
                            child: Tooltip(
                              message: '${e['label']}: ${rupiah(asInt(e['total']))}',
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 0.6),
                                height: 2 + 116 * asInt(e['total']) / maxV,
                                decoration: BoxDecoration(
                                  color: asInt(e['total']) == 0
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Brule.amber,
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (coffee.isNotEmpty) ...[
                  const Label('KOPI TERLARIS'),
                  for (final c in coffee)
                    Panel(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${c['name']}', style: Brule.condensed(17)),
                                Text('${c['orders']} pesanan · ${(asInt(c['grams']) / 1000).toStringAsFixed(2)} kg',
                                    style: Brule.mono(9.5)),
                              ],
                            ),
                          ),
                          Text(rupiah(asInt(c['revenue'])), style: Brule.condensed(18)),
                        ],
                      ),
                    ),
                ],
                if (level.isNotEmpty) ...[
                  const Label('PER TINGKAT SANGRAI'),
                  Panel(
                    child: Column(
                      children: [
                        for (final l in level)
                          _Row('${l['level']} · ${(asInt(l['grams']) / 1000).toStringAsFixed(2)} kg',
                              rupiah(asInt(l['revenue']))),
                      ],
                    ),
                  ),
                ],
                if (product.isNotEmpty) ...[
                  const Label('PERLENGKAPAN'),
                  Panel(
                    child: Column(
                      children: [
                        for (final p in product)
                          _Row('${p['name']} · ${p['units']} unit', rupiah(asInt(p['revenue']))),
                      ],
                    ),
                  ),
                ],
                if (voucher.isNotEmpty) ...[
                  const Label('PEMAKAIAN VOUCHER'),
                  Panel(
                    child: Column(
                      children: [
                        for (final v in voucher)
                          _Row('${v['code']} · ${v['uses']}x', '− ${rupiah(asInt(v['discount']))}'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final dynamic delta;
  const _Kpi(this.label, this.value, this.delta);

  @override
  Widget build(BuildContext context) {
    final dv = delta is num ? (delta as num).toInt() : null;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Brule.field,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Brule.mono(8.5)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: Brule.condensed(22)),
            ),
            const SizedBox(height: 4),
            if (dv != null)
              Text('${dv >= 0 ? '▲' : '▼'} ${dv.abs()}% vs periode lalu',
                  style: Brule.mono(9, color: dv >= 0 ? Brule.blueText : Brule.red)),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String a;
  final String b;
  const _Row(this.a, this.b);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(a, style: Brule.mono(11))),
            Text(b, style: Brule.mono(11, color: Brule.cream)),
          ],
        ),
      );
}
