import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

/// Kerangka layar admin (AppBar + isi sempit di tablet).
class AdminPage extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? fab;
  const AdminPage({super.key, required this.title, required this.child, this.actions, this.fab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, style: Brule.condensed(22)), actions: actions),
      floatingActionButton: fab,
      body: SafeArea(top: false, child: Narrow(maxWidth: 720, child: child)),
    );
  }
}

/// Kartu isi dengan garis tipis.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Brule.field,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: child,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: onTap == null
          ? box
          : Material(
              color: Colors.transparent,
              child: InkWell(borderRadius: BorderRadius.circular(10), onTap: onTap, child: box),
            ),
    );
  }
}

/// Angka ringkas (label kecil + nilai besar) untuk baris statistik.
class Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool warn;
  const Stat(this.label, this.value, {super.key, this.warn = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Brule.field,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Brule.mono(8.5)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: Brule.condensed(20, color: warn ? Brule.amber : Brule.cream)),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmDialog(BuildContext context, String title, String text,
    {String ok = 'YA', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1C1C1C),
      title: Text(title, style: Brule.condensed(20)),
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('BATAL')),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: Brule.red) : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return r == true;
}

void toast(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

/// Jalankan aksi API; tampilkan pesan error bila gagal. Mengembalikan true bila sukses.
Future<bool> runAction(BuildContext context, Future<void> Function() action, {String? done}) async {
  try {
    await action();
    if (context.mounted && done != null) toast(context, done);
    return true;
  } on ApiException catch (e) {
    if (context.mounted) toast(context, e.message);
    return false;
  }
}

/// Daftar berhalaman: ambil halaman berikutnya lewat tombol MUAT LAGI.
/// [header] dibangun ulang dari respons halaman pertama (untuk statistik/jumlah tab).
class PagedList extends StatefulWidget {
  final String path;
  final Map<String, String> params;
  final Widget Function(Map<String, dynamic>? meta) header;
  final Widget Function(BuildContext, Map<String, dynamic> item, Future<void> Function() refresh) item;
  final String empty;
  const PagedList({
    super.key,
    required this.path,
    required this.params,
    required this.header,
    required this.item,
    this.empty = 'Tidak ada data.',
  });

  @override
  State<PagedList> createState() => _PagedListState();
}

class _PagedListState extends State<PagedList> {
  final List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _meta;
  int _page = 0;
  int _last = 1;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);
  }

  Future<void> _fetch({bool reset = false}) async {
    if (_loading) return;
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
      final res = await Api.get(widget.path, {...widget.params, 'page': '${_page + 1}'});
      if (!mounted) return;
      setState(() {
        if (_page == 0) _meta = res;
        _items.addAll(((res['data'] ?? []) as List).cast<Map<String, dynamic>>());
        _page = (res['page'] as num?)?.toInt() ?? _page + 1;
        _last = (res['last_page'] as num?)?.toInt() ?? 1;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() => _fetch(reset: true);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Brule.amber,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          widget.header(_meta),
          const SizedBox(height: 10),
          if (_error != null) ErrorBox(_error!),
          if (!_loading && _error == null && _items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text(widget.empty, style: Brule.mono(11))),
            ),
          for (final it in _items) widget.item(context, it, _refresh),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(color: Brule.amber)),
            )
          else if (_page < _last && _error == null)
            OutlinedButton(onPressed: _fetch, child: const Text('MUAT LAGI')),
        ],
      ),
    );
  }
}

/// Bar tombol yang menempel di bawah layar (jempol gampang jangkau).
class BottomBar extends StatelessWidget {
  final Widget child;
  const BottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: child,
    );
  }
}

/// 12300 -> "12.300 g"
String gram(int v) {
  final neg = v < 0;
  final s = v.abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return '${neg ? '-' : ''}$s g';
}
