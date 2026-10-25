import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../api.dart';
import '../chromatogram.dart';
import '../coffee_bag.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import '../util.dart';
import 'coffee_detail_screen.dart';

const _ember = Color(0xFFE8782A);
const _ink = Color(0xFF1A1208);
const _kraftInk = Color(0xFF5C4B33);

const _stages = [
  ('Antrian', 'Pesanan masuk papan roastery, biji mentah ditimbang.', 'assets/images/step1.jpg'),
  ('Sangrai', 'Satu batch untuk satu pesanan, mengikuti kurva yang kamu pilih.', 'assets/images/step2.jpg'),
  ('Giling', 'Digiling di ukuran alat seduhmu. Pilih biji utuh kalau punya grinder.', 'assets/images/step3.jpg'),
  ('Kemas', 'Masuk kantong BRÛLÉ berkatup, tanggal sangrai dicetak hari itu juga.', 'assets/images/step4.jpg'),
  ('Kirim', 'Berangkat maksimal 24 jam setelah biji keluar dari mesin.', 'assets/images/step5.jpg'),
];

/// Halaman awal, mengikuti landing page web BRÛLÉ.
class HomeTab extends StatefulWidget {
  final VoidCallback onShop;
  const HomeTab({super.key, required this.onShop});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _beansKey = GlobalKey();

