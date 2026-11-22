import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import '../add_sheet.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

/// Kuis tiga pertanyaan "Temukan kopimu": jawaban dikirim ke server (logika sama dengan web),
/// hasilnya tiga kopi + level sangrai, tinggal lanjut ke pilihan racikan.
class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

/// Kunci jawaban harus sama dengan yang diterima POST /recommend.
const _questions = <({String key, String title, List<(String, String)> options})>[
  (
    key: 'drink',
    title: 'Biasanya kamu minum kopi seperti apa?',
    options: [('hitam', 'Hitam, tanpa susu'), ('susu', 'Pakai susu atau gula')],
  ),
  (
    key: 'taste',
    title: 'Rasa mana yang paling kamu suka?',
    options: [
      ('buah', 'Buah segar: jeruk, beri'),
      ('bunga', 'Harum bunga, ringan seperti teh'),
      ('cokelat', 'Cokelat dan manis'),
      ('kacang', 'Kacang dan rempah, pekat'),
    ],
  ),
  (
    key: 'acid',
    title: 'Seberapa suka rasa asam yang segar?',
    options: [
      ('suka', 'Suka, makin segar makin enak'),
      ('sedikit', 'Sedikit saja'),
      ('tidak', 'Tidak suka, pilih yang mantap'),
    ],
  ),
];

class _RecommendScreenState extends State<RecommendScreen> {
  final Map<String, String> _answers = {};
  int _step = 0;
  bool _loading = false;
  String? _error;
  List<Recommendation>? _results;
  String? _opening;

  Future<void> _answer(String value) async {
    _answers[_questions[_step].key] = value;
    if (_step < _questions.length - 1) {
      setState(() => _step++);
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await Api.post('/recommend', _answers);
      final list = ((r['data'] ?? []) as List)
          .map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _results = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _back() {
    if (_error != null) {
      setState(() => _error = null);
      return;
    }
    setState(() {
      if (_results != null) {
        _results = null;
        _step = _questions.length - 1;
      } else if (_step > 0) {
        _step--;
      }
    });
  }

  void _restart() => setState(() {
        _answers.clear();
        _step = 0;
        _results = null;
        _error = null;
      });

  /// Buka pilihan racikan dengan kopi dan level dari hasil kuis sudah terpilih.
  Future<void> _brew(Recommendation r) async {
    setState(() => _opening = r.slug);
    try {
      final j = await Api.get('/coffees/${r.slug}');
      if (!mounted) return;
      await addCoffeeSheet(context, Coffee.fromJson(j), level: r.level);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TEMUKAN KOPIMU')),
      body: Narrow(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null) ...[
              ErrorBox(_error!),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('COBA LAGI'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('UBAH JAWABAN'),
              ),
            ] else if (_results != null)
              ..._resultViews()
            else
              ..._questionViews(),
          ],
        ),
      ),
    );
  }

  List<Widget> _questionViews() {
    final q = _questions[_step];
    return [
      Text('PERTANYAAN ${_step + 1} / ${_questions.length}', style: Brule.mono(11, color: Brule.amber)),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: (_step + 1) / _questions.length,
        minHeight: 4,
        color: Brule.amber,
        backgroundColor: Brule.hair(0.12),
      ),
      const SizedBox(height: 22),
      Text(q.title, style: Brule.condensed(26)),
      const SizedBox(height: 18),
      for (final (value, label) in q.options) ...[
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          onPressed: () => _answer(value),
          child: Text(label),
        ),
        const SizedBox(height: 10),
      ],
      if (_step > 0) ...[
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('KEMBALI'),
        ),
      ],
    ];
  }

  List<Widget> _resultViews() {
    final list = _results!;
    return [
      Text('COCOK UNTUKMU', style: Brule.mono(11, color: Brule.amber)),
      const SizedBox(height: 8),
      Text('Tiga kopi pilihan', style: Brule.condensed(26)),
      const SizedBox(height: 16),
      if (list.isEmpty)
        const ErrorBox('Belum ada kopi yang cocok. Coba jawaban lain.')
      else
        for (final r in list) _ResultCard(r: r, busy: _opening == r.slug, onBrew: () => _brew(r)),
      const SizedBox(height: 6),
      OutlinedButton.icon(
        onPressed: _restart,
        icon: const Icon(Icons.replay, size: 18),
        label: const Text('ULANGI KUIS'),
      ),
    ];
  }
}

class _ResultCard extends StatelessWidget {
  final Recommendation r;
  final bool busy;
  final VoidCallback onBrew;
  const _ResultCard({required this.r, required this.busy, required this.onBrew});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Brule.field,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Brule.hair(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(width: 72, height: 72, child: NetImage(url: r.image)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: Brule.condensed(20)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [Tag(r.levelLabel.toUpperCase(), color: Brule.amber)],
                    ),
                    const SizedBox(height: 6),
                    Text('${rupiah(r.pricePer100g)} / 100 g',
                        style: TextStyle(color: Brule.kraft.withValues(alpha: 0.9), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (r.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(r.notes.join(' · '), style: Brule.mono(11, color: Brule.amber)),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: busy ? null : onBrew,
            icon: busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.coffee_maker_outlined, size: 18),
            label: const Text('RACIK KOPI INI'),
          ),
        ],
      ),
    );
  }
}
