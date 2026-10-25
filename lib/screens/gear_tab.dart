import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'gear_detail_screen.dart';

class GearTab extends StatefulWidget {
  const GearTab({super.key});

  @override
  State<GearTab> createState() => _GearTabState();
}

class _GearTabState extends State<GearTab> {
  String _q = '';

  Future<List<Gear>> _load() async {
    final res = await Api.get('/gear', _q.isEmpty ? null : {'q': _q});
    return (res['data'] as List)
        .map((e) => Gear.fromJson(e as Map<String, dynamic>))
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
                    Text('PERLENGKAPAN', style: Brule.condensed(22, spacing: 2)),
                  ],
                ),
                const SizedBox(height: 14),
                SearchBox(
                  hint: 'cari alat, contoh: Aeropress',
                  onChanged: (v) => setState(() => _q = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: Loader<List<Gear>>(
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
                              child: Center(child: Text('Produk tidak ditemukan.')),
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
                            final g = list[i];
                            return ProductCard(
                              image: g.image,
                              title: g.name,
                              meta: g.category.toUpperCase(),
                              price: rupiah(g.price),
                              soldOut: !g.inStock,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => GearDetailScreen(gear: g)),
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