  Future<List<Coffee>> _load() async {
    final res = await Api.get('/coffees');
    return (res['data'] as List)
        .map((e) => Coffee.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _toBeans() {
    final ctx = _beansKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Hero(onShop: widget.onShop, onBeans: _toBeans),
        _Promises(),
        Padding(
          key: _beansKey,
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 8),
          child: Narrow(
            maxWidth: 1000,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Biji yang sedang ada di gudang', style: Brule.condensed(30)),
                const SizedBox(height: 8),
                Text(
                  'Tiap lot punya catatan asal-usulnya sendiri. Kalau datanya tidak lengkap, kopinya tidak kami jual.',
                  style: TextStyle(color: Brule.kraft.withValues(alpha: 0.85), height: 1.5),
                ),
                const SizedBox(height: 20),
                Loader<List<Coffee>>(
                  load: _load,
                  builder: (context, list, reload) {
                    final shown = list.take(6).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            mainAxisExtent: 292,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: shown.length,
                          itemBuilder: (context, i) {
                            final c = shown[i];
                            return ProductCard(
                              image: c.image,
                              art: CoffeeBagArt(coffee: c),
                              title: c.name,
                              meta: c.cupping == null
                                  ? 'SPECIALTY'
                                  : 'CUPPING ${c.cupping!.toStringAsFixed(1)}',
                              price: 'mulai ${rupiah(c.fromPrice)} / 100g',
                              soldOut: !c.inStock,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => CoffeeDetailScreen(coffee: c)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: widget.onShop,
                          child: Text('LIHAT SEMUA ${list.length} KOPI'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),
        const _Stages(),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final VoidCallback onShop;
  final VoidCallback onBeans;
  const _Hero({required this.onShop, required this.onBeans});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 600;
    final top = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/hero.webp',
            fit: BoxFit.cover,
            alignment: const Alignment(0.36, 0),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF121212).withValues(alpha: 0.82),
                  const Color(0xFF121212).withValues(alpha: 0.72),
                  const Color(0xFF121212),
                ],
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, top + 28, 24, 8),
          child: Narrow(
            maxWidth: 1000,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 18, height: 3, color: Brule.amber),
                    const SizedBox(width: 10),
                    Text('BRÛLÉ', style: Brule.condensed(22, spacing: 3)),
                  ],
                ),
                const SizedBox(height: 28),
                const _RoastPill(),
                const SizedBox(height: 22),
                Text('Disangrai setelah',
                    style: Brule.condensed(wide ? 58 : 38, weight: FontWeight.w700)
                        .copyWith(height: 1.05)),
                Text('pesanan masuk.',
                    style: Brule.condensed(wide ? 58 : 38, weight: FontWeight.w700, color: _ember)
                        .copyWith(height: 1.05)),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Text(
                    'Kami tidak menyimpan kopi yang sudah disangrai. Biji mentahnya menunggu di gudang sampai kamu memilih level sangrai dan ukuran gilingannya, baru mesinnya dinyalakan.',
                    style: TextStyle(color: Brule.kraft, height: 1.55, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(onPressed: onShop, child: const Text('RACIK KOPIMU')),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: onBeans,
                        child: const Text('LIHAT BIJI YANG ADA'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Chromatogram(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Pil "sedang disangrai" dengan suhu dan jam yang bergerak, seperti di web.
class _RoastPill extends StatefulWidget {
  const _RoastPill();

  @override
  State<_RoastPill> createState() => _RoastPillState();
}

class _RoastPillState extends State<_RoastPill> {
  Timer? _timer;
  int _t = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _t++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final temp = 210 + 6 * math.sin(_t / 2.3) + 2 * math.sin(_t * 1.7);
    final secs = 9 * 60 + 42 + _t;
    final clock =
        '${(secs ~/ 60 % 60).toString().padLeft(2, '0')}:${(secs % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 16, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Brule.cream.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: _ember, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text('SEDANG DISANGRAI', style: Brule.mono(11, color: Brule.kraft.withValues(alpha: 0.85))),
          const SizedBox(width: 10),
          Text('${temp.toStringAsFixed(1)}°C', style: Brule.mono(11, color: Brule.cream)),
          const SizedBox(width: 10),
          Text(clock, style: Brule.mono(11, color: Brule.kraft.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class _Promises extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      ('1,2 kg', 'Batch terbesar yang kami sangrai sekali jalan.'),
      ('1 petani', 'Tiap lot datang dari satu kebun, bukan campuran.'),
      ('24 jam', 'Jarak dari biji keluar mesin sampai paket berangkat.'),
    ];
    final wide = MediaQuery.sizeOf(context).width > 600;

    Widget cell((String, String) it) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(it.$1, style: Brule.mono(24, color: Brule.cream)),
              const SizedBox(height: 6),
              Text(it.$2,
                  style: TextStyle(
                      color: Brule.kraft.withValues(alpha: 0.7), fontSize: 13, height: 1.45)),
            ],
          ),
        );

    return Container(
      color: Brule.bg,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Narrow(
        maxWidth: 1000,
        child: Container(
          padding: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Brule.kraft.withValues(alpha: 0.15))),
          ),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final it in items) Expanded(child: Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: cell(it),
                    )),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final it in items) cell(it)],
                ),
        ),
      ),
    );
  }
}

class _Stages extends StatelessWidget {
  const _Stages();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Brule.kraft,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      child: Narrow(
        maxWidth: 1000,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yang terjadi setelah kamu bayar',
                style: Brule.condensed(30, color: _ink)),
            const SizedBox(height: 10),
            const Text(
              'Lima tahap, dan kamu bisa melihat pesananmu ada di tahap mana lewat tab Pesanan.',
              style: TextStyle(color: _kraftInk, height: 1.5, fontSize: 15),
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < _stages.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 112,
                        height: 112,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(_stages[i].$3, fit: BoxFit.cover),
                            Positioned(
                              left: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF121212).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('0${i + 1}', style: Brule.mono(11, color: Brule.cream)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_stages[i].$1, style: Brule.condensed(21, color: _ink)),
                          const SizedBox(height: 4),
                          Text(_stages[i].$2,
                              style: const TextStyle(color: _kraftInk, height: 1.45, fontSize: 13.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: Text('BRÛLÉ · SPECIALTY COFFEE LAB',
                  style: Brule.mono(10, color: _kraftInk)),
            ),
          ],
        ),
      ),
    );
  }
}
