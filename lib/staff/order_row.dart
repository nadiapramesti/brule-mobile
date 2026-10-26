import 'package:flutter/material.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

/// Umur pesanan dalam bentuk singkat: "35 mnt", "5 jam", "2 hari".
String ageLabel(String? iso) {
  final d = DateTime.tryParse(iso ?? '');
  if (d == null) return '';
  final m = DateTime.now().difference(d).inMinutes;
  if (m < 1) return 'baru saja';
  if (m < 60) return '$m mnt';
  if (m < 60 * 48) return '${m ~/ 60} jam';
  return '${m ~/ 1440} hari';
}

/// Baris pesanan yang padat dan rapi, dipakai di antrian roaster dan daftar pesanan admin.
/// Satu baris ≈ 76 px, jadi puluhan pesanan tetap enak di-scroll.
class OrderRow extends StatelessWidget {
  final Map<String, dynamic> o;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onAdvance;
  final VoidCallback? onShip;
  final bool selectable;
  final bool selected;
  final VoidCallback? onToggle;
  final bool showTotal;
  final bool showStatus;

  const OrderRow({
    super.key,
    required this.o,
    required this.onTap,
    this.onLongPress,
    this.onAdvance,
    this.onShip,
    this.selectable = false,
    this.selected = false,
    this.onToggle,
    this.showTotal = false,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final late = o['is_late'] == true;
    final status = '${o['status']}';
    final canAdvance = onAdvance != null && o['can_advance'] == true;
    final canShip = onShip != null && o['can_ship'] == true;
    final showCheck = selectable && o['can_advance'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? Brule.amber.withValues(alpha: 0.08) : Brule.field,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? Brule.amber
              : (late ? Brule.amber.withValues(alpha: 0.5) : Brule.hair(0.1)),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 46,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: statusColor(status).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (selectable)
                  SizedBox(
                    width: 40,
                    child: Checkbox(
                      value: selected,
                      onChanged: showCheck ? (_) => onToggle?.call() : null,
                      activeColor: Brule.amber,
                      checkColor: Brule.bg,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                else
                  const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text('${o['code']}',
                                overflow: TextOverflow.ellipsis,
                                style: Brule.mono(10.5, color: Brule.kraft)),
                          ),
                          if (late) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.schedule, size: 12, color: Brule.amber),
                          ],
                          if (showStatus) ...[
                            const SizedBox(width: 8),
                            Tag('${o['status_label']}'.toUpperCase(), color: statusColor(status)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('${o['recipient'] ?? ''}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: Brule.condensed(17)),
                      const SizedBox(height: 2),
                      Text('${o['summary'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Brule.kraft.withValues(alpha: 0.85), fontSize: 12.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (showTotal)
                      Text(rupiah(asInt(o['total'])), style: Brule.condensed(16))
                    else if (asInt(o['grams']) > 0)
                      Text('${o['grams']} g', style: Brule.condensed(16)),
                    const SizedBox(height: 2),
                    Text(ageLabel('${o['since']}'),
                        style: Brule.mono(9.5, color: late ? Brule.amber : Brule.kraft)),
                  ],
                ),
                if (canAdvance || canShip) ...[
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: canShip ? 'Kirim dengan resi' : 'Lanjut: ${o['next_label']}',
                    onPressed: canShip ? onShip : onAdvance,
                    icon: Icon(canShip ? Icons.local_shipping_outlined : Icons.arrow_forward, size: 18),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog isi nomor resi. Mengembalikan teks resi atau null kalau dibatalkan.
Future<String?> askTracking(BuildContext context, String code) {
  final c = TextEditingController();
  String? error;
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: Brule.field,
          title: Text('Kirim $code', style: Brule.condensed(20)),
          content: TextField(
            controller: c,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'contoh: JNE1234567890',
              errorText: error,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(96, 44)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('BATAL'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
              onPressed: () {
                final v = c.text.trim();
                if (v.length < 6) {
                  setState(() => error = 'Nomor resi terlalu pendek.');
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: const Text('KIRIM'),
            ),
          ],
        );
      },
    ),
  );
}
