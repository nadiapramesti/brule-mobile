import 'package:flutter/material.dart' hide Text;
import 'package:flutter/widgets.dart' as w show Text;
import 'i18n_en.dart';
import 'prefs.dart';

final _cache = <String, String>{};
List<(RegExp, String)>? _pats;

List<(RegExp, String)> get _patterns => _pats ??= [
      for (final (k, v) in kEnPatterns)
        (
          RegExp('^${k.split('{}').map(RegExp.escape).join('(.+?)')}\$', dotAll: true),
          v,
        ),
    ];

/// Terjemahkan teks Indonesia ke bahasa pilihan. Bahasa Indonesia = teks apa adanya.
/// Teks yang tidak ada di kamus dibiarkan (misalnya nama kopi dan pesan dari server).
String tr(String s) {
  if (s.isEmpty || !AppPrefs.isEn) return s;
  final hit = _cache[s];
  if (hit != null) return hit;
  final r = _translate(s);
  if (_cache.length > 4000) _cache.clear();
  return _cache[s] = r;
}

String _translate(String s) {
  final exact = kEn[s];
  if (exact != null) return exact;
  final t = s.trim();
  if (t.isEmpty) return s;
  if (t != s) return s.replaceFirst(t, tr(t));
  // "Semua 12", "Admin 3": kata + angka di belakang (label filter dengan hitungan).
  final cnt = RegExp(r'^(.+?) (\d+)$').firstMatch(s);
  if (cnt != null) {
    final head = tr(cnt.group(1)!);
    if (head != cnt.group(1)) return '$head ${cnt.group(2)}';
  }
  for (final (re, out) in _patterns) {
    final m = re.firstMatch(s);
    if (m == null) continue;
    var i = 0;
    return out.replaceAllMapped('{}', (_) => tr(m.group(++i) ?? ''));
  }
  for (final sep in const [' · ', '\n', ' / ', ': ']) {
    if (!s.contains(sep)) continue;
    final parts = s.split(sep);
    final out = [for (final p in parts) tr(p)];
    var changed = false;
    for (var i = 0; i < parts.length; i++) {
      if (parts[i] != out[i]) changed = true;
    }
    if (changed) return out.join(sep);
  }
  return s;
}

/// Pengganti Text bawaan: isinya otomatis diterjemahkan lewat [tr].
/// Dipakai dengan `import 'package:flutter/material.dart' hide Text;`.
class Text extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextScaler? textScaler;
  final String? semanticsLabel;
  final StrutStyle? strutStyle;

  const Text(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textScaler,
    this.semanticsLabel,
    this.strutStyle,
  });

  @override
  Widget build(BuildContext context) => w.Text(
        tr(data),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        textScaler: textScaler,
        semanticsLabel: semanticsLabel,
        strutStyle: strutStyle,
      );
}
