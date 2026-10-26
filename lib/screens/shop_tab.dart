import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import 'catalog_tab.dart';
import 'gear_tab.dart';

/// Katalog: kopi dan perlengkapan dalam satu tab, dipisah segmen di atas.
class ShopTab extends StatefulWidget {
  const ShopTab({super.key});

  /// Segmen aktif (0 kopi, 1 perlengkapan); diubah dari beranda lewat pintasan.
  static final segment = ValueNotifier<int>(0);

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  int _seg = 0;

  @override
  void initState() {
    super.initState();
    _seg = ShopTab.segment.value;
    ShopTab.segment.addListener(_sync);
  }

  void _sync() => setState(() => _seg = ShopTab.segment.value);

  @override
  void dispose() {
    ShopTab.segment.removeListener(_sync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 0, label: Text('KOPI'), icon: Icon(Icons.coffee_outlined)),
                  ButtonSegment(
                      value: 1,
                      label: Text('PERLENGKAPAN'),
                      icon: Icon(Icons.coffee_maker_outlined)),
                ],
                selected: {_seg},
                onSelectionChanged: (s) => ShopTab.segment.value = s.first,
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _seg,
              children: const [CatalogTab(), GearTab()],
            ),
          ),
        ],
      ),
    );
  }
}
