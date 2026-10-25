import 'package:flutter/material.dart';
import '../api.dart';
import '../cart.dart';
import '../models.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'addresses_screen.dart';
import 'order_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _voucher = TextEditingController();
  final _card = TextEditingController();
  String _payment = 'online';
  bool _gift = false;
  bool _busy = false;
  bool _loadingAddr = true;
  Address? _addr;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  @override
  void dispose() {
    _voucher.dispose();
    _card.dispose();
    super.dispose();
  }

  /// Alamat utama dari buku alamat dipakai otomatis.
  Future<void> _loadAddress() async {
    try {
      final res = await Api.get('/addresses');
      final list = (res['data'] as List)
          .map((e) => Address.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _addr = list.isEmpty
            ? null
            : list.firstWhere((x) => x.isDefault, orElse: () => list.first);
        _loadingAddr = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingAddr = false);
    }
  }

  Future<void> _pick() async {
    final a = await Navigator.of(context).push<Address>(
      MaterialPageRoute(builder: (_) => const AddressesScreen(pick: true)),
    );
    if (a != null && mounted) setState(() => _addr = a);
  }

  Future<void> _addNew() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddressFormScreen()),
    );
    if (ok == true) {
      setState(() => _loadingAddr = true);
      await _loadAddress();
    }
  }

  Future<void> _submit() async {
    final a = _addr;
    if (a == null) {
      setState(() => _error = 'Pilih atau tambah alamat pengiriman dulu.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final nav = Navigator.of(context);
    try {
      final items = Cart.I.lines
          .map((l) => l.kind == 'coffee'
              ? {
                  'type': 'coffee',
                  'profile_id': l.refId,
                  'grams': l.grams,
                  'grind': l.grind,
                  'qty': l.qty,
                  if (l.blendId != null) 'blend_profile_id': l.blendId,
                  if (l.blendId != null) 'ratio': l.ratio,
                }
              : {
                  'type': 'gear',
                  'product_id': l.refId,
                  'option': l.option,
                  'qty': l.qty,
                })
          .toList();

      final res = await Api.post('/orders', {
        'name': a.recipient,
        'phone': a.phone,
        'address': a.address,
        'payment': _payment,
        if (_voucher.text.trim().isNotEmpty) 'voucher': _voucher.text.trim(),
        'gift_wrap': _gift,
        if (_gift && _card.text.trim().isNotEmpty) 'card_message': _card.text.trim(),
        'items': items,
      });
      final order = Order.fromJson(res);

      Cart.I.clear();
      AppEvents.ordersChanged.value++;
      nav.popUntil((r) => r.isFirst);
      nav.push(MaterialPageRoute(builder: (_) => OrderDetailScreen(code: order.code)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _box({required Widget child, Color? border}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Brule.field,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border ?? Colors.white.withValues(alpha: 0.1)),
        ),
        child: child,
      );

  Widget _addressSection() {
    if (_loadingAddr) {
      return _box(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Brule.amber),
            ),
          ),
        ),
      );
    }
    final a = _addr;
    if (a == null) {
      return _box(
        border: Brule.amber.withValues(alpha: 0.45),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.location_off_outlined, color: Brule.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Belum ada alamat tersimpan.',
                      style: Brule.condensed(17)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Simpan alamat dulu, nanti dipakai otomatis tiap checkout.',
                style: Brule.mono(10)),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: _addNew,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('TAMBAH ALAMAT'),
            ),
          ],
        ),
      );
    }
    return _box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tag(a.label.toUpperCase()),
              if (a.isDefault) ...[
                const SizedBox(width: 8),
                const Tag('UTAMA', color: Brule.amber),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(a.recipient, style: Brule.condensed(18)),
          const SizedBox(height: 2),
          Text(a.phone, style: Brule.mono(11, color: Brule.amber)),
          const SizedBox(height: 8),
          Text(a.address,
              style: TextStyle(color: Brule.kraft.withValues(alpha: 0.9), height: 1.45)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
            onPressed: _pick,
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text('GANTI ALAMAT'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String k, String v, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(k, style: Brule.mono(11)),
            const Spacer(),
            Text(v, style: Brule.mono(11, color: color ?? Brule.cream)),
          ],
        ),
      );

  Widget _summary() {
    final voucher = _voucher.text.trim();
    return _box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final l in Cart.I.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${l.qty}× ${l.name}'),
                        const SizedBox(height: 2),
                        Text(l.detail, style: Brule.mono(10, color: Brule.amber)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(rupiah(l.total)),
                ],
              ),
            ),
          const Divider(height: 20),
          _summaryRow('SUBTOTAL · ${Cart.I.count} ITEM', rupiah(Cart.I.subtotal)),
          _summaryRow('ONGKIR', 'dihitung saat pesanan dibuat', color: Brule.kraft),
          _summaryRow(
            voucher.isEmpty ? 'VOUCHER' : 'VOUCHER ${voucher.toUpperCase()}',
            voucher.isEmpty ? 'tidak dipakai' : 'dicek saat pesanan dibuat',
            color: Brule.kraft,
          ),
          if (_gift)
            _summaryRow('KEMASAN KADO', 'ditambahkan saat pesanan dibuat',
                color: Brule.kraft),
          const Divider(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('TOTAL SEMENTARA', style: Brule.mono(11)),
              const Spacer(),
              Text(rupiah(Cart.I.subtotal), style: Brule.condensed(28)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Total akhir muncul di detail pesanan setelah dibuat.',
              style: Brule.mono(10)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CHECKOUT')),
      body: Narrow(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const Label('ALAMAT PENGIRIMAN'),
            _addressSection(),
            const Label('PEMBAYARAN'),
            ChipPicker<String>(
              items: const ['online', 'cod'],
              value: _payment,
              label: (p) => p == 'online' ? 'Bayar online' : 'COD (bayar di tempat)',
              onChanged: (p) => setState(() => _payment = p),
            ),
            const Label('KODE VOUCHER (OPSIONAL)'),
            TextField(
              controller: _voucher,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'contoh: HEMAT10'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _gift,
              onChanged: (v) => setState(() => _gift = v),
              activeThumbColor: Brule.amber,
              title: const Text('Bungkus kado + kartu ucapan'),
              subtitle: Text('Biaya tambahan dihitung saat pesanan dibuat.',
                  style: Brule.mono(10)),
            ),
            if (_gift)
              TextField(
                controller: _card,
                maxLength: 160,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'contoh: Selamat ulang tahun! Semoga harimu harum kopi.',
                ),
              ),
            const Label('RINGKASAN PESANAN'),
            _summary(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              ErrorBox(_error!),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Brule.cream),
                    )
                  : const Text('BUAT PESANAN'),
            ),
          ],
        ),
      ),
    );
  }
}
