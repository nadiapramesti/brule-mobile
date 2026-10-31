import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'prefs.dart';

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
  // Bisa diganti dari dalam app (kartu error > UBAH ALAMAT SERVER), tersimpan di HP.
  static String base =
      const String.fromEnvironment('API_BASE', defaultValue: 'http://127.0.0.1:8001');

  static String? _token;

  /// Naik tiap kali login/logout, supaya layar yang bergantung pada sesi bisa menyegarkan diri.
  static final session = ValueNotifier<int>(0);
  static Map<String, dynamic>? user;

  /// true setelah pemeriksaan token saat aplikasi dibuka selesai (berhasil atau gagal).
  /// Intro menunggu ini supaya dashboard yang tampil sudah sesuai peran.
  static final ready = ValueNotifier<bool>(false);

  static bool get loggedIn => _token != null;

  static Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Accept-Language': AppPrefs.lang.value,
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Future<void> loadToken() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString('token');
    final saved = p.getString('api_base');
    if (saved != null && saved.isNotEmpty) base = saved;
  }

  /// Simpan alamat server baru, contoh: http://192.168.1.10:8001
  static Future<void> setBase(String url) async {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    base = u;
    final p = await SharedPreferences.getInstance();
    await p.setString('api_base', u);
  }

  static Future<Map<String, dynamic>> _send(
      Future<http.Response> Function() call,
      {Duration timeout = const Duration(seconds: 10)}) async {
    http.Response res;
    try {
      res = await call().timeout(timeout);
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

  /// Unduh berkas (PDF/Excel). Mengembalikan isi berkas dan nama dari header Content-Disposition.
  static Future<({List<int> bytes, String filename})> download(String path,
      [Map<String, String>? query]) async {
    final http.Response res;
    try {
      res = await http
          .get(Uri.parse('$base/api$path').replace(queryParameters: query), headers: _headers)
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw ApiException('Tidak bisa terhubung ke server.');
    }
    if (res.statusCode >= 400) {
      var msg = 'Gagal mengunduh berkas (${res.statusCode}).';
      try {
        final b = jsonDecode(res.body);
        if (b is Map && b['message'] != null) msg = '${b['message']}';
      } catch (_) {}
      throw ApiException(msg, res.statusCode);
    }
    final cd = res.headers['content-disposition'] ?? '';
    final m = RegExp(r'filename="?([^";]+)"?').firstMatch(cd);
    return (bytes: res.bodyBytes, filename: m?.group(1) ?? 'laporan');
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

  /// Unggah satu berkas (mis. foto) sebagai multipart.
  static Future<Map<String, dynamic>> upload(String path, String field, List<int> bytes, String filename) async {
    final req = http.MultipartRequest('POST', Uri.parse('$base/api$path'))
      ..headers.addAll({'Accept': 'application/json', 'Accept-Language': AppPrefs.lang.value, if (_token != null) 'Authorization': 'Bearer $_token'})
      ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
    final http.Response res;
    try {
      res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 60)));
    } on Exception {
      throw ApiException('Tidak bisa terhubung ke server.');
    }
    Map<String, dynamic> body = {};
    try {
      final d = jsonDecode(res.body);
      if (d is Map<String, dynamic>) body = d;
    } catch (_) {}
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    var msg = (body['message'] as String?) ?? 'Gagal mengunggah (${res.statusCode})';
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) msg = first.first.toString();
    }
    throw ApiException(msg, res.statusCode);
  }

  static Future<Map<String, dynamic>> delete(String path) {
    return _send(() => http.delete(
          Uri.parse('$base/api$path'),
          headers: _headers,
        ));
  }

  static Future<void> login(String email, String password, {bool remember = true}) async {
    final body = await _send(() => http.post(
          Uri.parse('$base/api/login'),
          headers: _headers,
          body: jsonEncode({'email': email, 'password': password}),
        ));
    await _startSession(body, remember: remember);
  }

  /// Tukar kode sekali pakai dari login Google/Facebook (lewat browser) jadi sesi aplikasi.
  static Future<void> exchange(String code) async {
    final body = await _send(() => http.post(
          Uri.parse('$base/api/auth/exchange'),
          headers: _headers,
          body: jsonEncode({'code': code}),
        ));
    await _startSession(body);
  }

  /// Daftar akun pelanggan baru; langsung masuk kalau berhasil.
  static Future<void> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String confirmation,
  }) async {
    final body = await _send(() => http.post(
          Uri.parse('$base/api/register'),
          headers: _headers,
          body: jsonEncode({
            'name': name,
            'email': email,
            if (phone != null && phone.isNotEmpty) 'phone': phone,
            'password': password,
            'password_confirmation': confirmation,
          }),
        ));
    await _startSession(body);
  }

  static Future<void> _startSession(Map<String, dynamic> body, {bool remember = true}) async {
    _token = body['token'] as String;
    user = Map<String, dynamic>.from(body['user'] as Map);
    final p = await SharedPreferences.getInstance();
    if (remember) {
      await p.setString('token', _token!);
    } else {
      await p.remove('token'); // sesi hanya hidup selama app terbuka
    }
    session.value++;
  }

  /// Dipakai saat aplikasi dibuka: token lama masih sah atau sudah mati?
  static Future<bool> restore() async {
    if (_token == null) return false;
    try {
      // Server gratis yang sedang tidur butuh waktu bangun, jadi timeout dibuat panjang.
      user = await _send(
          () => http.get(Uri.parse('$base/api/me'), headers: _headers),
          timeout: const Duration(seconds: 45));
      session.value++; // layar utama memilih ulang tampilan sesuai peran
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
    session.value++;
  }
}
