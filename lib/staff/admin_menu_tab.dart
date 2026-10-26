import 'package:flutter/material.dart';
import '../motion.dart';
import '../api.dart';
import '../brand_logo.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/password_screen.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin_catalog_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_kit.dart';
import 'admin_logs_screen.dart';
import 'admin_report_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_users_screen.dart';
import 'admin_vouchers_screen.dart';

/// Menu admin: semua halaman yang ada di panel web, selain dashboard/pesanan/stok.
class AdminMenuTab extends StatelessWidget {
  const AdminMenuTab({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String, Widget)>[
      (Icons.bar_chart, 'Laporan', 'Omzet, perbandingan periode, kopi terlaris', const AdminReportScreen()),
      (Icons.groups_outlined, 'Pelanggan', 'Daftar pembeli, total belanja, langganan', const AdminCustomersScreen()),
      (Icons.manage_accounts_outlined, 'Pengguna', 'Admin, roaster, customer, blokir akun', const AdminUsersScreen()),
      (Icons.sell_outlined, 'Voucher', 'Buat, ubah, aktifkan atau matikan', const AdminVouchersScreen()),
      (Icons.star_outline, 'Ulasan', 'Sembunyikan atau hapus ulasan', const AdminReviewsScreen()),
      (Icons.coffee_outlined, 'Kopi', 'Tampilkan atau sembunyikan dari toko', const AdminCatalogScreen(coffees: true)),
      (Icons.handyman_outlined, 'Produk', 'Alat seduh dan perlengkapan', const AdminCatalogScreen(coffees: false)),
      (Icons.history, 'Log aktivitas', 'Riwayat perubahan oleh admin dan roaster', const AdminLogsScreen()),
      (Icons.settings_outlined, 'Pengaturan toko', 'Kontak, ongkir, add-on, COD, batas stok', const AdminSettingsScreen()),
    ];

    return SafeArea(
      bottom: false,
      child: Narrow(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                Container(width: 18, height: 3, color: Brule.amber),
                const SizedBox(width: 10),
                Text('MENU ADMIN', style: Brule.condensed(22, spacing: 2)),
              ],
            ),
            const SizedBox(height: 14),
            const SizedBox(height: 4),
            for (final (i, it) in items.indexed)
              Reveal(index: i, child: Panel(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: () => _open(context, it.$4),
                child: Row(
                  children: [
                    Icon(it.$1, color: Brule.amber),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.$2, style: Brule.condensed(18)),
                          const SizedBox(height: 2),
                          Text(it.$3, style: Brule.mono(9.5)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Brule.kraft),
                  ],
                ),
              )),
            const Label('AKUN SAYA'),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('${Api.user?['name'] ?? ''}', style: Brule.condensed(20)),
                      ),
                      Tag('ADMIN', color: Brule.amber),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${Api.user?['email'] ?? ''}', style: Brule.mono(10)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _open(context, const EditProfileScreen()),
                          child: const Text('EDIT PROFIL'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _open(context, const PasswordScreen()),
                          child: const Text('UBAH PASSWORD'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Brule.red),
                    onPressed: () async {
                      if (await confirmDialog(context, 'Keluar?', 'Kamu akan keluar dari akun admin.',
                          ok: 'KELUAR', danger: true)) {
                        await Api.logout();
                      }
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('KELUAR'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Center(child: BrandLogo(height: 44)),
          ],
        ),
      ),
    );
  }
}
