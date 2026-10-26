import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import '../cart.dart';
import '../motion.dart';
import 'account_tab.dart';
import 'cart_tab.dart';
import 'home_tab.dart';
import 'orders_tab.dart';
import 'shop_tab.dart';

/// Kerangka utama: navigasi bawah dengan lima tab.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeIndexed(
        index: _index,
        children: [
          HomeTab(onGo: (tab, {int seg = 0}) {
            if (tab == 1) ShopTab.segment.value = seg;
            setState(() => _index = tab);
          }),
          const ShopTab(),
          const CartTab(),
          const OrdersTab(),
          const AccountTab(),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: Cart.I,
        builder: (context, _) {
          final n = Cart.I.count;
          return NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(icon: Icon(Icons.home_outlined), label: tr('BERANDA')),
              NavigationDestination(icon: Icon(Icons.coffee_outlined), label: tr('KATALOG')),
              NavigationDestination(
                icon: Badge(
                  label: Text('$n'),
                  isLabelVisible: n > 0,
                  child: const Icon(Icons.shopping_basket_outlined),
                ),
                label: tr('KERANJANG'),
              ),
              NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined), label: tr('PESANAN')),
              NavigationDestination(icon: Icon(Icons.person_outline), label: tr('AKUN')),
            ],
          );
        },
      ),
    );
  }
}
