import 'dart:async';
import 'package:flutter/material.dart';
import 'theme.dart';

/// Gambar jaringan dengan cadangan bila kosong atau gagal dimuat.
class NetImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  const NetImage({super.key, this.url, this.fit = BoxFit.cover});

  Widget _placeholder() => Container(
        color: Brule.field,
        alignment: Alignment.center,
        child: Icon(Icons.coffee_outlined,
            size: 40, color: Brule.kraft.withValues(alpha: 0.35)),
      );

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return _placeholder();
    return Image.network(
      u,
      fit: fit,
      errorBuilder: (context, error, stack) => _placeholder(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(),
    );
  }
}

class ErrorBox extends StatelessWidget {
  final String text;
  const ErrorBox(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Brule.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Brule.red.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: const TextStyle(color: Brule.red)),
    );
  }
}

class Tag extends StatelessWidget {
  final String text;
  final Color color;
  final bool filled;
  const Tag(this.text, {super.key, this.color = Brule.kraft, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF121212).withValues(alpha: 0.88) : null,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(text, style: Brule.mono(10, color: color)),
    );
  }
}

class Label extends StatelessWidget {
  final String text;
  const Label(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(text, style: Brule.mono(11)),
      );
}

class ChipPicker<T> extends StatelessWidget {
  final List<T> items;
  final T? value;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  const ChipPicker({
    super.key,
    required this.items,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ChipRow(
      children: [
        for (final i in items)
          ChoiceChip(
            label: Text(label(i)),
            selected: i == value,
            onSelected: (_) => onChanged(i),
          ),
      ],
    );
  }
}

/// Deretan pilihan SATU BARIS yang tidak pernah melebihi layar. Kalau isinya lebih panjang
/// dari layar, bisa digeser dan muncul tombol panah (>) di tepi untuk menunjukkan masih ada lanjutannya.
class ChipRow extends StatefulWidget {
  final List<Widget> children;
  final double gap;
  final EdgeInsets padding;
  final Color? fade;
  const ChipRow({
    super.key,
    required this.children,
    this.gap = 8,
    this.padding = EdgeInsets.zero,
    this.fade,
  });

  @override
  State<ChipRow> createState() => _ChipRowState();
}

class _ChipRowState extends State<ChipRow> {
  final _c = ScrollController();
  bool _left = false;
  bool _right = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_measure);
    _later();
  }

  @override
  void didUpdateWidget(covariant ChipRow old) {
    super.didUpdateWidget(old);
    _later();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _later() => WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

  void _measure() {
    if (!mounted || !_c.hasClients) return;
    final p = _c.position;
    final l = p.pixels > 4;
    final r = p.pixels < p.maxScrollExtent - 4;
    if (l != _left || r != _right) {
      setState(() {
        _left = l;
        _right = r;
      });
    }
  }

  void _nudge(double dir) {
    final p = _c.position;
    final to = (p.pixels + dir * p.viewportDimension * 0.6).clamp(0.0, p.maxScrollExtent);
    _c.animateTo(to, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  Widget _edge(bool left, bool show, Color fade) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: IgnorePointer(
        ignoring: !show,
        child: AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 52,
            alignment: left ? Alignment.centerLeft : Alignment.centerRight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: left ? Alignment.centerLeft : Alignment.centerRight,
                end: left ? Alignment.centerRight : Alignment.centerLeft,
                colors: [fade, fade.withValues(alpha: 0)],
              ),
            ),
            child: Material(
              color: Brule.blue,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _nudge(left ? -1 : 1),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(left ? Icons.chevron_left : Icons.chevron_right, size: 22, color: Brule.cream),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kids = widget.children;
    final fade = widget.fade ??
        (context.findAncestorWidgetOfExactType<BottomSheet>() != null ? const Color(0xFF161616) : Brule.bg);
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _later();
        return false;
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _c,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: widget.padding,
            child: Row(
              children: [
                for (var i = 0; i < kids.length; i++) ...[
                  if (i > 0) SizedBox(width: widget.gap),
                  kids[i],
                ],
              ],
            ),
          ),
          _edge(true, _left, fade),
          _edge(false, _right, fade),
        ],
      ),
    );
  }
}

