import 'package:flutter_test/flutter_test.dart';
import 'package:brule_mobile/prefs.dart';
import 'package:brule_mobile/util.dart';

void main() {
  tearDown(() => AppPrefs.lang.value = 'id');

  test('rupiah memakai titik ribuan', () {
    expect(rupiah(0), 'Rp 0');
    expect(rupiah(999), 'Rp 999');
    expect(rupiah(45000), 'Rp 45.000');
    expect(rupiah(1250000), 'Rp 1.250.000');
  });

  test('asInt menerima angka, teks, dan sampah', () {
    expect(asInt(12), 12);
    expect(asInt(12.9), 12);
    expect(asInt('34'), 34);
    expect(asInt(null), 0);
    expect(asInt('abc'), 0);
  });

  test('fullDate mengikuti bahasa', () {
    AppPrefs.lang.value = 'id';
    expect(fullDate('2026-08-17'), '17 Agu 2026');
    AppPrefs.lang.value = 'en';
    expect(fullDate('2026-08-17'), '17 Aug 2026');
  });

  test('tanggal kosong atau rusak jadi string kosong', () {
    expect(fullDate('bukan tanggal'), '');
    expect(dateTime(null), '');
    expect(dayMonth(''), '');
  });
}
