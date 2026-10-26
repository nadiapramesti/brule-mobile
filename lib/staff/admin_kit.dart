import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../motion.dart';
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

/// Baris kotak ringkas dengan ukuran SERAGAM: tinggi dikunci, lebar dibagi rata,
/// jarak hanya di antara kotak sehingga sisi kiri dan kanan sejajar dengan isi halaman.
class TileRow extends StatelessWidget {
  final List<Widget> children;
  final double height;
  const TileRow({super.key, required this.children, this.height = 88});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

/// Satu kotak angka: label (maks 2 baris, tinggi tetap), nilai besar, dan catatan kecil di bawah.
/// Dipakai di dalam [TileRow]. Bisa ditekan bila [onTap] diisi.
class Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? foot;
  final bool warn;
  final bool selected;
  final VoidCallback? onTap;
  const Stat(this.label, this.value,
      {super.key, this.foot, this.warn = false, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hot = warn || selected;
    return Material(
      color: selected ? Brule.amber.withValues(alpha: 0.1) : Brule.field,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected
              ? Brule.amber
              : (warn ? Brule.amber.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.1)),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 22,
                child: Center(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Brule.mono(8.5).copyWith(height: 1.15, letterSpacing: 0.8)),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: Brule.condensed(24, color: hot ? Brule.amber : Brule.cream)),
              ),
              const SizedBox(height: 2),
              Text(foot ?? ' ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Brule.mono(8.5, color: warn ? Brule.amber : Brule.kraft)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol filter berupa kotak: label kecil + pilihan sekarang, menekan membuka daftar pilihan.
class PickField<T> extends StatelessWidget {
  final String label;
  final Map<T, String> options;
  final T value;
  final T all; // nilai "tidak difilter"
  final ValueChanged<T> onChanged;
  const PickField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.all,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = value != all;
    return Material(
      color: active ? Brule.blue.withValues(alpha: 0.18) : Brule.field,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: active ? Brule.blueText.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.16)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final r = await pickOne<T>(context, label, options, value);
          if (r != null) onChanged(r);
        },
        child: Container(
          height: 58,
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Brule.mono(9)),
                    const SizedBox(height: 2),
                    Text(options[value] ?? '-',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: Brule.condensed(16)),
                  ],
                ),
              ),
              const Icon(Icons.expand_more, color: Brule.kraft),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lembar pilihan satu dari banyak. Mengembalikan null kalau ditutup tanpa memilih.
Future<T?> pickOne<T>(BuildContext context, String title, Map<T, String> options, T value) {
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF161616),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(width: 38, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Align(alignment: Alignment.centerLeft, child: Text(title, style: Brule.mono(11))),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              children: [
                for (final e in options.entries)
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    selected: e.key == value,
                    selectedTileColor: Brule.blue.withValues(alpha: 0.2),
                    title: Text(e.value, style: Brule.condensed(17)),
                    trailing: e.key == value ? const Icon(Icons.check, color: Brule.blueText) : null,
                    onTap: () => Navigator.of(ctx).pop(e.key),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<bool> confirmDialog(BuildContext context, String title, String text,
    {String ok = 'YA', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title, style: Brule.condensed(20)),
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('BATAL')),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(96, 44),
            backgroundColor: danger ? Brule.red : null,
          ),
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
  /// Bila diisi, daftar diberi judul kelompok (mis. tanggal) tiap kali nilainya berganti.
  final String Function(Map<String, dynamic> item)? groupBy;
  const PagedList({
    super.key,
    required this.path,
    required this.params,
    required this.header,
    required this.item,
    this.empty = 'Tidak ada data.',
    this.groupBy,
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
          for (final (i, it) in _items.indexed) ...[
            if (widget.groupBy != null && (i == 0 || widget.groupBy!(_items[i - 1]) != widget.groupBy!(it)))
              GroupTitle(widget.groupBy!(it), first: i == 0),
            Reveal(index: i, child: widget.item(context, it, _refresh)),
          ],
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

/// Judul kelompok daftar (mis. HARI INI): titik aksen, garis tipis, dan ringkasan di kanan.
/// Dipakai semua daftar bergrup supaya seragam.
class GroupTitle extends StatelessWidget {
  final String text;
  final bool first;
  final String? trailing;
  const GroupTitle(this.text, {super.key, this.first = false, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: first ? 2 : 18, bottom: 10),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: Brule.amber, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(text, style: Brule.mono(10, color: Brule.cream)),
            const SizedBox(width: 10),
            Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.08))),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              Text(trailing!, style: Brule.mono(9.5)),
            ],
          ],
        ),
      );
}
