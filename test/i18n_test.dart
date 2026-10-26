import 'package:flutter_test/flutter_test.dart';
import 'package:brule_mobile/i18n.dart';
import 'package:brule_mobile/i18n_en.dart';
import 'package:brule_mobile/prefs.dart';

void main() {
  tearDown(() => AppPrefs.lang.value = 'id');

  test('bahasa Indonesia: teks apa adanya', () {
    AppPrefs.lang.value = 'id';
    expect(tr('Batalkan pesanan?'), 'Batalkan pesanan?');
  });

  test('bahasa Inggris: kamus persis, pola {}, dan kata + angka', () {
    AppPrefs.lang.value = 'en';
    expect(tr('Batalkan pesanan?'), 'Cancel order?');
    expect(tr('2 item masuk keranjang, 1 tidak tersedia lagi'), '2 items added to cart, 1 no longer available');
    expect(tr('Semua 12'), 'All 12');
  });

  test('teks tanpa kamus dibiarkan (nama kopi, pesan server)', () {
    AppPrefs.lang.value = 'en';
    expect(tr('Gayo Wine Natural'), 'Gayo Wine Natural');
    expect(tr(''), '');
  });

  test('spasi di tepi teks tidak merusak terjemahan', () {
    AppPrefs.lang.value = 'en';
    expect(tr(' Batalkan pesanan? '), ' Cancel order? ');
  });

  test('kamus: tidak ada nilai kosong', () {
    for (final e in kEn.entries) {
      expect(e.value.trim().isNotEmpty, true, reason: 'kosong: ${e.key}');
    }
    for (final (k, v) in kEnPatterns) {
      expect(k.split('{}').length, v.split('{}').length, reason: 'jumlah {} beda: $k');
    }
  });
}
