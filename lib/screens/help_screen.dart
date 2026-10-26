import 'package:flutter/material.dart' hide Text;
import '../api.dart';
import '../i18n.dart';
import '../settings_screen.dart';
import '../staff/admin_kit.dart';
import '../theme.dart';
import '../widgets.dart';

const _helpTitles = {
  'faq': 'Bantuan (FAQ)',
  'shipping': 'Pengiriman dan pengembalian',
  'terms': 'Syarat dan ketentuan',
  'privacy': 'Kebijakan privasi',
};

/// Bantuan: FAQ (pertanyaan bisa dibuka satu per satu dan dicari) serta halaman kebijakan.
/// Isinya diambil dari API, sama dengan halaman Bantuan di web, dan mengikuti bahasa aplikasi.
class HelpScreen extends StatefulWidget {
  final String page;
  const HelpScreen({super.key, this.page = 'faq'});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _q = '';

  bool _hit(Map i) =>
      _q.isEmpty || '${i['q']} ${i['a']}'.toLowerCase().contains(_q.toLowerCase());

  void _open(String page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => HelpScreen(page: page)));

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: _helpTitles[widget.page] ?? 'Bantuan',
      child: Loader<Map<String, dynamic>>(
        load: () async => ((await Api.get('/help/${widget.page}'))['data'] ?? {}) as Map<String, dynamic>,
        builder: (context, d, reload) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            if ('${d['intro'] ?? ''}'.isNotEmpty)
              Text('${d['intro']}', style: TextStyle(color: Brule.cream, fontSize: 14, height: 1.5)),
            if (d['updated'] != null) ...[
              const SizedBox(height: 6),
              Text('${d['updated']}', style: Brule.mono(10)),
            ],
            if (d['groups'] != null) ..._faq(d) else ..._sections(d),
            if (widget.page == 'faq') ...[
              const SettingHeader('LAINNYA'),
              SettingGroup(children: [
                for (final e in _helpTitles.entries)
                  if (e.key != 'faq')
                    SettingRow(
                      icon: switch (e.key) {
                        'shipping' => Icons.local_shipping_outlined,
                        'terms' => Icons.description_outlined,
                        _ => Icons.privacy_tip_outlined,
                      },
                      title: e.value,
                      value: 'Sama dengan di web',
                      onTap: () => _open(e.key),
                    ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _faq(Map<String, dynamic> d) {
    final groups = (d['groups'] as List).cast<Map>();
    return [
      const SizedBox(height: 14),
      SearchBox(hint: 'cari pertanyaan, contoh: COD', onChanged: (v) => setState(() => _q = v)),
      for (final g in groups) ...[
        if (((g['items'] as List).cast<Map>()).any(_hit)) ...[
          SettingHeader('${g['title']}'.toUpperCase()),
          SettingGroup(children: [
            for (final i in (g['items'] as List).cast<Map>().where(_hit))
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: PageStorageKey('${i['q']}$_q'),
                  initiallyExpanded: _q.isNotEmpty,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  expandedAlignment: Alignment.centerLeft,
                  iconColor: Brule.amber,
                  collapsedIconColor: Brule.kraft,
                  title: Text('${i['q']}', style: Brule.condensed(16)),
                  children: [
                    Text('${i['a']}', style: TextStyle(color: Brule.cream.withValues(alpha: 0.88), fontSize: 13.5, height: 1.55)),
                  ],
                ),
              ),
          ]),
        ],
      ],
      if (_q.isNotEmpty && !groups.any((g) => ((g['items'] as List).cast<Map>()).any(_hit))) ...[
        const SizedBox(height: 28),
        Center(child: Text('Pertanyaan tidak ditemukan.', style: Brule.mono(11))),
      ],
    ];
  }

  List<Widget> _sections(Map<String, dynamic> d) {
    final sections = ((d['sections'] ?? []) as List).cast<Map>();
    return [
      for (final s in sections) ...[
        SettingHeader('${s['h']}'.toUpperCase()),
        for (final p in ((s['p'] ?? []) as List))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('$p', style: TextStyle(color: Brule.cream.withValues(alpha: 0.9), fontSize: 13.5, height: 1.55)),
          ),
        for (final li in ((s['li'] ?? []) as List))
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 10),
                  child: Container(width: 5, height: 5, decoration: BoxDecoration(color: Brule.amber, shape: BoxShape.circle)),
                ),
                Expanded(child: Text('$li', style: TextStyle(color: Brule.cream.withValues(alpha: 0.9), fontSize: 13.5, height: 1.5))),
              ],
            ),
          ),
      ],
    ];
  }
}
