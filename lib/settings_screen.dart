import 'package:flutter/material.dart' hide Text;
import 'i18n.dart';
import 'prefs.dart';
import 'staff/admin_kit.dart';
import 'staff/admin_settings_screen.dart';
import 'theme.dart';

/// Pengaturan seperti aplikasi pada umumnya: daftar berkelompok, tiap baris menampilkan nilainya,
/// ketuk untuk mengubah. Admin juga melihat kelompok TOKO (data toko yang sama dengan di web).
class SettingsScreen extends StatelessWidget {
  final bool admin;
  const SettingsScreen({super.key, this.admin = false});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppPrefs.light, AppPrefs.lang]),
      builder: (context, _) => AdminPage(
        title: 'Pengaturan',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            const SettingHeader('TAMPILAN'),
            SettingGroup(children: [
              SettingRow(
                icon: Brule.light ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                title: 'Tema',
                value: Brule.light ? 'Terang' : 'Gelap',
                onTap: () async {
                  final v = await showChoiceSheet<bool>(
                    context,
                    title: 'Tema',
                    current: Brule.light,
                    options: const {
                      false: ('Gelap', 'Latar hitam, nyaman di ruangan redup', Icons.dark_mode_outlined),
                      true: ('Terang', 'Latar krem seperti kertas lab', Icons.light_mode_outlined),
                    },
                  );
                  if (v != null) AppPrefs.setLight(v);
                },
              ),
              SettingRow(
                icon: Icons.translate,
                title: 'Bahasa',
                value: AppPrefs.isEn ? 'English' : 'Indonesia',
                onTap: () async {
                  final v = await showChoiceSheet<String>(
                    context,
                    title: 'Bahasa',
                    current: AppPrefs.lang.value,
                    options: const {
                      'id': ('Indonesia', 'Bahasa Indonesia', Icons.language),
                      'en': ('English', 'English', Icons.language),
                    },
                  );
                  if (v != null) AppPrefs.setLang(v);
                },
              ),
            ]),
            if (admin) ...[
              const SettingHeader('TOKO'),
              SettingGroup(children: [
                SettingRow(
                  icon: Icons.storefront_outlined,
                  title: 'Identitas toko',
                  value: 'Nama, tagline, kota, alamat',
                  onTap: () => _open(context, const AdminSettingsScreen(section: SettingsSection.identity)),
                ),
                SettingRow(
                  icon: Icons.alternate_email,
                  title: 'Kontak',
                  value: 'Email, WhatsApp, Instagram',
                  onTap: () => _open(context, const AdminSettingsScreen(section: SettingsSection.contact)),
                ),
                SettingRow(
                  icon: Icons.local_shipping_outlined,
                  title: 'Ongkir dan stok',
                  value: 'Ongkir flat, gratis ongkir, batas stok',
                  onTap: () => _open(context, const AdminSettingsScreen(section: SettingsSection.shipping)),
                ),
                SettingRow(
                  icon: Icons.timer_outlined,
                  title: 'Kesegaran kopi',
                  value: 'Masa segar setelah sangrai',
                  onTap: () => _open(context, const AdminSettingsScreen(section: SettingsSection.fresh)),
                ),
                SettingRow(
                  icon: Icons.card_giftcard_outlined,
                  title: 'Add-on',
                  value: 'Bungkus kado dan kartu ucapan',
                  onTap: () => _open(context, const AdminSettingsScreen(section: SettingsSection.addons)),
                ),
                SettingRow(
                  icon: Icons.payments_outlined,
                  title: 'Bayar di tempat (COD)',
                  value: 'Aktif atau mati, batas nilai',
                  onTap: () => _open(context, const AdminSettingsScreen(section: SettingsSection.cod)),
                ),
              ]),
              const SizedBox(height: 4),
              Text('Perubahan toko langsung dipakai di web dan aplikasi.', style: Brule.mono(10)),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingHeader extends StatelessWidget {
  final String text;
  const SettingHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(text, style: Brule.mono(11, color: Brule.amber)),
      );
}

/// Satu kartu berisi beberapa baris, dipisah garis tipis.
class SettingGroup extends StatelessWidget {
  final List<Widget> children;
  const SettingGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Brule.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Brule.hair(0.12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          children: [
            for (final (i, c) in children.indexed) ...[
              if (i > 0) Divider(height: 1, indent: 62, color: Brule.hair(0.1)),
              c,
            ],
          ],
        ),
      ),
    );
  }
}

class SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  const SettingRow({super.key, required this.icon, required this.title, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Brule.blue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: Brule.blueText),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Brule.condensed(17)),
                    const SizedBox(height: 2),
                    Text(value, style: Brule.mono(10.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Brule.kraft),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet pilihan tunggal: tiap opsi punya judul, keterangan, ikon; yang aktif diberi centang.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required T current,
  required Map<T, (String, String, IconData)> options,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Brule.sheet,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(color: Brule.hair(0.25), borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: Brule.condensed(22)),
            const SizedBox(height: 10),
            for (final e in options.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: e.key == current ? Brule.blue.withValues(alpha: 0.16) : Brule.field,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: e.key == current ? Brule.blueText : Brule.hair(0.12), width: e.key == current ? 1.5 : 1),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(ctx).pop(e.key),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      child: Row(
                        children: [
                          Icon(e.value.$3, color: Brule.blueText),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.value.$1, style: Brule.condensed(17)),
                                Text(e.value.$2, style: Brule.mono(10.5)),
                              ],
                            ),
                          ),
                          if (e.key == current) Icon(Icons.check_circle, color: Brule.blueText),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
