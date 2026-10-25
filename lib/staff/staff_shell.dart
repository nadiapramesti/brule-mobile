import 'package:flutter/material.dart';
import '../screens/account_tab.dart';
import 'admin_dashboard_tab.dart';
import 'admin_orders_tab.dart';
import 'admin_stock_tab.dart';
import 'queue_tab.dart';

/// Kerangka untuk akun roaster (antrian) dan admin (dashboard, pesanan, antrian, stok).
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
      const AccountTab(),
    ];
    final dest = <NavigationDestination>[
      if (admin)
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'DASHBOARD'),
      if (admin)
        const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'PESANAN'),
      const NavigationDestination(icon: Icon(Icons.local_fire_department_outlined), label: 'ANTRIAN'),
      if (admin)
        const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'STOK'),
      const NavigationDestination(icon: Icon(Icons.person_outline), label: 'AKUN'),
    ];

    return Scaffold(
      body: IndexedStack(index: _i, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: dest,
      ),
    );
  }
}
