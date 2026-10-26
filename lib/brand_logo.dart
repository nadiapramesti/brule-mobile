import 'package:flutter/material.dart';
import 'theme.dart';

/// Logo BRÛLÉ coffee lab (putih transparan, untuk latar gelap).
/// [mark] = ikon labu saja, selain itu logo horizontal lengkap.
class BrandLogo extends StatelessWidget {
  final double height;
  final bool mark;
  const BrandLogo({super.key, this.height = 32, this.mark = false});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      mark ? 'assets/images/logo_mark.png' : 'assets/images/logo_full.png',
      height: height,
      fit: BoxFit.contain,
      // logo aslinya putih: di mode terang diwarnai gelap supaya tetap terbaca
      color: Brule.light ? Brule.cream : null,
      colorBlendMode: Brule.light ? BlendMode.srcIn : null,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'BRÛLÉ coffee lab',
    );
  }
}
