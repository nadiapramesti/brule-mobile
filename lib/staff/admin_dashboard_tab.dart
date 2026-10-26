import 'package:flutter/material.dart';
import '../api.dart';
import '../motion.dart';
import '../notices.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'admin_kit.dart';

/// Ringkasan penjualan untuk admin: angka utama di atas, lalu grafik, antrian, dan peringkat.
class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  int _days = 14;
  int? _sel;

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
          final rev = (k['revenue'] ?? {}) as Map;

          return RefreshIndicator(
            color: Brule.amber,
            onRefresh: reload,
            child: Narrow(
              maxWidth: 720,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  Reveal(
                    child: Row(
                      children: [
                        Container(width: 18, height: 3, color: Brule.amber),
                        const SizedBox(width: 10),
                        Text('DASHBOARD', style: Brule.condensed(22, spacing: 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ChipPicker<int>(
                    items: const [7, 14, 30],
                    value: _days,
                    label: (v) => '$v HARI',
                    onChanged: (v) => setState(() {
                      _days = v;
                      _sel = null;
                    }),
                  ),
                  const SizedBox(height: 14),
                  Reveal(
                    index: 1,
                    child: _Hero(
                      days: _days,
                      revenue: asInt(rev['value']),
                      delta: rev['delta'],
                      daily: daily,
                      selected: _sel,
                      onSelect: (i) => setState(() => _sel = i == _sel ? null : i),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Reveal(
                    index: 2,
                    child: TileRow(
                      height: 92,
                      children: [
                        Stat('PESANAN\nDIBAYAR', '${asInt((k['orders'] ?? {})['value'])}',
                            foot: _dl((k['orders'] ?? {})['delta'])),
                        Stat('RATA-RATA\nPESANAN', _short(asInt((k['aov'] ?? {})['value']))),
                        Stat('PELANGGAN\nBARU', '${asInt((k['customers'] ?? {})['value'])}'),
                        Stat('BIJI\nTERJUAL', _kg(asInt(k['grams']))),
                      ],
                    ),
                  ),
                  const Label('PERLU PERHATIAN'),
                  Reveal(
                    index: 3,
                    child: TileRow(
                      children: [
                        Stat('BELUM\nBAYAR', '${asInt(att['unpaid'])}', warn: asInt(att['unpaid']) > 0),
                        Stat('ANTRIAN', '${asInt(att['queue'])}', onTap: () => Notices.goto.value = 'queue'),
                        Stat('SIAP\nKIRIM', '${asInt(att['to_ship'])}', onTap: () => Notices.goto.value = 'queue'),
                        Stat('STOK\nTIPIS', '${asInt(att['low'])}',
                            warn: asInt(att['low']) > 0, onTap: () => Notices.goto.value = 'stock'),
                      ],
                    ),
                  ),
                  const Label('STATUS PESANAN (SEMUA)'),
                  Reveal(index: 4, child: _StatusBox(statuses)),
                  const Label('KOPI TERLARIS'),
                  if (top.isEmpty)
                    Text('Belum ada penjualan di periode ini.', style: Brule.mono(10))
                  else
                    Reveal(index: 5, child: _TopBox(top)),
                  if (low.isNotEmpty) ...[
                    const Label('STOK BIJI MENIPIS'),
                    Reveal(
                      index: 6,
                      child: _Box([
                        for (final (i, c) in low.indexed)
                          Padding(
                            padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 16, color: Brule.amber),
                                const SizedBox(width: 10),
                                Expanded(child: Text('${c['name']}')),
                                Text('${c['grams']} g', style: Brule.mono(11, color: Brule.amber)),
                              ],
                            ),
                          ),
                      ]),
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

/// Rp 1.250.000 -> "1,3 jt" supaya muat di kotak kecil.
String _short(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1).replaceAll('.', ',')} jt';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)} rb';
  return '$v';
}

String _kg(int g) => g >= 1000 ? '${(g / 1000).toStringAsFixed(1).replaceAll('.', ',')} kg' : '$g g';

String? _dl(dynamic d) {
  if (d is! num) return null;
  return '${d >= 0 ? '▲' : '▼'} ${d.abs().toStringAsFixed(0)}%';
}

/// Kartu utama: pendapatan periode + grafik batang yang bisa disentuh per hari.
class _Hero extends StatelessWidget {
  final int days;
  final int revenue;
  final dynamic delta;
  final List<Map<String, dynamic>> daily;
  final int? selected;
  final ValueChanged<int> onSelect;
  const _Hero({
    required this.days,
    required this.revenue,
    required this.delta,
    required this.daily,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final values = [for (final e in daily) asInt(e['total'])];
    final maxV = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final hot = selected ?? (maxV == 0 ? null : values.indexOf(maxV));
    final dv = delta is num ? (delta as num).toDouble() : null;

    final String caption;
    if (hot == null || hot >= daily.length) {
      caption = 'Belum ada penjualan';
    } else {
      final lead = selected == null ? 'Tertinggi' : 'Dipilih';
      caption = '$lead · ${dayMonth('${daily[hot]['date']}')} · ${rupiah(values[hot])}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Brule.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Brule.hair(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('PENDAPATAN · $days HARI', style: Brule.mono(9.5)),
              const Spacer(),
              if (dv != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (dv >= 0 ? Brule.blueText : Brule.red).withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    '${dv >= 0 ? '▲' : '▼'} ${dv.abs().toStringAsFixed(0)}%',
                    style: Brule.mono(9.5, color: dv >= 0 ? Brule.blueText : Brule.red),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(rupiah(revenue), style: Brule.condensed(36)),
          ),
          if (dv != null) Text('dibanding periode sebelumnya', style: Brule.mono(9)),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: LayoutBuilder(
              builder: (context, c) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (t) {
                  if (values.isEmpty) return;
                  final i = (t.localPosition.dx / c.maxWidth * values.length).floor().clamp(0, values.length - 1);
                  onSelect(i);
                },
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(values.length),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1100),
                  builder: (context, t, _) => CustomPaint(
                    size: Size.infinite,
                    painter: _BarPainter(values, hot, t),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(daily.isEmpty ? '' : dayMonth('${daily.first['date']}'), style: Brule.mono(9)),
              Text(daily.isEmpty ? '' : dayMonth('${daily.last['date']}'), style: Brule.mono(9)),
            ],
          ),
          const Divider(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Row(
              key: ValueKey(caption),
              children: [
                Icon(selected == null ? Icons.trending_up : Icons.touch_app_outlined, size: 16, color: Brule.amber),
                const SizedBox(width: 8),
                Expanded(child: Text(caption, style: Brule.mono(10.5, color: Brule.cream))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Status pesanan sebagai batang proporsional, bukan daftar polos.
class _StatusBox extends StatelessWidget {
  final List<Map<String, dynamic>> statuses;
  const _StatusBox(this.statuses);

  @override
  Widget build(BuildContext context) {
    final maxN = statuses.fold<int>(1, (m, s) => asInt(s['n']) > m ? asInt(s['n']) : m);
    return _Box([
      for (final (i, s) in statuses.indexed)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('${s['label']}')),
                  Text('${asInt(s['n'])}',
                      style: Brule.condensed(17, color: statusColor('${s['status']}'))),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: asInt(s['n']) / maxN),
                  duration: Duration(milliseconds: 700 + i * 60),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 4,
                    backgroundColor: Brule.hair(0.07),
                    color: statusColor('${s['status']}'),
                  ),
                ),
              ),
            ],
          ),
        ),
    ]);
  }
}

/// Peringkat kopi terlaris dengan batang tipis menurut omzet.
class _TopBox extends StatelessWidget {
  final List<Map<String, dynamic>> top;
  const _TopBox(this.top);

  @override
  Widget build(BuildContext context) {
    final maxR = top.fold<int>(1, (m, e) => asInt(e['revenue']) > m ? asInt(e['revenue']) : m);
    return _Box([
      for (final (i, e) in top.indexed)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: (i == 0 ? Brule.amber : Brule.kraft).withValues(alpha: 0.6)),
                    ),
                    child: Text('${i + 1}', style: Brule.mono(10, color: i == 0 ? Brule.amber : Brule.kraft)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${e['name']}', maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text(rupiah(asInt(e['revenue'])), style: Brule.condensed(16)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 6, 0, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: asInt(e['revenue']) / maxR),
                          duration: Duration(milliseconds: 700 + i * 80),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 3,
                            backgroundColor: Brule.hair(0.07),
                            color: i == 0 ? Brule.amber : Brule.blue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${e['grams']} g', style: Brule.mono(9.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
    ]);
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
          border: Border.all(color: Brule.hair(0.1)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );
}

class _BarPainter extends CustomPainter {
  final List<int> values;
  final int? hot;
  final double t;
  _BarPainter(this.values, this.hot, [this.t = 1]);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    const gap = 4.0;
    final bw = (size.width - gap * (values.length - 1)) / values.length;
    final base = Paint()..color = Brule.hair(0.06);
    final bar = Paint()..color = Brule.blue;
    final accent = Paint()..color = Brule.amber;

    for (var i = 0; i < values.length; i++) {
      final x = i * (bw + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, 0, bw, size.height), const Radius.circular(3)),
        base,
      );
      if (maxV == 0 || values[i] == 0) {
        // hari tanpa penjualan tetap diberi garis tipis supaya kelihatan "nol", bukan rusak
        canvas.drawRect(Rect.fromLTWH(x, size.height - 2, bw, 2), Paint()..color = Brule.hair(0.12));
        continue;
      }
      final local = ((t * 1.6) - i / values.length * 0.6).clamp(0.0, 1.0);
      final h = (size.height * values[i] / maxV * Curves.easeOutCubic.transform(local)).clamp(3.0, size.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, bw, h), const Radius.circular(3)),
        i == hot ? accent : bar,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => old.values != values || old.hot != hot || old.t != t;
}
