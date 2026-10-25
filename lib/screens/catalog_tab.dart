import 'package:flutter/material.dart';
import '../api.dart';
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
                return RefreshIndicator(
                  color: Brule.amber,
                  onRefresh: reload,
                  child: list.isEmpty
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
                            mainAxisExtent: 292,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final c = list[i];
                            return ProductCard(
                              image: c.image,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
