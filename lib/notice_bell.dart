import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'notices.dart';
import 'theme.dart';

/// Ikon bel bulat dengan lencana jumlah belum dibaca. Bel bergoyang dan lencana "membal"
/// saat ada notifikasi baru masuk.
class NoticeBell extends StatefulWidget {
  const NoticeBell({super.key});

  @override
  State<NoticeBell> createState() => _NoticeBellState();
}

class _NoticeBellState extends State<NoticeBell> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  int _last = Notices.unread.value;

  @override
  void initState() {
    super.initState();
    Notices.unread.addListener(_changed);
  }

  void _changed() {
    final n = Notices.unread.value;
    if (n > _last) _c.forward(from: 0);
    _last = n;
  }

  @override
  void dispose() {
    Notices.unread.removeListener(_changed);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Notices.unread,
      builder: (context, n, _) {
        final label = n > 99 ? '99+' : '$n';
        return Tooltip(
          message: 'Notifikasi',
          child: Material(
            color: Brule.field,
            shape: CircleBorder(side: BorderSide(color: Brule.hair(0.16))),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: Notices.open,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _c,
                      builder: (context, child) => Transform.rotate(
                        angle: math.sin(_c.value * math.pi * 6) * 0.38 * (1 - _c.value),
                        alignment: Alignment.topCenter,
                        child: child,
                      ),
                      child: Icon(
                        n > 0 ? Icons.notifications_active_outlined : Icons.notifications_none,
                        size: 22,
                        color: n > 0 ? Brule.cream : Brule.kraft,
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: AnimatedScale(
                        scale: n > 0 ? 1 : 0,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutBack,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Brule.amber,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Brule.bg, width: 2),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                                fontSize: 10.5, fontWeight: FontWeight.w700, color: Brule.bg, height: 1.1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
