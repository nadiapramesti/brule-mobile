import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../api.dart';
import 'admin_kit.dart';

/// Unduh berkas dari API lalu buka menu bagikan/simpan (Drive, WhatsApp, WPS Office, dll).
/// Mengembalikan true bila berkas berhasil diunduh.
Future<bool> downloadAndShare(BuildContext context, String path, Map<String, String> query) async {
  try {
    final f = await Api.download(path, query);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${f.filename}');
    await file.writeAsBytes(f.bytes, flush: true);
    final mime = f.filename.endsWith('.pdf')
        ? 'application/pdf'
        : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: mime)], subject: f.filename),
    );
    return true;
  } on ApiException catch (e) {
    if (context.mounted) toast(context, e.message);
  } catch (_) {
    if (context.mounted) toast(context, 'Gagal menyimpan berkas laporan.');
  }
  return false;
}
