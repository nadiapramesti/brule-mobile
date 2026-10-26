import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import '../prefs.dart';
import '../add_sheet.dart';
import '../api.dart';
import '../auth_gate.dart';
import '../cart.dart';
import '../coffee_bag.dart';
import '../models.dart';
import '../brand_logo.dart';
import '../notice_bell.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'coffee_detail_screen.dart';
import 'blend_screen.dart';
import 'gear_detail_screen.dart';

const _ember = Color(0xFFE8782A);

// Banner foto selalu gelap (dua mode), jadi warna teksnya tetap terang.
const _heroInk = Color(0xFF121212);
const _heroSub = Color(0xFFD8C5A6);
const _heroAmber = Color(0xFFF2A266);

const _stages = [
  ('Antrian', 'Pesanan masuk papan roastery, biji mentah ditimbang.', 'assets/images/step1.jpg'),
  ('Sangrai', 'Satu batch untuk satu pesanan, mengikuti kurva yang kamu pilih.', 'assets/images/step2.jpg'),
  ('Giling', 'Digiling di ukuran alat seduhmu. Pilih biji utuh kalau punya grinder.', 'assets/images/step3.jpg'),
  ('Kemas', 'Masuk kantong BRÛLÉ berkatup, tanggal sangrai dicetak hari itu juga.', 'assets/images/step4.jpg'),
  ('Kirim', 'Berangkat maksimal 24 jam setelah biji keluar dari mesin.', 'assets/images/step5.jpg'),
];

/// Beranda ala toko online: pencarian, banner, pintasan, lalu rak produk.
/// [onGo] pindah tab: 0 beranda, 1 katalog (seg 0 kopi / 1 perlengkapan), 2 keranjang, 3 pesanan.
class HomeTab extends StatefulWidget {
  final void Function(int tab, {int seg}) onGo;
  const HomeTab({super.key, required this.onGo});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<(List<Coffee>, List<Gear>)> _f = _load();

  Future<(List<Coffee>, List<Gear>)> _load() async {
    final r = await Future.wait([Api.get('/coffees'), Api.get('/gear')]);
    final coffees = (r[0]['data'] as List)
        .map((e) => Coffee.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => (b.cupping ?? 0).compareTo(a.cupping ?? 0));
    final gear = (r[1]['data'] as List)
        .map((e) => Gear.fromJson(e as Map<String, dynamic>))
        .toList();
    return (coffees, gear);
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() => _f = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Brule.amber,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          SafeArea(
            bottom: false,
            child: Narrow(
              maxWidth: 1000,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const BrandLogo(height: 34),
                        const Spacer(),
                        const ThemeIconButton(),
                        const SizedBox(width: 8),
                        ValueListenableBuilder<int>(
                          valueListenable: Api.session,
                          builder: (context, _, _) => Api.loggedIn
                              ? const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: NoticeBell(),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(0, 38),
                                      padding: const EdgeInsets.symmetric(horizontal: 18),
                                    ),
                                    onPressed: () => requireLogin(context),
                                    child: const Text('MASUK'),
                                  ),
                                ),
                        ),
                        ListenableBuilder(
                          listenable: Cart.I,
                          builder: (context, _) => IconButton.filledTonal(
                            tooltip: tr('Keranjang'),
                            onPressed: () => widget.onGo(2),
                            icon: Badge(
                              label: Text('${Cart.I.count}'),
                              isLabelVisible: Cart.I.count > 0,
                              child: const Icon(Icons.shopping_basket_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ValueListenableBuilder<int>(
                      valueListenable: Api.session,
                      builder: (context, _, _) {
                        final n = '${Api.user?['name'] ?? ''}'.split(' ').first;
                        return Text(n.isEmpty ? 'HALO' : 'HALO, ${n.toUpperCase()}',
                            style: Brule.mono(11, color: Brule.amber));
                      },
                    ),
                    const SizedBox(height: 4),
                    Text('Mau seduh apa hari ini?', style: Brule.condensed(28)),
                    const SizedBox(height: 14),
                    _FakeSearch(onTap: () => widget.onGo(1, seg: 0)),
                    const SizedBox(height: 16),
                    _Banners(onGo: widget.onGo),
                    const SizedBox(height: 20),
                    _Shortcuts(onGo: widget.onGo),
                  ],
                ),
              ),
            ),
          ),
          FutureBuilder<(List<Coffee>, List<Gear>)>(
            future: _f,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(child: CircularProgressIndicator(color: Brule.amber)),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: ErrorPanel('${snap.error}', onRetry: _refresh),
                );
              }
              final (coffees, gear) = snap.data!;
              return Column(
                children: [
                  _Shelf(
                    title: 'Kopi pilihan',
                    subtitle: 'Diurutkan dari skor cupping tertinggi',
                    onMore: () => widget.onGo(1, seg: 0),
                    children: [
                      for (final c in coffees.take(8))
                        _MiniCard(
                          image: c.image,
                          art: CoffeeBagArt(coffee: c),
                          title: c.name,
                          meta: c.cupping == null
                              ? 'SPECIALTY'
                              : 'CUPPING ${c.cupping!.toStringAsFixed(1)}',
                          price: 'mulai ${rupiah(c.fromPrice)}',
                          unit: '/100g',
                          soldOut: !c.inStock,
                          onAdd: () => addCoffeeSheet(context, c),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => CoffeeDetailScreen(coffee: c))),
                        ),
                    ],
                  ),
                  if (gear.isNotEmpty)
                    _Shelf(
                      title: 'Perlengkapan seduh',
                      subtitle: 'Alat untuk menyeduh biji dari gudang kami',
                      onMore: () => widget.onGo(1, seg: 1),
                      children: [
                        for (final g in gear.take(8))
                          _MiniCard(
                            image: g.image,
                            title: g.name,
                            meta: g.category.toUpperCase(),
                            price: rupiah(g.price),
                            soldOut: !g.inStock,
                            onAdd: () => addGearQuick(context, g),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => GearDetailScreen(gear: g))),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
          const _Trust(),
          const _Stages(),
        ],
      ),
    );
  }
}

