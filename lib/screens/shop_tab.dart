import 'package:flutter/material.dart';
import 'catalog_tab.dart';
import 'gear_tab.dart';

/// Katalog: kopi dan perlengkapan dalam satu tab, dipisah segmen di atas.
class ShopTab extends StatefulWidget {
  const ShopTab({super.key});

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  int _seg = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
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
                onSelectionChanged: (s) => setState(() => _seg = s.first),
              ),
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
    );
  }
}