/// Beberapa tombol sejajar satu baris dengan lebar sama (aman dipakai walau tema tombol penuh lebar).
class ButtonRow extends StatelessWidget {
  final List<Widget> children;
  const ButtonRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class QtyStepper extends StatelessWidget {
  final int qty;
  final ValueChanged<int> onChanged;
  const QtyStepper({super.key, required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Kurangi',
            onPressed: () => onChanged(qty - 1),
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 28,
            child: Text('$qty',
                textAlign: TextAlign.center, style: Brule.mono(15, color: Brule.cream)),
          ),
          IconButton(
            tooltip: 'Tambah',
            onPressed: qty >= 20 ? null : () => onChanged(qty + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String? image;
  final String title;
  final String meta;
  final String price;
  final bool soldOut;
  final VoidCallback onTap;
  final Widget? art;
  final VoidCallback? onAdd;
  const ProductCard({
    super.key,
    this.art,
    this.onAdd,
    required this.image,
    required this.title,
    required this.meta,
    required this.price,
    required this.soldOut,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Brule.field,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (image == null || image!.isEmpty) && art != null
                      ? art!
                      : NetImage(url: image),
                  if (soldOut)
                    const Positioned(top: 8, left: 8, child: Tag('HABIS', color: Brule.red, filled: true)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Brule.condensed(17)),
                    const SizedBox(height: 6),
                    Text(meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Brule.mono(10, color: Brule.amber)),
                    const SizedBox(height: 4),
                    Text(price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Brule.kraft.withValues(alpha: 0.9), fontSize: 13)),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: soldOut ? null : onAdd,
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: Text(soldOut ? 'HABIS' : 'TAMBAH'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: Brule.condensed(14, spacing: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kotak cari dengan jeda ketik supaya server tidak dipanggil tiap huruf.
class SearchBox extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchBox({super.key, required this.hint, required this.onChanged});

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  final _c = TextEditingController();
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _typed(String v) {
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 450), () => widget.onChanged(v.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      onChanged: (v) {
        setState(() {});
        _typed(v);
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _c.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus',
                icon: const Icon(Icons.close),
                onPressed: () {
                  _c.clear();
                  setState(() {});
                  widget.onChanged('');
                },
              ),
      ),
    );
  }
}

/// Memuat data sekali, menampilkan loading / error / hasil, dan bisa dimuat ulang.
class Loader<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext, T, Future<void> Function() reload) builder;
  const Loader({super.key, required this.load, required this.builder});

  @override
  State<Loader<T>> createState() => _LoaderState<T>();
}

class _LoaderState<T> extends State<Loader<T>> {
  late Future<T> _f;

  @override
  void initState() {
    super.initState();
    _f = widget.load();
  }

  Future<void> _reload() async {
    final f = widget.load();
    setState(() => _f = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _f,
      builder: (context, snap) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.loose,
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: KeyedSubtree(
          key: ValueKey(snap.connectionState != ConnectionState.done ? 'load' : (snap.hasError ? 'err' : 'ok')),
          child: _body(context, snap),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AsyncSnapshot<T> snap) {
    if (snap.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator(color: Brule.amber));
    }
    if (snap.hasError) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ErrorBox('${snap.error}'),
                const SizedBox(height: 16),
                OutlinedButton(onPressed: _reload, child: const Text('COBA LAGI')),
              ],
            ),
          ),
        ),
      );
    }
    return widget.builder(context, snap.data as T, _reload);
  }
}

/// Batasi lebar isi di layar lebar (tablet) supaya tidak melar.
class Narrow extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const Narrow({super.key, required this.child, this.maxWidth = 720});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

Color statusColor(String status) {
  switch (status) {
    case 'pending_payment':
      return Brule.amber;
    case 'cancelled':
      return Brule.red;
    case 'completed':
      return Brule.blueText;
    default:
      return Brule.kraft;
  }
}
