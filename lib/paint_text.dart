import 'package:flutter/material.dart';

/// Gambar teks rata tengah pada titik (cx, baseline y) di kanvas.
void paintCentered(Canvas c, String text, double cx, double y, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final base = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  tp.paint(c, Offset(cx - tp.width / 2, y - base));
}
