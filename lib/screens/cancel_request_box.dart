import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import '../api.dart';
import '../cart.dart';
import '../theme.dart';
import '../widgets.dart';

/// Pesanan yang sudah masuk dapur tidak bisa dibatalkan langsung. Pelanggan menulis alasan
/// lalu mengajukan; admin yang menyetujui atau menolak.
class CancelRequestBox extends StatefulWidget {
  final String code;
  final Future<void> Function() reload;
  const CancelRequestBox({super.key, required this.code, required this.reload});

  @override
  State<CancelRequestBox> createState() => _CancelRequestBoxState();
}

class _CancelRequestBoxState extends State<CancelRequestBox> {
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajukan pembatalan?'),
        content: const Text(
            'Pesanan ini sudah disangrai, jadi admin yang memutuskan. Kamu akan diberi tahu hasilnya. Biji yang sudah disangrai tidak dikembalikan ke stok.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('TIDAK')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('YA, AJUKAN'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final text = _reason.text.trim();
      await Api.post('/orders/${widget.code}/cancel-request', text.isEmpty ? {} : {'reason': text});
      AppEvents.ordersChanged.value++;
      await widget.reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      await widget.reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Label('AJUKAN PEMBATALAN'),
        const Text('Pesananmu sudah masuk dapur, jadi tidak bisa dibatalkan langsung.'),
        const SizedBox(height: 10),
        TextField(
          controller: _reason,
          maxLength: 160,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: tr('Contoh: salah pilih level sangrai')),
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Brule.red,
            side: BorderSide(color: Brule.red.withValues(alpha: 0.6)),
          ),
          onPressed: _busy ? null : _submit,
          icon: const Icon(Icons.undo, size: 18),
          label: const Text('AJUKAN PEMBATALAN'),
        ),
      ],
    );
  }
}

/// Info setelah pengajuan terkirim, menunggu jawaban admin.
class CancelRequestedInfo extends StatelessWidget {
  final String? reason;
  const CancelRequestedInfo({super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Brule.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Brule.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_top, size: 18, color: Brule.amber),
              const SizedBox(width: 8),
              const Expanded(child: Text('Permintaan pembatalan sudah dikirim')),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Menunggu jawaban admin. Pesanan tetap diproses sampai ada keputusan.'),
          if (reason != null && reason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('"$reason"', style: Brule.mono(11, color: Brule.amber)),
          ],
        ],
      ),
    );
  }
}
