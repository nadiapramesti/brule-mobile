import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

/// Ringkasan penjualan untuk admin.
class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  int _days = 14;

  Future<Map<String, dynamic>> _load() => Api.get('/admin/dashboard', {'days': '$_days'});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Loader<Map<String, dynamic>>(
        key: ValueKey(_days),
        load: _load,
        builder: (context, d, reload) {
          final k = (d['kpis'] ?? {}) as Map;
          final att = (d['attention'] ?? {}) as Map;
          final daily = ((d['daily'] ?? []) as List).cast<Map<String, dynamic>>();
          final statuses = ((d['statuses'] ?? []) as List).cast<Map<String, dynamic>>();
          final top = ((d['top_coffees'] ?? []) as List).cast<Map<String, dynamic>>();
          final low = ((d['low_stock'] ?? []) as List).cast<Map<String, dynamic>>();

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
                      Text('DASHBOARD', style: Brule.condensed(22, spacing: 2)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ChipPicker<int>(
                    items: const [7, 14, 30],
                    value: _days,
                    label: (v) => '$v HARI',
                    onChanged: (v) => setState(() => _days = v),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Kpi('PENDAPATAN', rupiah(asInt((k['revenue'] ?? {})['value'])),
                          delta: (k['revenue'] ?? {})['delta']),
                      _Kpi('PESANAN DIBAYAR', '${asInt((k['orders'] ?? {})['value'])}',
                          delta: (k['orders'] ?? {})['delta']),
                      _Kpi('RATA-RATA PESANAN', rupiah(asInt((k['aov'] ?? {})['value']))),
                      _Kpi('PELANGGAN BARU', '${asInt((k['customers'] ?? {})['value'])}'),
                      _Kpi('BIJI TERJUAL', '${asInt(k['grams'])} g'),
                    ],
                  ),
                  const Label('PERLU PERHATIAN'),
                  Row(
                    children: [
                      _Att('BELUM BAYAR', asInt(att['unpaid'])),
                      _Att('ANTRIAN', asInt(att['queue'])),
                      _Att('SIAP KIRIM', asInt(att['to_ship'])),
                      _Att('STOK TIPIS', asInt(att['low']), warn: true),
                    ],
                  ),
                  const Label('PENDAPATAN HARIAN'),
                  Container(
                    height: 150,
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                    decoration: BoxDecoration(
                      color: Brule.field,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _BarPainter([for (final e in daily) asInt(e['total'])]),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(daily.isEmpty ? '' : dayMonth('${daily.first['date']}'),
                                style: Brule.mono(9)),
                            Text(daily.isEmpty ? '' : dayMonth('${daily.last['date']}'),
                                style: Brule.mono(9)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Label('STATUS PESANAN (SEMUA)'),
                  _Box([
                    for (final s in statuses)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text('${s['label']}')),
                            Tag('${s['n']}', color: statusColor('${s['status']}')),
                          ],
                        ),
                      ),
                  ]),
                  const Label('KOPI TERLARIS'),
                  if (top.isEmpty)
                    Text('Belum ada penjualan di periode ini.', style: Brule.mono(10))
                  else
                    _Box([
                      for (var i = 0; i < top.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Text('${i + 1}', style: Brule.mono(11, color: Brule.amber)),
                              const SizedBox(width: 12),
                              Expanded(child: Text('${top[i]['name']}')),
                              Text('${top[i]['grams']} g', style: Brule.mono(10)),
                              const SizedBox(width: 10),
                              Text(rupiah(asInt(top[i]['revenue']))),
                            ],
                          ),
                        ),
                    ]),
                  if (low.isNotEmpty) ...[
                    const Label('STOK BIJI MENIPIS'),
                    _Box([
                      for (final c in low)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(child: Text('${c['name']}')),
                              Text('${c['grams']} g', style: Brule.mono(11, color: Brule.amber)),
                            ],
                          ),
                        ),
                    ]),
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

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final dynamic delta;
  const _Kpi(this.label, this.value, {this.delta});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.sizeOf(context).width.clamp(0.0, 720.0).toDouble() - 42) / 2;
    final dv = delta is num ? (delta as num).toDouble() : null;
    return Container(
      width: w,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Brule.field,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Brule.mono(9.5)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: Brule.condensed(24)),
          ),
          const SizedBox(height: 4),
          if (dv != null)
            Text(
              '${dv >= 0 ? '▲' : '▼'} ${dv.abs().toStringAsFixed(0)}% vs periode lalu',
              style: Brule.mono(9, color: dv >= 0 ? Brule.blueText : Brule.red),
            )
          else
            Text(' ', style: Brule.mono(9)),
        ],
      ),
    );
  }
}

class _Att extends StatelessWidget {
  final String label;
  final int n;
  final bool warn;
  const _Att(this.label, this.n, {this.warn = false});

  @override
  Widget build(BuildContext context) {
    final hot = warn && n > 0;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Brule.field,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: hot ? Brule.amber.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text('$n', style: Brule.condensed(22, color: hot ? Brule.amber : Brule.cream)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: Brule.mono(8)),
          ],
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final List<Widget> children;
  const _Box(this.children);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Brule.field,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );
}

class _BarPainter extends CustomPainter {
  final List<int> values;
  _BarPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final gap = 4.0;
    final bw = (size.width - gap * (values.length - 1)) / values.length;
    final base = Paint()..color = Colors.white.withValues(alpha: 0.06);
    final bar = Paint()..color = Brule.blue;
    final hot = Paint()..color = Brule.amber;

    for (var i = 0; i < values.length; i++) {
      final x = i * (bw + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, 0, bw, size.height), const Radius.circular(2)),
        base,
      );
      if (maxV == 0 || values[i] == 0) continue;
      final h = size.height * values[i] / maxV;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, size.height - h, bw, h), const Radius.circular(2)),
        values[i] == maxV ? hot : bar,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => old.values != values;
}
