import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import '../cart.dart';
import '../external_link.dart';
import '../motion.dart';
import '../store_info.dart';
import '../util.dart';
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

  void _jump() {
    final t = AppEvents.goTab.value;
    if (t == null) return;
    AppEvents.goTab.value = null;
    if (mounted) setState(() => _index = t);
  }

  @override
  void initState() {
    super.initState();
    AppEvents.goTab.addListener(_jump);
  }

  @override
  void dispose() {
    AppEvents.goTab.removeListener(_jump);
    super.dispose();
  }

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
      // Di tab keranjang tombol chat disembunyikan supaya tidak menutupi tombol CHECKOUT.
      floatingActionButton: _index == 2 ? null : const _ChatFab(),
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

/// Tombol chat WhatsApp toko yang mengambang. Nomornya dari Pengaturan toko (GET /store);
/// tombol baru muncul setelah nomor berhasil dimuat.
class _ChatFab extends StatefulWidget {
  const _ChatFab();

  @override
  State<_ChatFab> createState() => _ChatFabState();
}

class _ChatFabState extends State<_ChatFab> {
  @override
  void initState() {
    super.initState();
    StoreInfo.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final number = StoreInfo.whatsapp;
    if (number == null) return const SizedBox.shrink();
    return FloatingActionButton.extended(
      heroTag: 'wa_chat',
      onPressed: () => openExternal(context, waUri(number, 'Halo BRÛLÉ, saya mau tanya soal kopi.')),
      icon: const Icon(Icons.chat_outlined),
      label: const Text('CHAT WA'),
    );
  }
}
