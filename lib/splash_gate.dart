import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _gold = Color(0xFFD9B26F);
const _goldHi = Color(0xFFF8E7BC);
const _goldLo = Color(0xFF9C7430);
const _ink = Color(0xFF121212); // sama dengan splash bawaan Android, supaya sambungannya mulus

/// Splash pembuka: labu BRÛLÉ berkilau emas, garis ornamen, lalu nama toko.
/// Tampil sekali tiap aplikasi dibuka dari nol, di atas layar utama yang sudah mulai dimuat.
class SplashGate extends StatefulWidget {
  final Widget child;
  const SplashGate({super.key, required this.child});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  static bool _played = false;
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
  bool _done = _played;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || _done) return;
    _started = true;
    // Pengguna yang mematikan animasi di HP: cukup kilas singkat.
    if (MediaQuery.of(context).disableAnimations) {
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

  double _iv(double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  Widget _splash() {
    final t = _c.value;
    final scale = 0.96 + 0.04 * _iv(0, 0.45);
    final sweep = -0.5 + 2.0 * _iv(0.12, 0.62, Curves.easeInOut);
    final glow = 0.16 * _iv(0, 0.5);
    final line = _iv(0.40, 0.66);
    final dot = _iv(0.46, 0.62);
    final word = _iv(0.50, 0.80);
    final tag = _iv(0.68, 0.90);
    final fade = 1 - _iv(0.90, 1.0, Curves.easeIn);
    final spacing = 14 - 6 * word;
    const markH = 112.0;

    return Opacity(
      opacity: fade,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          color: _ink,
          child: Stack(
            children: [
              // cahaya hangat tipis di belakang labu
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.75,
                      colors: [_gold.withValues(alpha: glow), _ink.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
              Center(
                child: Transform.scale(
                  scale: scale,
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
              Center(
                child: Transform.translate(
                  offset: const Offset(0, markH / 2 + 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      const SizedBox(height: 22),
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
