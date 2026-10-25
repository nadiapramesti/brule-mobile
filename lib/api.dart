import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class Api {
  // Lewat kabel USB: adb reverse tcp:8001 tcp:8001. Ganti dengan
  // --dart-define=API_BASE=http://IP-LAPTOP:8001 kalau lewat WiFi.
  static const base =
      String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:8001');

  static String? _token;
  static Map<String, dynamic>? user;

  static bool get loggedIn => _token != null;

  static Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Future<void> loadToken() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString('token');
  }

  static Future<Map<String, dynamic>> _send(
      Future<http.Response> Function() call) async {
    http.Response res;
    try {
      res = await call().timeout(const Duration(seconds: 10));
    } on Exception {
      throw ApiException(
          'Tidak bisa terhubung ke server. Pastikan API menyala dan kabel USB tersambung.');
    }

    Map<String, dynamic> body = {};
    try {
      final d = jsonDecode(res.body);
      if (d is Map<String, dynamic>) body = d;
    } catch (_) {}

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    var msg =
        (body['message'] as String?) ?? 'Terjadi kesalahan (${res.statusCode})';
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) msg = first.first.toString();
    }
    throw ApiException(msg, res.statusCode);
  }

  static Future<Map<String, dynamic>> get(String path,
      [Map<String, String>? query]) {
    return _send(() => http.get(
          Uri.parse('$base/api$path').replace(queryParameters: query),
          headers: _headers,
        ));
  }

  static Future<Map<String, dynamic>> post(String path,
      [Map<String, dynamic>? body]) {
    return _send(() => http.post(
          Uri.parse('$base/api$path'),
          headers: _headers,
          body: jsonEncode(body ?? {}),
        ));
  }

  static Future<Map<String, dynamic>> put(String path,
      [Map<String, dynamic>? body]) {
    return _send(() => http.put(
          Uri.parse('$base/api$path'),
          headers: _headers,
          body: jsonEncode(body ?? {}),
        ));
  }

  static Future<Map<String, dynamic>> delete(String path) {
    return _send(() => http.delete(
          Uri.parse('$base/api$path'),
          headers: _headers,
        ));
  }

  static Future<void> login(String email, String password) async {
    final body = await _send(() => http.post(
          Uri.parse('$base/api/login'),
          headers: _headers,
          body: jsonEncode({'email': email, 'password': password}),
        ));
    _token = body['token'] as String;
    user = Map<String, dynamic>.from(body['user'] as Map);
    final p = await SharedPreferences.getInstance();
    await p.setString('token', _token!);
  }

  /// Dipakai saat aplikasi dibuka: token lama masih sah atau sudah mati?
  static Future<bool> restore() async {
    if (_token == null) return false;
    try {
      user = await _send(
          () => http.get(Uri.parse('$base/api/me'), headers: _headers));
      return true;
    } on ApiException catch (e) {
      if (e.status == 401) await _clear();
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      await _send(
          () => http.post(Uri.parse('$base/api/logout'), headers: _headers));
    } catch (_) {}
    await _clear();
  }

  static Future<void> _clear() async {
    _token = null;
    user = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('token');
  }
}
