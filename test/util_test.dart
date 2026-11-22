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

  test('waNumber: hanya angka, awalan 0 jadi 62, nomor pendek ditolak', () {
    expect(waNumber('0812-3456-7890'), '6281234567890');
    expect(waNumber('+62 812 3456 7890'), '6281234567890');
    expect(waNumber('81234567890'), '6281234567890');
    expect(waNumber('6281234567890'), '6281234567890');
    expect(waNumber(''), null);
    expect(waNumber(null), null);
    expect(waNumber('0812'), null);
  });

  test('pesan WA invoice memakai nama depan, dan "Kak" bila nama kosong', () {
    const url = 'https://brule.test/invoice/BRL-1?signature=abc';
    expect(
      invoiceWaText('Nadia Pramesti', 'BRL-1', url),
      'Halo Nadia, terima kasih sudah memesan di BRÛLÉ. Invoice pesanan BRL-1: $url',
    );
    expect(invoiceWaText('  ', 'BRL-1', url), startsWith('Halo Kak,'));
    expect(invoiceWaText(null, 'BRL-1', url), startsWith('Halo Kak,'));
  });

  test('waUri: tujuan wa.me dan isi pesan ter-encode lalu bisa dibaca balik', () {
    final text = invoiceWaText('Nadia', 'BRL-1', 'https://brule.test/invoice/BRL-1?signature=abc&x=1');
    final u = waUri('6281234567890', text);
    expect(u.host, 'wa.me');
    expect(u.path, '/6281234567890');
    expect(u.queryParameters['text'], text);
  });
  test('resiWaText: nama depan, kode, resi, dan link lacak', () {
    expect(
      resiWaText('Nadia Pramesti', 'BRL-123', 'JNE123456', 'https://toko.test/lacak/BRL-123'),
      'Halo Nadia, pesanan BRL-123 sudah dikirim. Nomor resi: JNE123456. Lacak tanpa login: https://toko.test/lacak/BRL-123',
    );
    expect(resiWaText('', 'A1', 'R1', 'u'), startsWith('Halo Kak, pesanan A1'));
    expect(resiWaText(null, 'A1', 'R1', 'u'), startsWith('Halo Kak,'));
  });

  test('resiWaText masuk ke wa.me dengan teks ter-encode dan nomor 62', () {
    final uri = waUri(waNumber('081234567890')!, resiWaText('Nadia', 'BRL-1', 'JNE1', 'https://t.test/lacak/BRL-1'));
    expect(uri.host, 'wa.me');
    expect(uri.path, '/6281234567890');
    expect(uri.queryParameters['text'], contains('Nomor resi: JNE1'));
  });
}
