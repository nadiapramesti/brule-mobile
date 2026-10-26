import 'package:flutter/material.dart';
import 'motion.dart';
import 'theme.dart';
import 'util.dart';

/// Garis waktu tahap pesanan, sama seperti halaman Lacak Pesanan di web:
/// titik terisi untuk tahap yang sudah dilewati, cincin berdenyut di tahap sekarang,
/// waktu di bawah tiap tahap, dan nomor resi di tahap Dikirim.
class OrderTimeline extends StatelessWidget {
  final List<String> keys;
  final List<String> labels;
  final List<String?> times;
  final int? step;
  final String? tracking;
  /// Tanggal "terbaik dinikmati sebelum" (sudah diformat), tampil di bawah tahap sangrai.
  final String? bestBefore;
  const OrderTimeline({
    super.key,
    required this.keys,
    required this.labels,
    required this.times,
    required this.step,
    this.tracking,
    this.bestBefore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: Brule.field,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Brule.hair(0.1)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < labels.length; i++)
            Reveal(
              index: i,
              dy: 8,
              child: _Row(
              label: labels[i],
              time: i < times.length ? times[i] : null,
              best: keys.length > i && keys[i] == 'roasting' && step != null && i <= step! ? bestBefore : null,
              resi: keys.length > i && keys[i] == 'shipped' && step != null && i <= step! ? tracking : null,
              done: step != null && i <= step!,
              now: step == i,
              lineDone: step != null && i < step!,
              last: i == labels.length - 1,
              finished: i == labels.length - 1,
            ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String? time;
  final String? resi;
  final String? best;
  final bool done;
  final bool now;
  final bool lineDone;
  final bool last;
  final bool finished;
  const _Row({
    required this.label,
    required this.time,
    required this.resi,
    this.best,
    required this.done,
    required this.now,
    required this.lineDone,
    required this.last,
    required this.finished,
  });

  @override
  Widget build(BuildContext context) {
    final t = done && time != null && time!.isNotEmpty ? dateTime(time) : '';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 3),
                _Dot(done: done, pulse: now && !finished),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: lineDone ? Brule.blue : Brule.kraft.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 10 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      color: done ? Brule.cream : Brule.kraft.withValues(alpha: 0.5),
                      fontWeight: now ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (t.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(t, style: Brule.mono(10.5)),
                  ],
                  if (best != null && best!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('Terbaik dinikmati sebelum $best', style: Brule.mono(10.5, color: Brule.amber)),
                  ],
                  if (resi != null && resi!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    SelectableText('Resi: $resi', style: Brule.mono(11.5, color: Brule.blueText)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final bool done;
  final bool pulse;
  const _Dot({required this.done, required this.pulse});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant _Dot old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_c.isAnimating) _c.repeat();
    if (!widget.pulse && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.pulse)
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Container(
                width: 15 + 7 * _c.value,
                height: 15 + 7 * _c.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Brule.blue.withValues(alpha: 0.45 * (1 - _c.value)),
                ),
              ),
            ),
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.done ? Brule.blue : Brule.field,
              border: Border.all(
                color: widget.done ? Brule.blue : Brule.kraft.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
