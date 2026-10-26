import 'package:flutter/material.dart' hide Text;
import '../api.dart';
import '../i18n.dart';
import '../widgets.dart';
import '../staff/admin_kit.dart';
import '../theme.dart';
import 'order_detail_screen.dart';

/// Lacak pesanan lewat kode (BRL-TANGGAL-NOMOR) tanpa perlu masuk, sama seperti halaman Lacak di web.
class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final c = _code.text.trim().toUpperCase();
    if (c.isEmpty) {
      setState(() => _error = 'Isi kode pesanan dulu, contoh: BRL-20261026-0001');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.get('/track/$c');
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(code: c, publicView: true)),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Lacak pesanan',
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                Text('Masukkan kode pesanan dari email atau struk. Tidak perlu masuk akun.',
                    style: TextStyle(color: Brule.cream, fontSize: 14, height: 1.5)),
                const SizedBox(height: 18),
                TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _go(),
                  decoration: InputDecoration(hintText: tr('contoh: BRL-20261026-0001'), prefixIcon: const Icon(Icons.local_shipping_outlined)),
                ),
              ],
            ),
          ),
          BottomBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: ErrorBox(_error!)),
                FilledButton.icon(
                  onPressed: _busy ? null : _go,
                  icon: const Icon(Icons.search, size: 18),
                  label: Text(_busy ? 'MENCARI...' : 'LACAK'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
