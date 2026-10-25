import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';
import 'paint_text.dart';
import 'theme.dart';

const _levels = ['light', 'medium_light', 'medium', 'medium_dark', 'dark'];
const _levelLabels = ['LIGHT', 'MEDIUM LIGHT', 'MEDIUM', 'MEDIUM DARK', 'DARK'];

const _accents = {
  'Washed': Color(0xFF2A5DB0),
  'Natural': Color(0xFFE8782A),
  'Honey': Color(0xFFD9A441),
  'Wet-Hulled': Color(0xFF5E8C6A),
  'Anaerobic': Color(0xFF2FA3A3),
  'Carbonic Maceration': Color(0xFF8E6BBF),
};

int _crc32(String s) {
  var crc = 0xFFFFFFFF;
  for (final b in utf8.encode(s)) {
    crc ^= b;
    for (var k = 0; k < 8; k++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

/// Ilustrasi kantong kopi, sama dengan komponen coffee-bag di web BRÛLÉ.
/// Dipakai kalau kopi belum punya foto produk.
class CoffeeBagArt extends StatelessWidget {
  final Coffee coffee;
  final String? level;
  const CoffeeBagArt({super.key, required this.coffee, this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Brule.field,
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: AspectRatio(
        aspectRatio: 200 / 250,
        child: CustomPaint(
          painter: _BagPainter(
            slug: coffee.slug,
            shortName: coffee.shortName,
            process: coffee.process,
            altitude: coffee.altitude,
            level: level ?? coffee.signatureLevel ?? 'medium',
          ),
        ),
      ),
    );
  }
}

class _BagPainter extends CustomPainter {
  final String slug;
  final String shortName;
  final String? process;
  final int? altitude;
  final String level;

  _BagPainter({
    required this.slug,
    required this.shortName,
    required this.process,
    required this.altitude,
    required this.level,
  });

  @override
  void paint(Canvas c, Size size) {
    final s = math.min(size.width / 200, size.height / 250);
    c.save();
    c.translate((size.width - 200 * s) / 2, (size.height - 250 * s) / 2);
    c.scale(s);

    final accent = _accents[process] ?? const Color(0xFF2A5DB0);
    final ink = const Color(0xFF1A1208);
    final brown = const Color(0xFF5C4B33);
    final lv = math.max(0, _levels.indexOf(level));

    // bayangan
    c.drawOval(
      Rect.fromCenter(center: const Offset(100, 243), width: 172, height: 14),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // badan kantong
    final body = Path()
      ..moveTo(26, 36)
      ..lineTo(174, 36)
      ..cubicTo(180, 90, 184, 170, 182, 230)
      ..quadraticBezierTo(182, 244, 170, 244)
      ..lineTo(30, 244)
      ..quadraticBezierTo(18, 244, 18, 230)
      ..cubicTo(16, 170, 20, 90, 26, 36)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF232323), Color(0xFF121212), Color(0xFF1C1C1C)],
          stops: [0, 0.45, 1],
        ).createShader(const Rect.fromLTRB(18, 36, 184, 244)),
    );
    c.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.13),
    );
    c.drawPath(
      Path()
        ..moveTo(30, 44)
        ..cubicTo(26, 100, 25, 170, 27, 228),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.07),
    );

    // segel atas
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(26, 12, 148, 26), const Radius.circular(3)),
      Paint()..color = const Color(0xFF191919),
    );
    final sealLine = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (final ly in [17.0, 22.0, 27.0, 32.0]) {
      c.drawLine(Offset(28, ly), Offset(172, ly), sealLine);
    }
    final notch = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF2A2A2A);
    c.drawPath(
      Path()
        ..moveTo(26, 24)
        ..lineTo(22, 26.5)
        ..lineTo(26, 29)
        ..moveTo(174, 24)
        ..lineTo(178, 26.5)
        ..lineTo(174, 29),
      notch,
    );

    // katup
    c.drawCircle(const Offset(152, 56), 6.5, Paint()..color = const Color(0xFF1D1D1D));
    c.drawCircle(
      const Offset(152, 56),
      6.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF3A3A3A),
    );
    c.drawCircle(const Offset(152, 56), 2.2, Paint()..color = const Color(0xFF0C0C0C));

    // label kraft
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(38, 64, 124, 158), const Radius.circular(3)),
      Paint()..color = Brule.kraft,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(42, 68, 116, 150), const Radius.circular(2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = brown.withValues(alpha: 0.45),
    );

    // wordmark
    paintCentered(
      c,
      'BRÛLÉ',
      100,
      98,
      TextStyle(
        fontFamily: 'IBMPlexSansCondensed',
        fontWeight: FontWeight.w600,
        fontSize: 19,
        letterSpacing: 3,
        color: ink,
      ),
    );

    // kromatogram mini, bentuknya diturunkan dari slug (sama dengan web)
    final peaks = <List<double>>[];
    for (var i = 0; i < 5; i++) {
      peaks.add([
        55 + (_crc32('${slug}c$i') % 88).toDouble(),
        2.5 + (_crc32('${slug}a$i') % 60) / 10,
        1.6 + (_crc32('${slug}w$i') % 18) / 10,
      ]);
    }
    final trace = Path();
    for (var x = 50.0; x <= 150; x += 2) {
      var y = 0.0;
      for (final p in peaks) {
        final d = (x - p[0]) / p[2];
        y += p[1] * math.exp(-d * d);
      }
      final py = 113 - y + 11 - 2;
      if (x == 50) {
        trace.moveTo(x, py);
      } else {
        trace.lineTo(x, py);
      }
    }
    c.drawPath(
      trace,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeJoin = StrokeJoin.round
        ..color = accent,
    );
    final rule = Paint()
      ..color = ink.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    c.drawLine(const Offset(50, 122), const Offset(150, 122), rule);

    // nama
    final words = shortName.split(' ');
    final line1 = words.first;
    final line2 = words.skip(1).join(' ');
    paintCentered(
      c,
      line1,
      100,
      154,
      TextStyle(
        fontFamily: 'IBMPlexSansCondensed',
        fontWeight: FontWeight.w600,
        fontSize: line1.length > 8 ? 21 : 25,
        color: ink,
      ),
    );
    if (line2.isNotEmpty) {
      paintCentered(
        c,
        line2,
        100,
        171,
        TextStyle(
          fontFamily: 'IBMPlexSansCondensed',
          fontWeight: FontWeight.w600,
          fontSize: line2.length > 11 ? 11 : 13,
          letterSpacing: 0.5,
          color: ink.withValues(alpha: 0.82),
        ),
      );
    }
    c.drawLine(const Offset(50, 181), const Offset(150, 181), rule);

    // proses dan ketinggian
    final alt = altitude == null ? '' : ' · ${_dots(altitude!)} M';
    paintCentered(
      c,
      '${(process ?? '').toUpperCase()}$alt',
      100,
      193,
      TextStyle(fontFamily: 'IBMPlexMono', fontSize: 6.2, letterSpacing: 0.6, color: brown),
    );

    // titik tingkat sangrai
    for (var i = 0; i < 5; i++) {
      final center = Offset(64.0 + i * 18, 204);
      if (i <= lv) {
        c.drawCircle(center, 2.7, Paint()..color = accent);
      } else {
        c.drawCircle(
          center,
          2.7,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9
            ..color = brown.withValues(alpha: 0.6),
        );
      }
    }
    paintCentered(
      c,
      _levelLabels[lv],
      100,
      215,
      TextStyle(fontFamily: 'IBMPlexMono', fontSize: 5.2, letterSpacing: 0.8, color: brown),
    );

    // pita warna proses
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(24, 228, 152, 4), const Radius.circular(2)),
      Paint()..color = accent,
    );

    c.restore();
  }

  String _dots(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      b.write(s[i]);
      final left = s.length - i;
      if (left > 1 && left % 3 == 1) b.write('.');
    }
    return b.toString();
  }

  @override
  bool shouldRepaint(covariant _BagPainter old) =>
      old.slug != slug || old.level != level || old.process != process;
}
