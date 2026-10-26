import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import '../prefs.dart';
import '../api.dart';
import '../cart.dart';
import '../theme.dart';
import '../widgets.dart';
import 'addresses_screen.dart';
import 'edit_profile_screen.dart';
import '../auth_gate.dart';
import 'password_screen.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  Future<void> _open(Widget screen, [String? doneMessage]) async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    setState(() {});
    if (ok == true && doneMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(doneMessage)));
    }
  }

  Future<void> _logout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Brule.field,
        title: Text('Keluar dari akun?', style: Brule.condensed(20)),
        content: const Text('Keranjang di perangkat ini ikut dikosongkan.'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('BATAL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('KELUAR'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await Api.logout();
    Cart.I.clear();
    AppEvents.ordersChanged.value++;
  }

  Widget _guest() {
    return SafeArea(
      bottom: false,
      child: Narrow(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                Container(width: 18, height: 3, color: Brule.amber),
                const SizedBox(width: 10),
                Text('AKUN', style: Brule.condensed(22, spacing: 2)),
              ],
            ),
            const SizedBox(height: 32),
            Icon(Icons.account_circle_outlined,
                size: 64, color: Brule.kraft.withValues(alpha: 0.45)),
            const SizedBox(height: 14),
            Center(child: Text('Belum masuk', style: Brule.condensed(24))),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Masuk untuk belanja, memantau pesanan,\ndan menyimpan alamat pengiriman.',
                textAlign: TextAlign.center,
                style: Brule.mono(11),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => requireLogin(context),
              child: const Text('MASUK'),
            ),
            const SizedBox(height: 28),
            Center(child: Text('BRÛLÉ · SPECIALTY COFFEE LAB', style: Brule.mono(10))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Api.session,
      builder: (context, _, _) => Api.loggedIn ? _profile() : _guest(),
    );
  }

  Widget _profile() {
    final u = Api.user ?? {};
    final name = '${u['name'] ?? ''}';
    final phone = u['phone'];

    return SafeArea(
      bottom: false,
      child: Narrow(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                Container(width: 18, height: 3, color: Brule.amber),
                const SizedBox(width: 10),
                Text('AKUN', style: Brule.condensed(22, spacing: 2)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Brule.field,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Brule.hair(0.1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Brule.blue,
                    child: Text(
                      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                      style: Brule.condensed(26, color: Brule.paper),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Brule.condensed(22)),
                        const SizedBox(height: 2),
                        Text('${u['email'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Brule.mono(11)),
                        if (u['role'] == 'admin' || u['role'] == 'roaster') ...[
                          const SizedBox(height: 6),
                          Tag('${u['role']}'.toUpperCase(), color: Brule.amber),
                        ],
                        if (phone != null) ...[
                          const SizedBox(height: 2),
                          Text('$phone', style: Brule.mono(11, color: Brule.amber)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _Tile(
              icon: Icons.person_outline,
              title: 'Edit profil',
              subtitle: 'Nama, email, nomor WhatsApp',
              onTap: () => _open(const EditProfileScreen(), 'Profil diperbarui'),
            ),
            if (u['role'] == null || u['role'] == 'customer')
              _Tile(
                icon: Icons.location_on_outlined,
                title: 'Buku alamat',
                subtitle: 'Simpan hingga $kMaxAddresses alamat pengiriman',
                onTap: () => _open(const AddressesScreen()),
              ),
            _Tile(
              icon: Icons.lock_outline,
              title: 'Ubah password',
              subtitle: 'Ganti password akunmu',
              onTap: () => _open(const PasswordScreen(), 'Password diubah'),
            ),
            const Label('TAMPILAN DAN BAHASA'),
            const ThemeSwitch(),
            const SizedBox(height: 8),
            const LangSwitch(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Brule.red,
                side: BorderSide(color: Brule.red.withValues(alpha: 0.6)),
              ),
              onPressed: _logout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('KELUAR'),
            ),
            const SizedBox(height: 24),
            Center(child: Text('BRÛLÉ · SPECIALTY COFFEE LAB', style: Brule.mono(10))),
            const SizedBox(height: 4),
            Center(child: Text('SERVER ${Api.base}', style: Brule.mono(9))),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Brule.field,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Brule.hair(0.1)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Brule.blue.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Brule.blueText.withValues(alpha: 0.25)),
                  ),
                  child: Icon(icon, color: Brule.blueText),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Brule.condensed(18)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: Brule.mono(10)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
