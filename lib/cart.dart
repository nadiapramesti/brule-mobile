import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Penanda sederhana: naik tiap kali pesanan dibuat/diubah, supaya tab Pesanan memuat ulang.
class AppEvents {
  static final ordersChanged = ValueNotifier<int>(0);
}

class CartLine {
  final String kind; // coffee | gear
  final int refId; // id profil sangrai (kopi) atau id produk (gear)
  final String name;
  final String detail;
  final int unit;
  final String? image;
  final int? grams;
  final String? grind;
  final String? option;
  int qty;

  CartLine({
    required this.kind,
    required this.refId,
    required this.name,
    required this.detail,
    required this.unit,
    this.image,
    this.grams,
    this.grind,
    this.option,
    this.qty = 1,
  });

  String get key => '$kind|$refId|${grams ?? ''}|${grind ?? ''}|${option ?? ''}';
  int get total => unit * qty;

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'refId': refId,
        'name': name,
        'detail': detail,
        'unit': unit,
        'image': image,
        'grams': grams,
        'grind': grind,
        'option': option,
        'qty': qty,
      };

  factory CartLine.fromJson(Map<String, dynamic> j) => CartLine(
        kind: j['kind'] as String,
        refId: j['refId'] as int,
        name: j['name'] as String,
        detail: j['detail'] as String,
        unit: j['unit'] as int,
        image: j['image'] as String?,
        grams: j['grams'] as int?,
        grind: j['grind'] as String?,
        option: j['option'] as String?,
        qty: j['qty'] as int,
      );
}

/// Keranjang disimpan di perangkat. Harga akhir tetap dihitung ulang server saat pesanan dibuat.
class Cart extends ChangeNotifier {
  Cart._();
  static final Cart I = Cart._();

  final List<CartLine> lines = [];

  int get count => lines.fold(0, (a, l) => a + l.qty);
  int get subtotal => lines.fold(0, (a, l) => a + l.total);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('cart');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        lines
          ..clear()
          ..addAll(list.map((e) => CartLine.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        lines.clear();
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('cart', jsonEncode(lines.map((l) => l.toJson()).toList()));
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  void add(CartLine line) {
    final i = lines.indexWhere((l) => l.key == line.key);
    if (i >= 0) {
      lines[i].qty = (lines[i].qty + line.qty).clamp(1, 20).toInt();
    } else {
      lines.add(line);
    }
    _changed();
  }

  void setQty(CartLine l, int q) {
    if (q <= 0) {
      lines.remove(l);
    } else {
      l.qty = q.clamp(1, 20).toInt();
    }
    _changed();
  }

  void remove(CartLine l) {
    lines.remove(l);
    _changed();
  }

  void clear() {
    lines.clear();
    _changed();
  }
}
