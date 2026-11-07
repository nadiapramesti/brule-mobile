import 'package:flutter/material.dart' hide Text;
import 'package:url_launcher/url_launcher.dart';
import 'i18n.dart';

/// Buka tautan di aplikasi atau browser luar (bukan WebView), mis. invoice dan WhatsApp.
/// Mengembalikan false dan menampilkan pesan bila tidak ada aplikasi yang bisa membukanya.
Future<bool> openExternal(BuildContext context, Uri uri) async {
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak bisa membuka tautan.')));
  }
  return ok;
}
