String rupiah(num v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final left = s.length - i;
    b.write(s[i]);
    if (left > 1 && left % 3 == 1) b.write('.');
  }
  return 'Rp $b';
}

String dateTime(String? iso) {
  final d = DateTime.tryParse(iso ?? '')?.toLocal();
  if (d == null) return '';
  String t(int n) => n.toString().padLeft(2, '0');
  return '${t(d.day)}/${t(d.month)}/${d.year} ${t(d.hour)}:${t(d.minute)}';
}

const kGrams = [100, 200, 250, 500, 1000];

const kGrinds = {
  'whole_bean': 'Biji Utuh',
  'v60': 'V60 / Pour Over',
  'espresso': 'Espresso',
  'french_press': 'French Press',
  'tubruk': 'Tubruk',
  'aeropress': 'Aeropress',
};

int asInt(dynamic v) => v is num ? v.toInt() : (int.tryParse('$v') ?? 0);

String dayMonth(String? iso) {
  final d = DateTime.tryParse(iso ?? '')?.toLocal();
  if (d == null) return '';
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

const _dayNames = ['SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'MINGGU'];
const _monthNames = ['JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN', 'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'];

DateTime? _whenOf(Object? iso) => DateTime.tryParse('$iso')?.toLocal();

/// Judul kelompok: HARI INI, KEMARIN, atau "SENIN, 26 OKT 2026".
String dayGroup(Map<String, dynamic> m, [String key = 'created_at']) {
  return dayTitleOf(m[key]);
}

String dayTitleOf(Object? iso) {
  final d = _whenOf(iso);
  if (d == null) return '-';
  final now = DateTime.now();
  final a = DateTime(d.year, d.month, d.day);
  final t = DateTime(now.year, now.month, now.day);
  final diff = t.difference(a).inDays;
  if (diff == 0) return 'HARI INI';
  if (diff == 1) return 'KEMARIN';
  return '${_dayNames[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]} ${d.year}';
}

String clockOf(Object? iso) {
  final d = _whenOf(iso);
  if (d == null) return '';
  return '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';
}

const _monthLong = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// "2026-11-09" atau ISO -> "9 Nov 2026". Kosong bila tidak bisa dibaca.
String fullDate(Object? iso) {
  final d = DateTime.tryParse('$iso');
  if (d == null) return '';
  final l = iso is String && iso.length > 10 ? d.toLocal() : d;
  return '${l.day} ${_monthLong[l.month - 1]} ${l.year}';
}
