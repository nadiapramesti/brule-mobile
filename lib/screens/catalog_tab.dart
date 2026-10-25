import 'package:flutter/material.dart';
import '../motion.dart';
import '../api.dart';
import '../add_sheet.dart';
import '../coffee_bag.dart';
import '../models.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'coffee_detail_screen.dart';

class CatalogTab extends StatefulWidget {
  const CatalogTab({super.key});

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab> {
  String _q = '';
  String? _process;

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
                final shown = _process == null
                    ? list
                    : list.where((c) => c.process == _process).toList();

                return Column(
                  children: [
                    if (processes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ChipRow(
                          children: [
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
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Center(child: Text('Kopi tidak ditemukan.')),
                                  ),
                                ],
                              )
                            : GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
            ),
          ),
        ],
      ),
    );
  }
}
