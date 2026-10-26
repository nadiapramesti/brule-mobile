import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'api.dart';
import 'auth_gate.dart';
import 'theme.dart';
import 'util.dart';
import 'widgets.dart';

/// Bintang rata-rata atau pilihan (read-only).
class Stars extends StatelessWidget {
  final double value;
  final double size;
  const Stars(this.value, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            value >= i
                ? Icons.star
                : (value >= i - 0.5 ? Icons.star_half : Icons.star_border),
            size: size,
            color: Brule.amber,
          ),
      ],
    );
  }
}

/// Ulasan pembeli di halaman detail kopi. Menulis ulasan hanya untuk yang pesanannya sudah selesai.
class ReviewsSection extends StatefulWidget {
  final String slug;
  const ReviewsSection({super.key, required this.slug});

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  int _v = 0;

  Future<Map<String, dynamic>> _load() => Api.get('/coffees/${widget.slug}/reviews');

  Future<void> _write(Map<String, dynamic>? mine) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Brule.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => _ReviewSheet(slug: widget.slug, mine: mine),
    );
    if (saved == true && mounted) {
      setState(() => _v++);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Terima kasih, ulasanmu tersimpan')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Label('ULASAN PEMBELI'),
        Loader<Map<String, dynamic>>(
          key: ValueKey('${widget.slug}|$_v|${Api.session.value}'),
          load: _load,
          builder: (context, d, reload) {
            final avg = (d['average'] as num?)?.toDouble() ?? 0;
            final count = asInt(d['count']);
            final list = ((d['data'] ?? []) as List).cast<Map<String, dynamic>>();
            final mine = d['mine'] as Map<String, dynamic>?;
            final can = d['can_review'] == true;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(count == 0 ? '–' : avg.toStringAsFixed(1),
                        style: Brule.condensed(34)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stars(avg, size: 18),
                        const SizedBox(height: 2),
                        Text(count == 0 ? 'Belum ada ulasan' : '$count ulasan',
                            style: Brule.mono(10)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (can)
                  OutlinedButton.icon(
                    onPressed: () => _write(mine),
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: Text(mine == null ? 'TULIS ULASAN' : 'UBAH ULASANMU'),
                  )
                else if (!Api.loggedIn)
                  OutlinedButton(
                    onPressed: () async {
                      if (await requireLogin(context,
                          reason: 'Masuk untuk menulis ulasan.')) {
                        if (mounted) setState(() => _v++);
                      }
                    },
                    child: const Text('MASUK UNTUK MENULIS ULASAN'),
                  )
                else
                  Text('Ulasan hanya untuk pembeli yang pesanannya sudah selesai.',
                      style: Brule.mono(10)),
                const SizedBox(height: 12),
                for (final r in list.take(10))
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Brule.field,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Brule.hair(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('${r['name']}', style: Brule.condensed(16))),
                            Stars(asInt(r['rating']).toDouble(), size: 14),
                          ],
                        ),
                        if ('${r['body'] ?? ''}'.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('${r['body']}',
                              style: TextStyle(
                                  color: Brule.kraft.withValues(alpha: 0.95), height: 1.45)),
                        ],
                        const SizedBox(height: 6),
                        Text(dateTime('${r['created_at']}'), style: Brule.mono(9)),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  final String slug;
  final Map<String, dynamic>? mine;
  const _ReviewSheet({required this.slug, this.mine});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late int _rating = asInt(widget.mine?['rating']);
  late final _body = TextEditingController(text: '${widget.mine?['body'] ?? ''}');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating < 1) {
      setState(() => _error = 'Pilih jumlah bintang dulu.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.post('/coffees/${widget.slug}/reviews', {
        'rating': _rating,
        'body': _body.text.trim(),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Ulasanmu', style: Brule.condensed(22))),
                IconButton(
                  tooltip: tr('Tutup'),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Label('NILAI'),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i bintang',
                    iconSize: 36,
                    onPressed: () => setState(() => _rating = i),
                    icon: Icon(_rating >= i ? Icons.star : Icons.star_border,
                        color: Brule.amber),
                  ),
              ],
            ),
            const Label('CERITAMU (OPSIONAL)'),
            TextField(
              controller: _body,
              maxLength: 600,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: tr('contoh: Aroma jeruknya terasa jelas, asamnya manis.'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              ErrorBox(_error!),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'MENYIMPAN...' : 'SIMPAN ULASAN'),
            ),
          ],
        ),
      ),
    );
  }
}
