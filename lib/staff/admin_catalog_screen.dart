import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'admin_kit.dart';

/// Kopi atau produk: lihat harga/stok dan tampilkan atau sembunyikan dari toko.
/// Tambah dan ubah detail (foto, cerita, traceability) tetap lewat panel web.
class AdminCatalogScreen extends StatefulWidget {
  final bool coffees;
  const AdminCatalogScreen({super.key, required this.coffees});

  @override
  State<AdminCatalogScreen> createState() => _AdminCatalogScreenState();
}

class _AdminCatalogScreenState extends State<AdminCatalogScreen> {
  String _q = '';
  int _v = 0;

  String get _base => widget.coffees ? '/admin/coffees' : '/admin/products';

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: widget.coffees ? 'Kopi' : 'Produk',
      child: Loader<Map<String, dynamic>>(
        key: ValueKey('$_q|$_v'),
        load: () => Api.get(_base, _q.isEmpty ? null : {'q': _q}),
        builder: (context, d, reload) {
          final list = ((d['data'] ?? []) as List).cast<Map<String, dynamic>>();
          return RefreshIndicator(
            color: Brule.amber,
            onRefresh: reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                SearchBox(
                  hint: widget.coffees ? 'cari nama kopi' : 'cari nama produk',
                  onChanged: (v) => setState(() => _q = v.trim()),
                ),
                const SizedBox(height: 4),
                Text('Tambah dan ubah detail dilakukan lewat panel web.', style: Brule.mono(9)),
                const SizedBox(height: 10),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('Tidak ada data.', style: Brule.mono(11))),
                  ),
                for (final it in list) _tile(it),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tile(Map<String, dynamic> it) {
    final active = it['is_active'] == true;
    final info = widget.coffees
        ? [
            if (it['region'] != null) '${it['region']}',
            '${asInt(it['profiles'])} sangrai',
            'mulai ${rupiah(asInt(it['from_price']))}/100 g',
            'stok ${(asInt(it['stock_gram']) / 1000).toStringAsFixed(1)} kg',
          ]
        : [
            '${it['category']}',
            rupiah(asInt(it['price'])),
            'stok ${asInt(it['stock'])} unit',
          ];
    return Panel(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text('${it['name']}', style: Brule.condensed(18))),
                    if (!active) ...[const SizedBox(width: 8), const Tag('DISEMBUNYIKAN', color: Brule.amber)],
                  ],
                ),
                const SizedBox(height: 2),
                Text(info.join(' · '), style: Brule.mono(9.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Switch(
                value: active,
                onChanged: (_) async {
                  final ok = await runAction(
                    context,
                    () => Api.post('$_base/${it['id']}/toggle'),
                    done: active ? '${it['name']} disembunyikan dari toko' : '${it['name']} tampil di toko',
                  );
                  if (ok && mounted) setState(() => _v++);
                },
              ),
              Text(active ? 'TAMPIL' : 'SEMBUNYI', style: Brule.mono(8)),
            ],
          ),
        ],
      ),
    );
  }
}
