import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'i18n.dart' show tr;

const _gold = Color(0xFFD9B26F);
const _goldHi = Color(0xFFF8E7BC);
const _goldLo = Color(0xFF9C7430);
const _ink = Color(0xFF121212); // sama dengan splash bawaan Android, supaya sambungannya mulus

/// Total durasi intro (detik). Sengaja pelan supaya geraknya terasa mewah, bukan kilat.
const _total = 5.6;

/// Puncak kurva sangrai: posisi (0..1), tinggi (0..1), lebar, dan label aroma.
/// Urutan dan tinggi mengikuti kromatogram di beranda.
const _peaks = <(double, double, double, String)>[
  (0.10, 0.30, 0.014, 'Segar'),
  (0.235, 0.72, 0.016, 'Jeruk'),
  (0.36, 0.42, 0.014, 'Beri'),
  (0.485, 0.62, 0.015, 'Melati'),
  (0.625, 0.98, 0.018, 'Kakao'),
  (0.75, 0.52, 0.014, 'Kacang'),
  (0.91, 0.36, 0.015, 'Cengkeh'),
];

const _phases = <String>[
  'MEMANASKAN DRUM SANGRAI',
  'MEMBACA KURVA SANGRAI',
  'MENGGILING BIJI',
  'MENYIAPKAN DASHBOARD',
];

double _curve(double x) {
  var y = 0.035 + 0.02 * math.sin(x * 21) * math.sin(x * 5.3 + 1);
  for (final (at, h, s, _) in _peaks) {
    final d = (x - at) / s;
    y += h * math.exp(-0.5 * d * d);
  }
  return y;
}

