import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'admin_kit.dart';

const _kModes = {
  'restock': 'MASUK (RESTOCK)',
  'waste': 'KELUAR (SUSUT / RUSAK)',
  'count': 'KOREKSI HITUNG',
};

/// Form stok biji: masuk (restock), keluar (susut/rusak), atau koreksi hasil hitung fisik.
/// Mengembalikan true bila tersimpan.
Future<bool> showCoffeeStockSheet(BuildContext context, Map<String, dynamic> coffee, {String mode = 'restock'}) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFF161616),
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (_) => _CoffeeStock(coffee: coffee, mode: mode),
  );
  return r == true;
}

class _CoffeeStock extends StatefulWidget {
  final Map<String, dynamic> coffee;
  final String mode;
  const _CoffeeStock({required this.coffee, required this.mode});

  @override
  State<_CoffeeStock> createState() => _CoffeeStockState();
}

class _CoffeeStockState extends State<_CoffeeStock> {
  late String _mode = widget.mode;
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  int get _now => asInt(widget.coffee['grams']);
  int? get _n => int.tryParse(_amount.text.trim());

  int? get _after {
    final n = _n;
    if (n == null) return null;
    return switch (_mode) {
      'restock' => _now + n,
      'waste' => _now - n,
      _ => n,
    };
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.post('/admin/stock/coffees/${widget.coffee['id']}', {
        'mode': _mode,
        'amount': _n ?? _amount.text.trim(),
        'reason': _reason.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final after = _after;
    final bad = after != null && after < 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${widget.coffee['name']}', style: Brule.condensed(22)),
                    Text(_kModes[_mode] ?? '', style: Brule.mono(10, color: Brule.blueText)),
                  ],
                ),
              ),
              IconButton(tooltip: 'Tutup', icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Stok biji mentah sekarang: ${gram(_now)}', style: Brule.mono(10, color: Brule.cream)),
                  const SizedBox(height: 4),
                  Label(_mode == 'count' ? 'HASIL HITUNG FISIK (gram)' : 'JUMLAH (gram)'),
                  TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: _mode == 'count' ? 'contoh: 12500' : 'contoh: 5000',
                      counterText: '',
                    ),
                  ),
                  if (_mode == 'restock') ...[
                    const SizedBox(height: 8),
                    ChipRow(
                      children: [
                        for (final v in const [1000, 5000, 10000, 25000])
                          ActionChip(
                            label: Text('+${gram(v)}'),
                            onPressed: () => setState(() => _amount.text = '${(_n ?? 0) + v}'),
                          ),
                      ],
                    ),
                  ],
                  Label(_mode == 'waste' ? 'ALASAN (WAJIB)' : 'CATATAN (OPSIONAL)'),
                  TextField(
                    controller: _reason,
                    maxLength: 120,
                    decoration: InputDecoration(
                      hintText: switch (_mode) {
                        'restock' => 'contoh: Beli dari petani, invoice 0231',
                        'waste' => 'contoh: Kemasan sobek, biji lembap',
                        _ => 'contoh: Hasil stok opname akhir bulan',
                      },
                      counterText: '',
                    ),
                  ),
                  if (after != null) ...[
                    const SizedBox(height: 10),
                    Panel(
                      child: Row(
                        children: [
                          Text('STOK SETELAHNYA', style: Brule.mono(9.5)),
                          const Spacer(),
                          Text(gram(after),
                              style: Brule.condensed(20, color: bad ? Brule.red : Brule.cream)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_error != null) ...[const SizedBox(height: 8), ErrorBox(_error!)],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy || bad ? null : _save,
            child: Text(_busy ? 'MENYIMPAN...' : 'SIMPAN STOK'),
          ),
        ],
      ),
    );
  }
}

/// Tambah stok perlengkapan (unit).
Future<bool> showProductStockSheet(BuildContext context, Map<String, dynamic> product) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFF161616),
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
    builder: (_) => _ProductStock(product: product),
  );
  return r == true;
}

class _ProductStock extends StatefulWidget {
  final Map<String, dynamic> product;
  const _ProductStock({required this.product});

  @override
  State<_ProductStock> createState() => _ProductStockState();
}

class _ProductStockState extends State<_ProductStock> {
  final _amount = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.post('/admin/stock/products/${widget.product['id']}',
          {'amount': int.tryParse(_amount.text.trim()) ?? _amount.text.trim()});
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = asInt(widget.product['stock']);
    final n = int.tryParse(_amount.text.trim());
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('${widget.product['name']}', style: Brule.condensed(22))),
              IconButton(tooltip: 'Tutup', icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          Text('Stok sekarang: $now unit', style: Brule.mono(10, color: Brule.cream)),
          const Label('TAMBAH (unit)'),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'contoh: 12', counterText: ''),
          ),
          const SizedBox(height: 8),
          ChipRow(
            children: [
              for (final v in const [5, 10, 25, 50])
                ActionChip(
                  label: Text('+$v'),
                  onPressed: () => setState(() => _amount.text = '${(n ?? 0) + v}'),
                ),
            ],
          ),
          if (n != null) ...[
            const SizedBox(height: 10),
            Panel(
              child: Row(
                children: [
                  Text('STOK SETELAHNYA', style: Brule.mono(9.5)),
                  const Spacer(),
                  Text('${now + n} unit', style: Brule.condensed(20)),
                ],
              ),
            ),
          ],
          if (_error != null) ...[const SizedBox(height: 8), ErrorBox(_error!)],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'MENYIMPAN...' : 'TAMBAH STOK'),
          ),
        ],
      ),
    );
  }
}
