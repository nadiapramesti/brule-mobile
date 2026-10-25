import 'package:flutter/material.dart';

/// Muncul pelan dari bawah (fade + geser). [index] memberi jeda bertahap supaya daftar
/// terasa mengalir, dibatasi 10 supaya item jauh di bawah tidak menunggu lama.
class Reveal extends StatelessWidget {
  final int index;
  final double dy;
  final Widget child;
  const Reveal({super.key, this.index = 0, this.dy = 14, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = index.clamp(0, 9) * 55;
    final total = 380 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (context, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, dy * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

/// IndexedStack yang menjaga state tiap tab, tapi saat pindah tab isinya memudar dan naik sedikit.
class FadeIndexed extends StatefulWidget {
  final int index;
  final List<Widget> children;
  const FadeIndexed({super.key, required this.index, required this.children});

  @override
  State<FadeIndexed> createState() => _FadeIndexedState();
}

class _FadeIndexedState extends State<FadeIndexed> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 280), value: 1);
  late final Animation<double> _v = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(covariant FadeIndexed old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _v,
      builder: (context, child) => Opacity(
        opacity: _v.value,
        child: Transform.translate(offset: Offset(0, 12 * (1 - _v.value)), child: child),
      ),
      child: IndexedStack(index: widget.index, children: widget.children),
    );
  }
}

/// Transisi halaman: halaman baru memudar masuk sambil bergeser dari kanan,
/// halaman di bawahnya bergeser sedikit ke kiri.
class BrulePageTransitions extends PageTransitionsBuilder {
  const BrulePageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final leave = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return SlideTransition(
      position: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.05, 0)).animate(leave),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.6).animate(leave),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(enter),
          child: FadeTransition(opacity: enter, child: child),
        ),
      ),
    );
  }
}
