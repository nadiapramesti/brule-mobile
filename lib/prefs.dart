import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

/// Pilihan tampilan pengguna: tema terang/gelap. Tersimpan di HP.
/// Belum memilih = mengikuti setelan sistem, seperti di web.
class AppPrefs {
  AppPrefs._();

  /// true = terang. Dipakai MaterialApp untuk membangun ulang tema.
  static final light = ValueNotifier<bool>(false);

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString('theme');
    final sys = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.light;
    final v = t == 'light' ? true : (t == 'dark' ? false : sys);
    Brule.light = v;
    light.value = v;
  }

  static Future<void> setLight(bool v) async {
    if (Brule.light == v) return;
    Brule.light = v;
    light.value = v;
    _rebuildAll();
    final p = await SharedPreferences.getInstance();
    await p.setString('theme', v ? 'light' : 'dark');
  }

  /// Warna merek dibaca langsung lewat Brule.*, jadi semua layar perlu dibangun ulang
  /// (state dan posisi scroll tetap terjaga).
  static void _rebuildAll() {
    void visit(Element e) {
      e.markNeedsBuild();
      e.visitChildren(visit);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
  }
}

/// Dua pilihan tampilan dalam satu baris: GELAP | TERANG.
class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppPrefs.light,
      builder: (context, light, _) {
        Widget seg(String label, IconData icon, bool value) {
          final on = light == value;
          return Expanded(
            child: Material(
              color: on ? Brule.blue : Colors.transparent,
              child: InkWell(
                onTap: () => AppPrefs.setLight(value),
                child: SizedBox(
                  height: 42,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 17, color: on ? Brule.paper : Brule.kraft),
                      const SizedBox(width: 8),
                      Text(label, style: Brule.condensed(14, spacing: 1, color: on ? Brule.paper : Brule.kraft)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Brule.hair(0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Row(children: [
              seg('GELAP', Icons.dark_mode_outlined, false),
              seg('TERANG', Icons.light_mode_outlined, true),
            ]),
          ),
        );
      },
    );
  }
}

/// Tombol bulat kecil untuk ganti tema langsung dari header (ikon = mode tujuan).
class ThemeIconButton extends StatelessWidget {
  const ThemeIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppPrefs.light,
      builder: (context, light, _) => Material(
        color: Brule.field,
        shape: CircleBorder(side: BorderSide(color: Brule.hair(0.16))),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => AppPrefs.setLight(!light),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(light ? Icons.dark_mode_outlined : Icons.light_mode_outlined, size: 20, color: Brule.kraft),
          ),
        ),
      ),
    );
  }
}
