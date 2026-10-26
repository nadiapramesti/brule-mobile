import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import '../api.dart';
import '../reviews_section.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'admin_kit.dart';

const _kShow = {'all': 'Semua', 'visible': 'Tampil', 'hidden': 'Disembunyikan'};

/// Moderasi ulasan: sembunyikan, tampilkan lagi, atau hapus.
class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  String _show = 'all';
  int _v = 0;

  Future<void> _act(Future<void> Function() a, {String? done}) async {
    if (await runAction(context, a, done: done) && mounted) setState(() => _v++);
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Ulasan',
      child: Loader<Map<String, dynamic>>(
        key: ValueKey('$_show|$_v'),
        load: () => Api.get('/admin/reviews', {'tampil': _show}),
        builder: (context, d, reload) {
          final cn = (d['counts'] ?? {}) as Map;
          final list = ((d['data'] ?? []) as List).cast<Map<String, dynamic>>();
          return RefreshIndicator(
            color: Brule.amber,
            onRefresh: reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                ChipPicker<String>(
                  items: _kShow.keys.toList(),
                  value: _show,
                  label: (k) => '${_kShow[k]} ${asInt(cn[k])}',
                  onChanged: (k) => setState(() => _show = k),
                ),
                const SizedBox(height: 10),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('Belum ada ulasan.', style: Brule.mono(11))),
                  ),
                for (final (i, r) in list.indexed) ...[
                  if (i == 0 || dayGroup(list[i - 1]) != dayGroup(r)) GroupTitle(dayGroup(r), first: i == 0),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('${r['coffee']}', style: Brule.condensed(18))),
                            if (r['is_hidden'] == true) Tag('DISEMBUNYIKAN', color: Brule.amber),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Stars(asInt(r['rating']).toDouble(), size: 14),
                            const SizedBox(width: 8),
                            Expanded(child: Text('${r['name']}', style: Brule.mono(10, color: Brule.cream))),
                          ],
                        ),
                        if ('${r['body'] ?? ''}'.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('${r['body']}',
                              style: TextStyle(color: Brule.kraft.withValues(alpha: 0.95), height: 1.4)),
                        ],
                        const SizedBox(height: 4),
                        Text(clockOf(r['created_at']), style: Brule.mono(9)),
                        const SizedBox(height: 10),
                        ButtonRow(
                          children: [
                            OutlinedButton(
                              onPressed: () => _act(() => Api.post('/admin/reviews/${r['id']}/toggle'),
                                  done: r['is_hidden'] == true ? 'Ulasan ditampilkan' : 'Ulasan disembunyikan'),
                              child: Text(r['is_hidden'] == true ? 'TAMPILKAN' : 'SEMBUNYIKAN'),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Brule.red),
                              onPressed: () async {
                                if (await confirmDialog(context, 'Hapus ulasan?', 'Ulasan dihapus permanen.',
                                    ok: 'HAPUS', danger: true)) {
                                  await _act(() => Api.delete('/admin/reviews/${r['id']}'), done: 'Ulasan dihapus');
                                }
                              },
                              child: const Text('HAPUS'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