class _FakeSearch extends StatelessWidget {
  final VoidCallback onTap;
  const _FakeSearch({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Brule.field,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Brule.hair(0.12)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.search, color: Brule.kraft.withValues(alpha: 0.8)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('cari kopi atau alat, contoh: Aeropress',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Brule.kraft.withValues(alpha: 0.9))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Banners extends StatefulWidget {
  final void Function(int tab, {int seg}) onGo;
  const _Banners({required this.onGo});

  @override
  State<_Banners> createState() => _BannersState();
}

class _BannersState extends State<_Banners> {
  final _c = PageController();
  Timer? _t;
  int _i = 0;

  static const _slides = [
    ('Disangrai setelah\npesanan masuk.', 'Tidak ada stok kopi sangrai yang menua di rak.', 'assets/images/hero.webp', 'RACIK KOPIMU', 0, true),
    ('Satu batch,\nsatu pesanan.', 'Pilih level sangrai dan ukuran gilingan sesuai alat seduhmu.', 'assets/images/step2.jpg', 'LIHAT KOPI', 0, false),
    ('Berangkat dalam\n24 jam.', 'Dari mesin sangrai langsung ke kurir, tanggal sangrai tercetak di kantong.', 'assets/images/step5.jpg', 'BELANJA SEKARANG', 0, false),
  ];

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_c.hasClients) return;
      _c.animateToPage((_i + 1) % _slides.length,
          duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, box) => SizedBox(
            height: 204,
            child: OverflowBox(
              minWidth: box.maxWidth + 12,
              maxWidth: box.maxWidth + 12,
              child: PageView.builder(
            controller: _c,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _i = i),
            itemBuilder: (context, i) {
              final s = _slides[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(s.$3, fit: BoxFit.cover, alignment: const Alignment(0.3, 0)),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              _heroInk.withValues(alpha: 0.92),
                              _heroInk.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (s.$6) const _RoastPill() else Text('BRÛLÉ LAB', style: Brule.mono(11, color: _heroAmber)),
                            const SizedBox(height: 12),
                            Text(s.$1,
                                style: Brule.condensed(28, weight: FontWeight.w700, color: Brule.paper)
                                    .copyWith(height: 1.08)),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: SizedBox(
                                  width: 230,
                                  child: Text(s.$2,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: _heroSub.withValues(alpha: 0.9),
                                          fontSize: 12.5,
                                          height: 1.4)),
                                ),
                              ),
                            ),
                            FilledButton(
                              onPressed: () => widget.onGo(1, seg: s.$5),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                              ),
                              child: Text(s.$4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _i ? Brule.amber : Brule.kraft.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Shortcuts extends StatelessWidget {
  final void Function(int tab, {int seg}) onGo;
  const _Shortcuts({required this.onGo});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, VoidCallback)>[
      (Icons.coffee_outlined, 'KOPI', () => onGo(1, seg: 0)),
      (Icons.coffee_maker_outlined, 'ALAT SEDUH', () => onGo(1, seg: 1)),
      (Icons.receipt_long_outlined, 'PESANAN', () => onGo(3)),
      (
        Icons.tune,
        'RACIK BLEND',
        () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const BlendScreen())),
      ),
    ];
    return Row(
      children: [
        for (final it in items)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: it.$3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Brule.blue.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Brule.blueText.withValues(alpha: 0.25)),
                      ),
                      child: Icon(it.$1, color: Brule.blueText),
                    ),
                    const SizedBox(height: 8),
                    Text(it.$2, style: Brule.mono(10)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Shelf extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onMore;
  final List<Widget> children;
  const _Shelf({
    required this.title,
    required this.subtitle,
    required this.onMore,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Brule.condensed(24)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: Brule.mono(10)),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: onMore,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text('SEMUA'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: children.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => children[i],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String? image;
  final Widget? art;
  final String title;
  final String meta;
  final String price;
  final String? unit;
  final bool soldOut;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  const _MiniCard({
    required this.image,
    this.art,
    required this.title,
    required this.meta,
    required this.price,
    this.unit,
    required this.soldOut,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 172,
      child: Material(
        color: Brule.field,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Brule.hair(0.1)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    (image == null || image!.isEmpty) && art != null
                        ? art!
                        : NetImage(url: image),
                    if (soldOut)
                      Positioned(
                          top: 8, left: 8, child: Tag('HABIS', color: Brule.red, filled: true)),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Brule.condensed(16)),
                      const SizedBox(height: 4),
                      Text(meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Brule.mono(9.5, color: Brule.amber)),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(price,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w500)),
                                if (unit != null)
                                  Text(unit!, style: Brule.mono(9)),
                              ],
                            ),
                          ),
                          IconButton.filled(
                            tooltip: tr('Tambah ke keranjang'),
                            onPressed: soldOut ? null : onAdd,
                            icon: const Icon(Icons.add, size: 20),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(38, 38),
                              backgroundColor: Brule.blue,
                              foregroundColor: Brule.paper,
                            ),
                          ),
                        ],
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
}