/// Intro pembuka: kurva sangrai emas tergambar pelan, uap emas naik, labu BRÛLÉ berkilau,
/// lalu bilah muat dengan status singkat sebelum masuk ke dashboard.
/// Tampil sekali tiap aplikasi dibuka dari nol, di atas layar utama yang sudah mulai dimuat.
class SplashGate extends StatefulWidget {
  final Widget child;
  const SplashGate({super.key, required this.child});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  static bool _played = false;
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 5600));
  bool _done = _played;
  bool _started = false;
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || _done) return;
    _started = true;
    // Pengguna yang mematikan animasi di HP: cukup kilas singkat (hanya fase memudar).
    if (MediaQuery.of(context).disableAnimations) {
      _reduce = true;
      _c.duration = const Duration(milliseconds: 350);
    }
    _c.forward().whenComplete(() {
      _played = true;
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _splash() {
    final t = _reduce ? 5.0 + _c.value * 0.6 : _c.value * _total;
    double iv(double a, double b, [Curve curve = Curves.easeOutCubic]) =>
        curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

    final logoIn = iv(0.35, 1.55);
    final sweep = -0.5 + 2.0 * iv(0.7, 2.3, Curves.easeInOut);
    final line = iv(1.4, 2.2);
    final dot = iv(1.5, 2.1);
    final word = iv(1.6, 2.7);
    final tag = iv(2.3, 3.2);
    final spacing = 14 - 6 * word;
    final fade = 1 - iv(5.0, 5.6, Curves.easeIn);
    final drift = 1 + 0.03 * (t / _total); // zoom sangat pelan sepanjang intro, kesan sinematik
    const markH = 104.0;

    return Opacity(
      opacity: fade,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Transform.scale(
          scale: 1 + 0.03 * (1 - fade),
          child: Container(
            color: _ink,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _BrewPainter(t))),
                Align(
                  alignment: const Alignment(0, -0.28),
                  child: Transform.scale(
                    scale: drift,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: logoIn,
                          child: Transform.scale(
                            scale: 0.93 + 0.07 * logoIn,
                            child: ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (r) => LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: const [Colors.white, Colors.white, _goldHi, _gold, Colors.white, Colors.white],
                                stops: [
                                  0,
                                  (sweep - 0.28).clamp(0.0, 1.0),
                                  (sweep - 0.08).clamp(0.0, 1.0),
                                  sweep.clamp(0.0, 1.0),
                                  (sweep + 0.14).clamp(0.0, 1.0),
                                  1,
                                ],
                              ).createShader(r),
                              child: Image.asset('assets/images/logo_mark.png',
                                  height: markH, color: Colors.white, filterQuality: FilterQuality.medium),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56 * line,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_gold.withValues(alpha: 0), _gold]),
                              ),
                            ),
                            Opacity(
                              opacity: dot,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Transform.rotate(
                                  angle: 0.785398,
                                  child: Container(width: 5, height: 5, color: _gold),
                                ),
                              ),
                            ),
                            Container(
                              width: 56 * line,
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_gold, _gold.withValues(alpha: 0)]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Opacity(
                          opacity: word,
                          child: Transform.translate(
                            offset: Offset(0, 8 * (1 - word)),
                            child: Padding(
                              padding: EdgeInsets.only(left: spacing),
                              child: Text(
                                'BRÛLÉ',
                                style: TextStyle(
                                  fontFamily: 'IBMPlexSans',
                                  fontSize: 30,
                                  letterSpacing: spacing,
                                  color: Colors.white,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Opacity(
                          opacity: tag,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              'SPECIALTY COFFEE LAB',
                              style: TextStyle(
                                fontFamily: 'IBMPlexMono',
                                fontSize: 10,
                                letterSpacing: 4,
                                color: Color.lerp(_goldLo, _gold, 0.6),
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        Positioned.fill(
          child: AbsorbPointer(
            child: AnimatedBuilder(animation: _c, builder: (_, _) => _splash()),
          ),
        ),
      ],
    );
  }
}

/// Latar bergerak: cahaya hangat bernapas, uap emas naik, kurva sangrai tergambar,
/// label aroma, status, dan bilah muat. Semua digambar dengan kode, tanpa aset tambahan.
class _BrewPainter extends CustomPainter {
  final double t;
  _BrewPainter(this.t);

  static final List<_Mote> _motes = () {
    final r = math.Random(11);
    return List.generate(
      28,
      (_) => _Mote(
        x: r.nextDouble(),
        speed: 0.035 + r.nextDouble() * 0.04,
        size: 0.9 + r.nextDouble() * 1.4,
        phase: r.nextDouble(),
        sway: 6 + r.nextDouble() * 10,
      ),
    );
  }();

  double _iv(double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  void _text(Canvas c, String s, Offset at, TextStyle style, {TextAlign align = TextAlign.center}) {
    final tp = TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();
    final dx = align == TextAlign.center ? -tp.width / 2 : (align == TextAlign.right ? -tp.width : 0.0);
    tp.paint(c, at + Offset(dx, -tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cahaya hangat yang pelan-pelan bernapas.
    final glowIn = _iv(0, 1.4);
    final glow = 0.20 * glowIn * (0.85 + 0.15 * math.sin(t * 1.4));
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w / 2, h * (0.36 + 0.015 * math.sin(t * 0.8))),
          math.max(w, h) * 0.62,
          [_gold.withValues(alpha: glow), _ink.withValues(alpha: 0)],
        ),
    );

    // Uap emas naik pelan.
    for (final m in _motes) {
      final life = ((t * m.speed + m.phase) % 1.1) / 1.1;
      final y = h * (1.04 - life * 1.08);
      final x = m.x * w + math.sin(t * 0.9 + m.phase * 6.283) * m.sway;
      final a = glowIn * (0.10 + 0.45 * math.sin(math.pi * life));
      if (a <= 0.01) continue;
      canvas.drawCircle(
        Offset(x, y),
        m.size * 2.2,
        Paint()
          ..color = _gold.withValues(alpha: a * 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, m.size * 2),
      );
      canvas.drawCircle(Offset(x, y), m.size * 0.7, Paint()..color = _goldHi.withValues(alpha: a));
    }

    // Kurva sangrai yang tergambar dari kiri ke kanan.
    final left = w * 0.10;
    final cw = w * 0.80;
    final base = h * 0.78;
    final amp = math.min(h * 0.11, 96.0);
    final p = _iv(1.0, 4.0, Curves.easeInOut);
    final fadeIn = _iv(0.8, 1.6);

    canvas.drawLine(
      Offset(left, base),
      Offset(left + cw, base),
      Paint()
        ..color = _gold.withValues(alpha: 0.16 * fadeIn)
        ..strokeWidth = 1,
    );

    if (p > 0) {
      const n = 180;
      final path = Path();
      Offset head = Offset(left, base);
      for (var i = 0; i <= n; i++) {
        final x = i / n;
        if (x > p) {
          final y0 = base - amp * _curve(p);
          head = Offset(left + cw * p, y0);
          path.lineTo(head.dx, head.dy);
          break;
        }
        final pt = Offset(left + cw * x, base - amp * _curve(x));
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
        head = pt;
      }

      final grad = ui.Gradient.linear(
        Offset(left, 0),
        Offset(left + cw, 0),
        [_goldLo, _gold, _goldHi],
        [0, 0.6, 1],
      );

      // area di bawah kurva
      final area = Path.from(path)
        ..lineTo(head.dx, base)
        ..lineTo(left, base)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, base - amp),
            Offset(0, base),
            [_gold.withValues(alpha: 0.16), _gold.withValues(alpha: 0)],
          ),
      );
      // pendar
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeJoin = StrokeJoin.round
          ..shader = grad
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // garis utama
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = grad,
      );
      // titik penuntun
      if (p < 1) {
        canvas.drawLine(
          head,
          Offset(head.dx, base),
          Paint()
            ..color = _gold.withValues(alpha: 0.28)
            ..strokeWidth = 1,
        );
        canvas.drawCircle(
          head,
          11,
          Paint()
            ..color = _gold.withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
        );
        canvas.drawCircle(head, 2.8, Paint()..color = _goldHi);
      }
    }

    // Label aroma muncul saat kurva melewati puncaknya.
    for (final (at, ph, _, label) in _peaks) {
      final a = ((p - at) / 0.07).clamp(0.0, 1.0);
      if (a <= 0 || ph < 0.3) continue;
      final y = base - amp * _curve(at) - 12 - 4 * (1 - a);
      _text(
        canvas,
        tr(label).toUpperCase(),
        Offset(left + cw * at, y),
        TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 8.5,
          letterSpacing: 1.6,
          color: _gold.withValues(alpha: 0.85 * a),
          decoration: TextDecoration.none,
        ),
      );
    }

    // Status bergantian dan bilah muat.
    final prog = _iv(0.8, 4.8, Curves.easeInOutCubic);
    final idx = (((t - 1.0) / 0.95).floor()).clamp(0, _phases.length - 1).toInt();
    final local = (t - 1.0 - idx * 0.95).clamp(0.0, 0.95);
    var sa = 1.0;
    if (t < 1.0) {
      sa = 0;
    } else {
      sa = (local / 0.25).clamp(0.0, 1.0);
      if (idx < _phases.length - 1) sa *= ((0.95 - local) / 0.2).clamp(0.0, 1.0);
    }
    final statusEnd = 1 - _iv(4.95, 5.2);
    _text(
      canvas,
      tr(_phases[idx]),
      Offset(w / 2, h * 0.865),
      TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: 10.5,
        letterSpacing: 2.4,
        color: Color.lerp(_goldLo, _gold, 0.7)!.withValues(alpha: sa * statusEnd),
        decoration: TextDecoration.none,
      ),
    );

    final barY = h * 0.915;
    final barA = _iv(0.6, 1.3);
    canvas.drawLine(
      Offset(left, barY),
      Offset(left + cw, barY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10 * barA)
        ..strokeWidth = 1,
    );
    if (prog > 0) {
      canvas.drawLine(
        Offset(left, barY),
        Offset(left + cw * prog, barY),
        Paint()
          ..color = _gold.withValues(alpha: barA)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        Offset(left + cw * prog, barY),
        5,
        Paint()
          ..color = _gold.withValues(alpha: 0.6 * barA)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    _text(
      canvas,
      '${(prog * 100).round()}%',
      Offset(left + cw, barY - 16),
      TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: 9,
        letterSpacing: 1.5,
        color: _gold.withValues(alpha: 0.55 * barA),
        decoration: TextDecoration.none,
      ),
      align: TextAlign.right,
    );
  }

  @override
  bool shouldRepaint(covariant _BrewPainter old) => old.t != t;
}

class _Mote {
  final double x;
  final double speed;
  final double size;
  final double phase;
  final double sway;
  const _Mote({required this.x, required this.speed, required this.size, required this.phase, required this.sway});
}
