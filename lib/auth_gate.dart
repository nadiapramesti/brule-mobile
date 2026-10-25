import 'package:flutter/material.dart';
import 'api.dart';
import 'cart.dart';
import 'screens/login_screen.dart';

/// Jelajah katalog bebas, tapi belanja butuh akun. Kalau belum masuk, buka layar login
/// dan kembalikan true bila berhasil masuk.
Future<bool> requireLogin(BuildContext context, {String? reason}) async {
  if (Api.loggedIn) return true;
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => LoginScreen(
        popOnSuccess: true,
        reason: reason ?? 'Masuk dulu untuk mulai belanja.',
      ),
    ),
  );
  if (ok == true) AppEvents.ordersChanged.value++;
  return ok == true;
}
