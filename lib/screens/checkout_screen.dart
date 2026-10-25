import 'package:flutter/material.dart';
import '../api.dart';
import '../cart.dart';
import '../models.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'order_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _name = TextEditingController(text: '${Api.user?['name'] ?? ''}');
  final _phone = TextEditingController(text: '${Api.user?['phone'] ?? ''}');
  final _address = TextEditingController();
  final _voucher = TextEditingController();
  final _card = TextEditingController();
  String _payment = 'online';
  bool _gift = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _voucher.dispose();
    _card.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'Nama penerima wajib diisi.';
    if (!RegExp(r'^(\+62|62|0)8[0-9]{7,12}$').hasMatch(_phone.text.trim())) {
      return 'Nomor WhatsApp tidak valid. Contoh: 0812xxxxxxxx';
    }
    if (_address.text.trim().length < 15) {
      return 'Alamat terlalu pendek. Tulis jalan, nomor, kota, dan kode pos.';
    }
    return null;
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
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
                }
              : {
                  'type': 'gear',
                  'product_id': l.refId,
                  'option': l.option,
                  'qty': l.qty,
                })
          .toList();

      final res = await Api.post('/orders', {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CHECKOUT')),
      body: Narrow(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const Label('NAMA PENERIMA'),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'contoh: Nadia Pramesti'),
            ),
            const Label('NOMOR WHATSAPP'),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'contoh: 081234567890'),
            ),
            const Label('ALAMAT PENGIRIMAN'),
            TextField(
              controller: _address,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'contoh: Jl. Melati No. 5, Karawang, 41361',
              ),
            ),
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
            if (_error != null) ...[
              const SizedBox(height: 12),
              ErrorBox(_error!),
            ],
            const SizedBox(height: 16),
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
            const Label('RINGKASAN'),
            for (final l in Cart.I.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${l.qty}× ${l.name}'),
                          Text(l.detail, style: Brule.mono(10, color: Brule.amber)),
                        ],
                      ),
                    ),
                    Text(rupiah(l.total)),
                  ],
                ),
              ),
            const Divider(),
            Row(
              children: [
                Text('Subtotal', style: Brule.mono(12)),
                const Spacer(),
                Text(rupiah(Cart.I.subtotal), style: Brule.condensed(20)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Ongkir, diskon voucher, dan biaya kado dihitung server saat pesanan dibuat.',
                style: Brule.mono(10)),
          ],
        ),
      ),
    );
  }
}
