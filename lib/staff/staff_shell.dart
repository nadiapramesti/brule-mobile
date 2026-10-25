import 'package:flutter/material.dart';
import '../brand_logo.dart';
import '../screens/account_tab.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin_dashboard_tab.dart';
import 'admin_menu_tab.dart';
import 'admin_orders_tab.dart';
import 'admin_stock_tab.dart';
import 'queue_tab.dart';

/// Kerangka untuk akun roaster (antrian, akun) dan admin (dashboard, pesanan, antrian, stok, menu).
class StaffShell extends StatefulWidget {
  final bool admin;
  const StaffShell({super.key, required this.admin});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final admin = widget.admin;
    final pages = <Widget>[
      if (admin) const AdminDashboardTab(),
      if (admin) const AdminOrdersTab(),
      const QueueTab(),
      if (admin) const AdminStockTab(),
      admin ? const AdminMenuTab() : const AccountTab(),
    ];
    final dest = <NavigationDestination>[
      if (admin)
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'DASHBOARD'),
      if (admin)
        const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'PESANAN'),
      const NavigationDestination(icon: Icon(Icons.local_fire_department_outlined), label: 'ANTRIAN'),
      if (admin)
        const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'STOK'),
      admin
          ? const NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'MENU')
          : const NavigationDestination(icon: Icon(Icons.person_outline), label: 'AKUN'),
    ];

    // Bar logo di atas semua tab; SafeArea di sini membuat tab di bawahnya tidak menambah jarak ulang.
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  const BrandLogo(height: 28),
                  const Spacer(),
                  Tag(admin ? 'ADMIN' : 'ROASTER', color: admin ? Brule.amber : Brule.blueText),
                ],
              ),
            ),
            Expanded(child: IndexedStack(index: _i, children: pages)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: dest,
      ),
    );
  }
}
