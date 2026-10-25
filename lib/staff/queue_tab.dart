import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'staff_order_screen.dart';

/// Antrian roastery: pesanan per tahap, majukan tahap, kirim dengan resi.
class QueueTab extends StatefulWidget {
  const QueueTab({super.key});

  @override
  State<QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends State<QueueTab> {
  int _v = 0;
  String _q = '';
  bool _late = false;
  final Set<String> _sel = {};
  bool _busy = false;

  Future<Map<String, dynamic>> _load() => Api.get('/staff/queue', {
        if (_q.isNotEmpty) 'q': _q,
        if (_late) 'late': '1',
      });

  void _reload() => setState(() => _v++);

  void _toggle(String code) => setState(() {
        if (!_sel.remove(code)) _sel.add(code);
      });

  Future<void> _advanceSelected() async {
    if (_sel.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final res = await Api.post('/staff/orders/advance', {'codes': _sel.toList()});
      final moved = asInt(res['moved']);
      final skipped = asInt(res['skipped']);
      _toast(moved > 0
          ? '$moved pesanan dilanjutkan${skipped > 0 ? ', $skipped dilewati' : ''}'
          : 'Tidak ada yang bisa dilanjutkan. Tahap Dikemas butuh nomor resi.');
      _sel.clear();
      _reload();
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _advance(Map<String, dynamic> o) async {
    try {
      await Api.post('/staff/orders/${o['code']}/advance');
      _toast('${o['code']} dilanjutkan');
      _reload();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _ship(Map<String, dynamic> o) async {
    final ok = await askTracking(context, '${o['code']}');
    if (ok == null) return;
    try {
      await Api.post('/staff/orders/${o['code']}/ship', {'tracking_number': ok});
      _toast('${o['code']} dikirim');
      _reload();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _open(String code) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => StaffOrderScreen(code: code)));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 18, height: 3, color: Brule.amber),
                    const SizedBox(width: 10),
                    Text('ANTRIAN ROASTERY', style: Brule.condensed(22, spacing: 2)),
                  ],
                ),
                const SizedBox(height: 12),
                SearchBox(
                  hint: 'cari kode, nama, atau biji, contoh: BRL-2026',
                  onChanged: (v) => setState(() => _q = v),
                ),
                const SizedBox(height: 8),
                FilterChip(
                  label: const Text('TERLAMBAT > 24 JAM'),
                  selected: _late,
                  onSelected: (v) => setState(() => _late = v),
                ),
                const SizedBox(height: 6),
                Text('Tahan kartu untuk memilih beberapa pesanan sekaligus.', style: Brule.mono(9)),
              ],
            ),
          ),
          Expanded(
            child: Loader<Map<String, dynamic>>(
              key: ValueKey('$_v|$_q|$_late'),
              load: _load,
              builder: (context, data, reload) {
                final stats = (data['stats'] ?? {}) as Map;
                final columns = ((data['columns'] ?? []) as List).cast<Map<String, dynamic>>();
                final batches = ((data['batches'] ?? []) as List).cast<Map<String, dynamic>>();
                return RefreshIndicator(
                  color: Brule.amber,
                  onRefresh: reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      Row(
                        children: [
                          _Stat('MENUNGGU BAYAR', '${stats['waiting'] ?? 0}'),
                          _Stat('PRODUKSI', '${stats['in_production'] ?? 0}'),
                          _Stat('KIRIM HARI INI', '${stats['shipped_today'] ?? 0}'),
                          _Stat('GRAM', '${stats['grams'] ?? 0}'),
                        ],
                      ),
                      if (batches.isNotEmpty) ...[
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
                            subtitle: Text('Antrian masuk dikelompokkan per biji dan level',
                                style: Brule.mono(9)),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            children: [
                              for (final b in batches)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text('${b['name']} · ${b['level']}'),
                                      ),
                                      Text('${b['grams']} g · ${b['orders']} pesanan',
                                          style: Brule.mono(10)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      for (final col in columns) ...[
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Text('${col['label']}'.toUpperCase(),
                                style: Brule.condensed(18, spacing: 1.5)),
                            const SizedBox(width: 10),
                            Tag('${col['total']} PESANAN'),
                            const SizedBox(width: 6),
                            Tag('${col['grams']} g', color: Brule.blueText),
                            const Spacer(),
                            if (((col['orders'] ?? []) as List).any((e) => (e as Map)['can_advance'] == true))
                              TextButton(
                                onPressed: () => setState(() {
                                  final codes = ((col['orders'] as List).cast<Map<String, dynamic>>())
                                      .where((e) => e['can_advance'] == true)
                                      .map((e) => '${e['code']}')
                                      .toList();
                                  final all = codes.every(_sel.contains);
                                  if (all) {
                                    _sel.removeAll(codes);
                                  } else {
                                    _sel.addAll(codes);
                                  }
                                }),
                                child: const Text('PILIH SEMUA'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (((col['orders'] ?? []) as List).isEmpty)
                          Text('Tidak ada pesanan di tahap ini.', style: Brule.mono(10))
                        else
                          for (final o in ((col['orders'] as List).cast<Map<String, dynamic>>()))
                            OrderCard(
                              o: o,
                              selected: _sel.contains('${o['code']}'),
                              onLongPress: o['can_advance'] == true ? () => _toggle('${o['code']}') : null,
                              onTap: () => _sel.isNotEmpty && o['can_advance'] == true
                                  ? _toggle('${o['code']}')
                                  : _open('${o['code']}'),
                              onAdvance: () => _advance(o),
                              onShip: () => _ship(o),
                            ),
                      ],
                    ],
                  ),
                );
              },
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
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: _busy ? null : _advanceSelected,
                    child: Text(_busy ? 'MEMPROSES...' : 'LANJUTKAN SEMUA'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Brule.field,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(value, style: Brule.condensed(20)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: Brule.mono(7.5)),
          ],
        ),
      ),
    );
  }
}

