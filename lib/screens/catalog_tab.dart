import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import '../motion.dart';
import '../api.dart';
import '../add_sheet.dart';
import '../auth_gate.dart';
import '../coffee_bag.dart';
import '../favorites.dart';
import '../models.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'coffee_detail_screen.dart';
import 'recommend_screen.dart';

class CatalogTab extends StatefulWidget {
  const CatalogTab({super.key});

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab> {
  String _q = '';
  String? _process;
  bool _onlyFav = false;

  @override
  void initState() {
    super.initState();
    Favorites.I.refresh();
  }

  Future<void> _toggleFav(Coffee c) async {
    if (!await requireLogin(context, reason: 'Masuk dulu untuk menyimpan favorit.')) return;
    try {
      await Favorites.I.toggle(c.id, c.slug);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _pickFavFilter(bool on) async {
    if (on && !await requireLogin(context, reason: 'Masuk dulu untuk melihat favoritmu.')) return;
    if (mounted) setState(() => _onlyFav = on);
  }

  Future<List<Coffee>> _load() async {
    final res = await Api.get('/coffees', _q.isEmpty ? null : {'q': _q});
    return (res['data'] as List)
        .map((e) => Coffee.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 18, height: 3, color: Brule.amber),
                    const SizedBox(width: 10),
                    Text('KOPI SANGRAI', style: Brule.condensed(22, spacing: 2)),
                  ],
                ),
                const SizedBox(height: 14),
                SearchBox(
                  hint: 'cari kopi, contoh: Ethiopia',
                  onChanged: (v) => setState(() => _q = v),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const RecommendScreen())),
                    icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: const Text('BINGUNG PILIH? TEMUKAN KOPIMU'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Loader<List<Coffee>>(
              key: ValueKey(_q),
              load: _load,
              builder: (context, list, reload) {
                final processes = {
                  ...list.map((c) => c.process).whereType<String>()
                }.toList()
                  ..sort();
                return ListenableBuilder(
                  listenable: Favorites.I,
                  builder: (context, _) {
                final shown = list
                    .where((c) => _process == null || c.process == _process)
                    .where((c) => !_onlyFav || Favorites.I.has(c.id))
                    .toList();

                return Column(
                  children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ChipRow(
                          children: [
                            FilterChip(
                              avatar: Icon(_onlyFav ? Icons.favorite : Icons.favorite_border,
                                  size: 16, color: _onlyFav ? Brule.red : null),
                              label: const Text('Favorit saya'),
                              selected: _onlyFav,
                              showCheckmark: false,
                              onSelected: _pickFavFilter,
                            ),
                            for (final p in <String?>[null, ...processes])
                              ChoiceChip(
                                label: Text(p ?? 'Semua'),
                                selected: _process == p,
                                onSelected: (_) => setState(() => _process = p),
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        color: Brule.amber,
                        onRefresh: reload,
                        child: shown.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Center(
                                      child: Text(
                                        _onlyFav
                                            ? 'Belum ada kopi favorit. Tekan ikon hati di kartu kopi.'
                                            : 'Kopi tidak ditemukan.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 240,
                                  mainAxisExtent: 322,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: shown.length,
                                itemBuilder: (context, i) {
                                  final c = shown[i];
                                  return Reveal(index: i, child: ProductCard(
                                    image: c.image,
                                    art: CoffeeBagArt(coffee: c),
                                    onAdd: () => addCoffeeSheet(context, c),
                                    title: c.name,
                                    meta: c.cupping == null
                                        ? 'SPECIALTY'
                                        : 'CUPPING ${c.cupping!.toStringAsFixed(1)}',
                                    price: 'mulai ${rupiah(c.fromPrice)} / 100g',
                                    soldOut: !c.inStock,
                                    isFavorite: Favorites.I.has(c.id),
                                    onFavorite: () => _toggleFav(c),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => CoffeeDetailScreen(coffee: c)),
                                    ),
                                  ));
                                },
                              ),
                      ),
                    ),
                  ],
                );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
