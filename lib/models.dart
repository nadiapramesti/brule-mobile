List<String> _strings(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  if (v is Map && v.isNotEmpty) return _strings(v.values.first);
  return <String>[];
}

int _int(dynamic v) => v is num ? v.toInt() : (int.tryParse('$v') ?? 0);

class RoastProfile {
  final int id;
  final String level;
  final String levelLabel;
  final int? agtron;
  final List<String> notes;
  final int pricePer100g;

  RoastProfile.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        level = '${j['level']}',
        levelLabel = '${j['level_label'] ?? j['level']}',
        agtron = j['agtron'] == null ? null : _int(j['agtron']),
        notes = _strings(j['tasting_notes']),
        pricePer100g = _int(j['price_per_100g']);

  int priceFor(int grams) => (pricePer100g * grams / 100).round();
}

class Coffee {
  final int id;
  final String slug;
  final String name;
  final String? story;
  final String? image;
  final double? cupping;
  final bool inStock;
  final List<RoastProfile> profiles;
  final String shortName;
  final String? process;
  final int? altitude;
  final String? signatureLevel;
  final Map<String, dynamic> trace;

  Coffee.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        slug = '${j['slug']}',
        name = '${j['name']}',
        story = j['story'] as String?,
        image = j['image'] as String?,
        cupping = j['cupping_score'] == null
            ? null
            : double.tryParse('${j['cupping_score']}'),
        inStock = j['in_stock'] == true,
        profiles = ((j['profiles'] ?? []) as List)
            .map((e) => RoastProfile.fromJson(e as Map<String, dynamic>))
            .toList(),
        shortName = '${j['short_name'] ?? j['name']}',
        process = j['process'] as String?,
        altitude = j['altitude'] == null ? null : _int(j['altitude']),
        signatureLevel = j['signature_level'] as String?,
        trace = (j['trace'] ?? <String, dynamic>{}) as Map<String, dynamic>;

  int get fromPrice => profiles.isEmpty
      ? 0
      : profiles.map((p) => p.pricePer100g).reduce((a, b) => a < b ? a : b);
}

class Gear {
  final int id;
  final String slug;
  final String name;
  final String category;
  final String? description;
  final int price;
  final int stock;
  final bool inStock;
  final String? optionLabel;
  final List<String> options;
  final String? image;
  final Map<String, String> optionImages;

  Gear.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        slug = '${j['slug']}',
        name = '${j['name']}',
        category = '${j['category'] ?? ''}',
        description = j['description'] as String?,
        price = _int(j['price']),
        stock = _int(j['stock']),
        inStock = j['in_stock'] == true,
        optionLabel = j['option_label'] as String?,
        options = _strings(j['options']),
        image = j['image'] as String?,
        optionImages = j['option_images'] is Map
            ? {
                for (final e in (j['option_images'] as Map).entries)
                  if (e.value != null) '${e.key}': '${e.value}'
              }
            : <String, String>{};
}

class OrderItem {
  final String name;
  final String detail;
  final int grams;
  final int lineTotal;
  final bool isGear;

  OrderItem.fromJson(Map<String, dynamic> j)
      : name = '${j['name']}',
        detail = '${j['detail'] ?? ''}',
        grams = _int(j['grams']),
        lineTotal = _int(j['line_total']),
        isGear = j['is_gear'] == true;
}

class Order {
  final String code;
  final String status;
  final String statusLabel;
  final String paymentMethod;
  final int progress;
  final int? step;
  final List<String> steps;
  final bool isPaid;
  final bool canPay;
  final bool canCancel;
  final String? trackingNumber;
  final int subtotal;
  final int shipping;
  final int addon;
  final int discount;
  final int total;
  final String? voucherCode;
  final bool giftWrap;
  final String? cardMessage;
  final String? createdAt;
  final Map<String, dynamic> recipient;
  final List<OrderItem> items;

  Order.fromJson(Map<String, dynamic> j)
      : code = '${j['code']}',
        status = '${j['status']}',
        statusLabel = statusLabelId('${j['status']}', '${j['status_label']}'),
        paymentMethod = '${j['payment_method']}',
        progress = _int(j['progress']),
        step = j['step'] == null ? null : _int(j['step']),
        steps = ((j['steps'] ?? []) as List)
            .map((e) => e is Map ? statusLabelId('${e['key']}', '${e['label']}') : statusLabelId('$e', '$e'))
            .toList(),
        isPaid = j['is_paid'] == true,
        canPay = j['can_pay'] == true,
        canCancel = j['can_cancel'] == true,
        trackingNumber = j['tracking_number'] as String?,
        subtotal = _int(j['subtotal']),
        shipping = _int(j['shipping_cost']),
        addon = _int(j['addon_cost']),
        discount = _int(j['discount']),
        total = _int(j['total']),
        voucherCode = j['voucher_code'] as String?,
        giftWrap = j['gift_wrap'] == true,
        cardMessage = j['card_message'] as String?,
        createdAt = j['created_at'] as String?,
        recipient = (j['recipient'] ?? <String, dynamic>{}) as Map<String, dynamic>,
        items = ((j['items'] ?? []) as List)
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList();
}


/// Label status bahasa Indonesia, sama dengan Order::STATUS_LABELS di web.
/// Dipakai supaya tampilan tidak tergantung locale server.
const _statusId = {
  'pending_payment': 'Menunggu Pembayaran',
  'queued': 'Masuk Antrian',
  'roasting': 'Sedang Disangrai',
  'grinding': 'Sedang Digiling',
  'packing': 'Dikemas',
  'shipped': 'Dikirim',
  'completed': 'Selesai',
  'cancelled': 'Dibatalkan',
};

String statusLabelId(String key, String fallback) => _statusId[key] ?? fallback;

class Address {
  final int id;
  final String label;
  final String recipient;
  final String phone;
  final String address;
  final bool isDefault;

  Address.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        label = '${j['label']}',
        recipient = '${j['recipient']}',
        phone = '${j['phone']}',
        address = '${j['address']}',
        isDefault = j['is_default'] == true;
}
