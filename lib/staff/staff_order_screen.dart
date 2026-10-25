import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'queue_tab.dart';

/// Detail pesanan untuk roaster dan admin, dengan aksi sesuai peran dan tahap.
class StaffOrderScreen extends StatefulWidget {
  final String code;
  const StaffOrderScreen({super.key, required this.code});

  @override
  State<StaffOrderScreen> createState() => _StaffOrderScreenState();
}

class _StaffOrderScreenState extends State<StaffOrderScreen> {
  Map<String, dynamic>? _o;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final o = await Api.get('/staff/orders/${widget.code}');
      if (mounted) setState(() => _o = o);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _act(Future<Map<String, dynamic>> Function() call, String done) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final o = await call();
      if (!mounted) return;
      setState(() => _o = o);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final c = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Batalkan ${widget.code}?', style: Brule.condensed(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stok biji dikembalikan dan pelanggan diberi tahu.'),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              maxLength: 120,
              decoration: const InputDecoration(hintText: 'alasan, contoh: stok biji habis'),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('KEMBALI'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size(96, 44), backgroundColor: Brule.red),
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('BATALKAN'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    await _act(
      () => Api.post('/admin/orders/${widget.code}/cancel',
          reason.isEmpty ? {} : {'reason': reason}),
      'Pesanan dibatalkan',
    );
  }

  Widget _row(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text(k, style: Brule.mono(10))),
            Expanded(
              child: Text(v,
                  style: bold
                      ? const TextStyle(fontWeight: FontWeight.w600)
                      : null),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final o = _o;
    return Scaffold(
      appBar: AppBar(title: Text(widget.code)),
      body: o == null
          ? Center(
              child: _error != null
                  ? Padding(padding: const EdgeInsets.all(24), child: ErrorBox(_error!))
                  : const CircularProgressIndicator(color: Brule.amber),
            )
          : Narrow(
              child: RefreshIndicator(
                color: Brule.amber,
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    _actions(o),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      ErrorBox(_error!),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text('${o['status_label']}', style: Brule.condensed(26)),
                        ),
                        if (o['is_late'] == true) ...[
                          const Tag('TERLAMBAT', color: Brule.amber),
                          const SizedBox(width: 6),
                        ],
                        Tag(o['is_paid'] == true ? 'LUNAS' : 'BELUM BAYAR',
                            color: o['is_paid'] == true ? Brule.blueText : Brule.amber),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: asInt(o['progress']) / 100,
                        minHeight: 6,
                        color: Brule.blue,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ((o['steps'] ?? []) as List).map((e) => '${(e as Map)['label']}').join('  ›  '),
                      style: Brule.mono(9),
                    ),
                    const Label('PELANGGAN'),
                    _box([
                      _row('NAMA', '${(o['customer_info'] ?? {})['name'] ?? '-'}'),
                      _row('EMAIL', '${(o['customer_info'] ?? {})['email'] ?? '-'}'),
                      _row('WHATSAPP', '${(o['customer_info'] ?? {})['phone'] ?? '-'}'),
                    ]),
                    const Label('PENGIRIMAN'),
                    _box([
                      _row('PENERIMA', '${(o['recipient'] ?? {})['name'] ?? ''}', bold: true),
                      _row('TELEPON', '${(o['recipient'] ?? {})['phone'] ?? ''}'),
                      _row('ALAMAT', '${(o['recipient'] ?? {})['address'] ?? ''}'),
                      if (o['tracking_number'] != null)
                        _row('RESI', '${o['tracking_number']}', bold: true),
                    ]),
                    const Label('ISI PESANAN'),
                    _box([
                      for (final it in ((o['items'] ?? []) as List).cast<Map<String, dynamic>>())
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${it['name']}'),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        '${it['detail'] ?? ''}',
                                        if (asInt(it['grams']) > 0) '${it['grams']} g',
                                      ].where((x) => x.isNotEmpty).join(' · '),
                                      style: Brule.mono(10, color: Brule.amber),
                                    ),
                                  ],
                                ),
                              ),
                              Text(rupiah(asInt(it['line_total']))),
                            ],
                          ),
                        ),
                    ]),
                    const Label('RINCIAN BIAYA'),
                    _box([
                      _row('SUBTOTAL', rupiah(asInt(o['subtotal']))),
                      _row('ONGKIR', rupiah(asInt(o['shipping_cost']))),
                      if (asInt(o['addon_cost']) > 0)
                        _row('KEMASAN KADO', rupiah(asInt(o['addon_cost']))),
                      if (asInt(o['discount']) > 0)
                        _row('DISKON ${o['voucher_code'] ?? ''}', '- ${rupiah(asInt(o['discount']))}'),
                      const Divider(height: 16),
                      Row(
                        children: [
                          Text('TOTAL', style: Brule.mono(11)),
                          const Spacer(),
                          Text(rupiah(asInt(o['total'])), style: Brule.condensed(24)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        o['payment_method'] == 'cod' ? 'COD (bayar di tempat)' : 'Bayar online',
                        style: Brule.mono(10),
                      ),
                    ]),
                    if (o['gift_wrap'] == true && '${o['card_message'] ?? ''}'.isNotEmpty) ...[
                      const Label('KARTU UCAPAN'),
                      _box([Text('${o['card_message']}')]),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _box(List<Widget> children) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Brule.field,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );

  /// Tombol aksi di atas halaman, sesuai peran dan tahap pesanan.
  Widget _actions(Map<String, dynamic> o) {
    final buttons = <Widget>[
      if (o['can_advance'] == true)
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () => _act(() => Api.post('/staff/orders/${widget.code}/advance'),
                  'Dilanjutkan ke ${o['next_label']}'),
          icon: const Icon(Icons.arrow_forward, size: 18),
          iconAlignment: IconAlignment.end,
          label: Text('LANJUT: ${'${o['next_label']}'.toUpperCase()}'),
        ),
      if (o['can_ship'] == true)
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () async {
                  final resi = await askTracking(context, widget.code);
                  if (resi == null) return;
                  await _act(
                    () => Api.post('/staff/orders/${widget.code}/ship', {'tracking_number': resi}),
                    'Pesanan dikirim',
                  );
                },
          icon: const Icon(Icons.local_shipping_outlined, size: 18),
          label: const Text('KIRIM + NOMOR RESI'),
        ),
      if (o['can_complete'] == true)
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () => _act(() => Api.post('/admin/orders/${widget.code}/complete'),
                  'Pesanan selesai'),
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('TANDAI SELESAI'),
        ),
      if (o['can_cancel'] == true && Api.user?['role'] == 'admin')
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Brule.red,
            side: BorderSide(color: Brule.red.withValues(alpha: 0.6)),
          ),
          onPressed: _busy ? null : _cancel,
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text('BATALKAN PESANAN'),
        ),
    ];
    if (buttons.isEmpty) {
      return Text('Tidak ada aksi untuk pesanan ini di tahap sekarang.',
          style: Brule.mono(10));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          buttons[i],
        ],
      ],
    );
  }
}