class _Trust extends StatelessWidget {
  const _Trust();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.local_fire_department_outlined, 'Disangrai\nsetelah dipesan'),
      (Icons.local_shipping_outlined, 'Dikirim\nmax 24 jam'),
      (Icons.verified_outlined, 'Asal biji\ntercatat'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
      child: Narrow(
        maxWidth: 1000,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Brule.field,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Brule.hair(0.1)),
          ),
          child: Row(
            children: [
              for (final it in items)
                Expanded(
                  child: Column(
                    children: [
                      Icon(it.$1, color: Brule.amber),
                      const SizedBox(height: 8),
                      Text(it.$2,
                          textAlign: TextAlign.center,
                          style: Brule.mono(10, color: Brule.kraft)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
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
        color: _heroInk.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Brule.paper.withValues(alpha: 0.15)),
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
          Text('SEDANG DISANGRAI', style: Brule.mono(11, color: _heroSub.withValues(alpha: 0.9))),
          const SizedBox(width: 10),
          Text('${temp.toStringAsFixed(1)}°C', style: Brule.mono(11, color: Brule.paper)),
          const SizedBox(width: 10),
          Text(clock, style: Brule.mono(11, color: _heroSub.withValues(alpha: 0.65))),
        ],
      ),
    );
  }
}

class _Stages extends StatelessWidget {
  const _Stages();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Setelah kamu bayar', style: Brule.condensed(24)),
                const SizedBox(height: 2),
                Text('5 tahap, pantau di tab PESANAN', style: Brule.mono(10)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 232,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _stages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final st = _stages[i];
                return Container(
                  width: 200,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Brule.field,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Brule.hair(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 104,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(st.$3, fit: BoxFit.cover),
                            Positioned(
                              left: 10,
                              top: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Brule.bg.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('0${i + 1}', style: Brule.mono(11, color: _ember)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(st.$1, style: Brule.condensed(19)),
                            const SizedBox(height: 4),
                            Text(st.$2,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Brule.kraft.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(child: Text('BRÛLÉ · SPECIALTY COFFEE LAB', style: Brule.mono(10))),
        ],
      ),
    );
  }
}
