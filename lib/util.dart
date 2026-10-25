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