/// Kartu pesanan untuk antrian dan daftar pesanan admin.
class OrderCard extends StatelessWidget {
  final Map<String, dynamic> o;
  final VoidCallback onTap;
  final VoidCallback? onAdvance;
  final VoidCallback? onShip;
  final bool showTotal;
  final bool selected;
  final VoidCallback? onLongPress;
  const OrderCard({
    super.key,
    required this.o,
    required this.onTap,
    this.onAdvance,
    this.onShip,
    this.showTotal = false,
    this.selected = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final status = '${o['status']}';
    final late = o['is_late'] == true;
    final canAdvance = onAdvance != null && o['can_advance'] == true;
    final canShip = onShip != null && o['can_ship'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Brule.field,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected
                ? Brule.amber
                : (late ? Brule.amber.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.1)),
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (selected) ...[
                      const Icon(Icons.check_circle, size: 18, color: Brule.amber),
                      const SizedBox(width: 6),
                    ],
                    Expanded(child: Text('${o['code']}', style: Brule.mono(12, color: Brule.cream))),
                    if (late) ...[
                      const Tag('TERLAMBAT', color: Brule.amber),
                      const SizedBox(width: 6),
                    ],
                    Tag('${o['status_label']}'.toUpperCase(), color: statusColor(status)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${o['recipient'] ?? ''}', style: Brule.condensed(18)),
                const SizedBox(height: 2),
                Text('${o['summary'] ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Brule.kraft.withValues(alpha: 0.9), fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      [
                        if (asInt(o['grams']) > 0) '${o['grams']} g',
                        dateTime('${o['since']}'),
                      ].join(' · '),
                      style: Brule.mono(10),
                    ),
                    const Spacer(),
                    if (showTotal)
                      Text(rupiah(asInt(o['total'])), style: Brule.condensed(17)),
                  ],
                ),
                if (canAdvance || canShip) ...[
                  const SizedBox(height: 12),
                  if (canAdvance)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                      onPressed: onAdvance,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      iconAlignment: IconAlignment.end,
                      label: Text('LANJUT: ${'${o['next_label']}'.toUpperCase()}'),
                    ),
                  if (canShip)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                      onPressed: onShip,
                      icon: const Icon(Icons.local_shipping_outlined, size: 18),
                      label: const Text('KIRIM + NOMOR RESI'),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog isi nomor resi. Mengembalikan teks resi atau null kalau dibatalkan.
Future<String?> askTracking(BuildContext context, String code) {
  final c = TextEditingController();
  String? error;
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('Kirim $code', style: Brule.condensed(20)),
          content: TextField(
            controller: c,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'contoh: JNE1234567890',
              errorText: error,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(96, 44)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('BATAL'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
              onPressed: () {
                final v = c.text.trim();
                if (v.length < 6) {
                  setState(() => error = 'Nomor resi terlalu pendek.');
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: const Text('KIRIM'),
            ),
          ],
        );
      },
    ),
  );
}
