import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'paint_text.dart';
import 'theme.dart';

class _Peak {
  final double at;
  final double h;
  final double w;
  final String reads;
  const _Peak(this.at, this.h, this.w, this.reads);
}

// Senyawa aroma kopi, urutan dan tinggi sama dengan hero di web.
const _peaks = [
  _Peak(0.109, 0.30, 0.0042, 'Segar'),
  _Peak(0.236, 0.74, 0.0052, 'Jeruk'),
  _Peak(0.358, 0.41, 0.0046, 'Beri'),
  _Peak(0.483, 0.63, 0.0050, 'Melati'),
  _Peak(0.624, 0.97, 0.0068, 'Kakao'),
  _Peak(0.749, 0.52, 0.0048, 'Kacang'),
  _Peak(0.915, 0.36, 0.0056, 'Cengkeh'),
];

class Chromatogram extends StatelessWidget {
  final double height;
  const Chromatogram({super.key, this.height = 170});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _ChromatogramPainter()),
    );
  }
}

class _ChromatogramPainter extends CustomPainter {
  static const ember = Color(0xFFE8782A);

  double _y(double x) {
    var y = 0.0;
    for (final p in _peaks) {
      final d = (x - p.at) / (p.w * 2.2);
      y += p.h * math.exp(-d * d);
    }
    return math.min(y, 1.05);
  }

  @override
  void paint(Canvas c, Size s) {
    const topPad = 26.0;
    const bottomPad = 32.0;
    final w = s.width;
    final baseY = s.height - bottomPad;
    final plotH = baseY - topPad;

    final line = Path();
    final area = Path()..moveTo(0, baseY);
    for (var px = 0.0; px <= w; px += 1) {
      final y = baseY - _y(px / w) * plotH;
      if (px == 0) {
        line.moveTo(px, y);
      } else {
        line.lineTo(px, y);
      }
      area.lineTo(px, y);
    }
    area
      ..lineTo(w, baseY)
      ..close();

    c.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ember.withValues(alpha: 0.32), ember.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, topPad, w, plotH)),
    );
    c.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round
        ..color = ember,
    );

    // sumbu waktu
    final axis = Paint()
      ..color = Brule.kraft.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    c.drawLine(Offset(0, baseY), Offset(w, baseY), axis);
    final tick = Brule.mono(8, color: Brule.kraft.withValues(alpha: 0.9));
    for (var m = 0; m <= 12; m += 2) {
      final x = m / 13 * w;
      c.drawLine(Offset(x, baseY), Offset(x, baseY + 4), axis);
      paintCentered(c, '$m', math.max(8, x), baseY + 15, tick);
    }
    paintCentered(c, 'waktu retensi (menit)', w / 2, baseY + 28, tick);

    // nama kesan aroma di atas puncak
    final label = Brule.mono(9, color: Brule.kraft);
    for (final p in _peaks) {
      if (p.h < 0.3) continue;
      final x = (p.at * w).clamp(24.0, w - 24).toDouble();
      paintCentered(c, p.reads, x, baseY - p.h * plotH - 7, label);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
