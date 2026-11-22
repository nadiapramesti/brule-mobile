import 'package:flutter_test/flutter_test.dart';
import 'package:brule_mobile/models.dart';

Map<String, dynamic> _order(Map<String, dynamic> extra) => {
      'code': 'BRL-1',
      'status': 'roasting',
      'status_label': 'Sedang Disangrai',
      'payment_method': 'cod',
      'steps': <dynamic>[],
      'items': <dynamic>[],
      'recipient': <String, dynamic>{},
      ...extra,
    };

void main() {
  group('Order: ajukan batal', () {
    test('field permintaan batal dibaca dari server', () {
      final o = Order.fromJson(_order({
        'can_cancel': false,
        'can_request_cancel': true,
        'cancel_requested_at': null,
        'cancel_request_reason': null,
      }));
      expect(o.canCancel, false);
      expect(o.canRequestCancel, true);
      expect(o.cancelRequestedAt, isNull);
    });

    test('setelah diajukan: waktu dan alasan terisi, tombol ajukan hilang', () {
      final o = Order.fromJson(_order({
        'can_request_cancel': false,
        'cancel_requested_at': '2026-11-22T10:00:00+07:00',
        'cancel_request_reason': 'Salah pilih level sangrai',
      }));
      expect(o.canRequestCancel, false);
      expect(o.cancelRequestedAt, '2026-11-22T10:00:00+07:00');
      expect(o.cancelRequestReason, 'Salah pilih level sangrai');
    });

    test('server lama tanpa field baru: semuanya aman (false/null)', () {
      final o = Order.fromJson(_order({}));
      expect(o.canRequestCancel, false);
      expect(o.cancelRequestedAt, isNull);
      expect(o.cancelRequestReason, isNull);
    });
  });

  group('Recommendation', () {
    test('membaca slug, level, harga per 100 g, dan catatan rasa', () {
      final r = Recommendation.fromJson({
        'slug': 'gayo-wine',
        'name': 'Gayo Wine',
        'image': null,
        'profile_id': 3,
        'level': 'medium_light',
        'level_label': 'Medium Light',
        'price_per_100g': '45000',
        'tasting_notes': ['jeruk', 'beri'],
      });
      expect(r.slug, 'gayo-wine');
      expect(r.level, 'medium_light');
      expect(r.pricePer100g, 45000);
      expect(r.notes, ['jeruk', 'beri']);
    });
  });

  group('ShippingQuote', () {
    test('masih kurang: gap > 0 dan promo aktif', () {
      final q = ShippingQuote.fromJson({'shipping': 15000, 'free_shipping_from': 500000, 'free_shipping_gap': 380000});
      expect(q.hasPromo, true);
      expect(q.gap, 380000);
      expect(q.shipping, 15000);
    });

    test('promo dimatikan admin (batas 0): hasPromo false', () {
      final q = ShippingQuote.fromJson({'shipping': 15000, 'free_shipping_from': 0, 'free_shipping_gap': 0});
      expect(q.hasPromo, false);
    });

    test('sudah gratis: gap 0 tapi promo masih aktif', () {
      final q = ShippingQuote.fromJson({'shipping': 0, 'free_shipping_from': 500000, 'free_shipping_gap': 0});
      expect(q.hasPromo, true);
      expect(q.gap, 0);
    });
  });
}
