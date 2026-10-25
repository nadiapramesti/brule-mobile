import 'package:flutter/material.dart';
import '../motion.dart';
import '../api.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'admin_kit.dart';
import 'download.dart';
import 'order_row.dart';
import 'staff_order_screen.dart';

/// Antrian roastery per tahap. Satu tahap tampil sekali, jadi ratusan pesanan tetap rapi:
/// pilih tahap di atas, cari/filter, centang banyak pesanan, lalu lanjutkan sekaligus dari bar bawah.
class QueueTab extends StatefulWidget {
  const QueueTab({super.key});

  @override
  State<QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends State<QueueTab> {
  final List<Map<String, dynamic>> _items = [];
  final Set<String> _sel = {};
  Map<String, dynamic> _meta = {};
  String _stage = 'queued';
  String _q = '';
  bool _late = false;
  bool _newest = false;
  int _page = 0;
  int _last = 1;
  bool _loading = false;
  bool _busy = false;
  String? _error;
  int _gen = 0; // hanya respons terbaru yang dipakai

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);
  }

  Future<void> _fetch({bool reset = false}) async {
    if (_loading && !reset) return;
    final g = reset ? ++_gen : _gen;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _page = 0;
        _last = 1;
      }
    });
    try {
      final res = await Api.get('/staff/queue', {
        'stage': _stage,
        'sort': _newest ? 'newest' : 'oldest',
        if (_q.isNotEmpty) 'q': _q,
        if (_late) 'late': '1',
        'page': '${_page + 1}',
      });
      if (!mounted || g != _gen) return;
      setState(() {
        _meta = res;
        _items.addAll(((res['data'] ?? []) as List).cast<Map<String, dynamic>>());
        _page = asInt(res['page']);
        _last = asInt(res['last_page']) == 0 ? 1 : asInt(res['last_page']);
      });
    } on ApiException catch (e) {
      if (mounted && g == _gen) setState(() => _error = e.message);
    } finally {
      if (mounted && g == _gen) setState(() => _loading = false);
    }
  }

  void _reset({String? stage}) {
    if (stage != null) _stage = stage;
    _sel.clear();
    _fetch(reset: true);
  }

  void _toast(String m) => toast(context, m);

  void _toggle(String code) => setState(() {
        if (!_sel.remove(code)) _sel.add(code);
      });

  List<Map<String, dynamic>> get _advanceable => _items.where((e) => e['can_advance'] == true).toList();

  Future<void> _advance(Map<String, dynamic> o) async {
    if (await runAction(context, () => Api.post('/staff/orders/${o['code']}/advance'),
        done: '${o['code']} dilanjutkan')) {
      _reset();
    }
  }

  Future<void> _ship(Map<String, dynamic> o) async {
    final resi = await askTracking(context, '${o['code']}');
    if (resi == null || !mounted) return;
    if (await runAction(context, () => Api.post('/staff/orders/${o['code']}/ship', {'tracking_number': resi}),
        done: '${o['code']} dikirim')) {
      _reset();
    }
  }

  Future<void> _advanceSelected() async {
    if (_sel.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final res = await Api.post('/staff/orders/advance', {'codes': _sel.toList()});
      final moved = asInt(res['moved']);
      final skipped = asInt(res['skipped']);
      _toast(moved > 0
          ? '$moved pesanan dilanjutkan${skipped > 0 ? ', $skipped dilewati' : ''}'
          : 'Tidak ada yang bisa dilanjutkan.');
      _reset();
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(String code) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => StaffOrderScreen(code: code)));
    if (mounted) _reset();
  }

  @override
  Widget build(BuildContext context) {
    final stats = (_meta['stats'] ?? {}) as Map;
    final stages = ((_meta['stages'] ?? []) as List).cast<Map<String, dynamic>>();
    final batches = ((_meta['batches'] ?? []) as List).cast<Map<String, dynamic>>();
    final adv = _advanceable;
    final allSelected = adv.isNotEmpty && adv.every((e) => _sel.contains('${e['code']}'));
    final total = asInt(_meta['total']);

    return Column(
      children: [
        Expanded(
          child: Narrow(
            maxWidth: 720,
            child: RefreshIndicator(
              color: Brule.amber,
              onRefresh: () async => _reset(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  Row(
                    children: [
                      Container(width: 18, height: 3, color: Brule.amber),
                      const SizedBox(width: 10),
                      Text('ANTRIAN ROASTERY', style: Brule.condensed(22, spacing: 2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Stat('MENUNGGU BAYAR', '${asInt(stats['waiting'])}'),
                      Stat('PRODUKSI', '${asInt(stats['in_production'])}'),
                      Stat('KIRIM HARI INI', '${asInt(stats['shipped_today'])}'),
                      Stat('BERAT', '${(asInt(stats['grams']) / 1000).toStringAsFixed(1)} kg'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (final s in stages)
                        _StageTile(
                          label: '${s['label']}',
                          total: asInt(s['total']),
                          late: asInt(s['late']),
                          grams: asInt(s['grams']),
                          selected: _stage == '${s['status']}',
                          onTap: () => _reset(stage: '${s['status']}'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SearchBox(
                    hint: 'cari kode, nama, atau biji, contoh: BRL-2026',
                    onChanged: (v) {
                      _q = v.trim();
                      _reset();
                    },
                  ),
                  const SizedBox(height: 10),
                  ChipRow(
                      children: [
                        FilterChip(
                          label: const Text('TERLAMBAT > 24 JAM'),
                          selected: _late,
                          onSelected: (v) {
                            _late = v;
                            _reset();
                          },
                        ),
                        ChoiceChip(
                          label: Text(_newest ? 'TERBARU DULU' : 'TERLAMA DULU'),
                          selected: true,
                          onSelected: (_) {
                            _newest = !_newest;
                            _reset();
                          },
                        ),
                        if (adv.isNotEmpty)
                          ActionChip(
                            avatar: Icon(allSelected ? Icons.deselect : Icons.select_all, size: 16),
                            label: Text(allSelected ? 'LEPAS SEMUA' : 'PILIH SEMUA (${adv.length})'),
                            onPressed: () => setState(() {
                              final codes = adv.map((e) => '${e['code']}');
                              if (allSelected) {
                                _sel.removeAll(codes);
                              } else {
                                _sel.addAll(codes);
                              }
                            }),
                          ),
                      ],
                    ),
                  if (_stage == 'queued' && batches.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Brule.field,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text('RENCANA SANGRAI', style: Brule.mono(11, color: Brule.amber)),
                        subtitle: Text('Antrian masuk dikelompokkan per biji dan level', style: Brule.mono(9)),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        children: [
                          for (final b in batches)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Expanded(child: Text('${b['name']} · ${b['level']}')),
                                  Text('${b['grams']} g · ${b['orders']} pesanan', style: Brule.mono(10)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text('$total PESANAN', style: Brule.mono(10, color: Brule.cream)),
                      const Spacer(),
                      Text('Tahan baris untuk memilih', style: Brule.mono(9)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_error != null) ErrorBox(_error!),
                  if (_items.isEmpty && !_loading && _error == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Center(child: Text('Tidak ada pesanan di tahap ini.', style: Brule.mono(11))),
                    ),
                  for (final (i, o) in _items.indexed)
                    Reveal(index: i, child: OrderRow(
                      o: o,
                      selectable: true,
                      selected: _sel.contains('${o['code']}'),
                      onToggle: () => _toggle('${o['code']}'),
                      onLongPress: o['can_advance'] == true ? () => _toggle('${o['code']}') : null,
                      onTap: () => _sel.isNotEmpty && o['can_advance'] == true
                          ? _toggle('${o['code']}')
                          : _open('${o['code']}'),
                      onAdvance: () => _advance(o),
                      onShip: () => _ship(o),
                    )),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator(color: Brule.amber)),
                    )
                  else if (_page < _last && _error == null)
                    OutlinedButton(onPressed: _fetch, child: const Text('MUAT LEBIH BANYAK')),
                ],
              ),
            ),
          ),
        ),
        if (_sel.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Text('${_sel.length} DIPILIH', style: Brule.mono(11, color: Brule.cream)),
                const Spacer(),
                TextButton(onPressed: () => setState(_sel.clear), child: const Text('BATAL')),
                IconButton(
                  tooltip: 'Unduh label paket',
                  onPressed: _busy
                      ? null
                      : () => downloadAndShare(context, '/staff/labels', {'codes': _sel.join(',')}),
                  icon: const Icon(Icons.local_shipping_outlined),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  onPressed: _busy ? null : _advanceSelected,
                  child: Text(_busy ? 'MEMPROSES...' : 'LANJUTKAN SEMUA'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StageTile extends StatelessWidget {
  final String label;
  final int total;
  final int late;
  final int grams;
  final bool selected;
  final VoidCallback onTap;
  const _StageTile({
    required this.label,
    required this.total,
    required this.late,
    required this.grams,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Material(
          color: selected ? Brule.amber.withValues(alpha: 0.1) : Brule.field,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: selected ? Brule.amber : Colors.white.withValues(alpha: 0.1),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: Column(
                children: [
                  Text(label.toUpperCase(),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: Brule.mono(8.5)),
                  const SizedBox(height: 4),
                  Text('$total', style: Brule.condensed(24, color: selected ? Brule.amber : Brule.cream)),
                  const SizedBox(height: 2),
                  Text(
                    late > 0 ? '$late telat' : '${(grams / 1000).toStringAsFixed(1)} kg',
                    style: Brule.mono(8.5, color: late > 0 ? Brule.amber : Brule.kraft),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
