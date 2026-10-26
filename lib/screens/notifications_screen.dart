import 'package:flutter/material.dart' hide Text;
import '../i18n.dart';
import '../api.dart';
import '../notices.dart';
import '../staff/admin_kit.dart';
import '../staff/staff_order_screen.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'order_detail_screen.dart';

const _kIcons = {
  'order': Icons.shopping_bag_outlined,
  'queue': Icons.format_list_bulleted,
  'status': Icons.timelapse,
  'ship': Icons.local_shipping_outlined,
  'stock': Icons.warning_amber_rounded,
  'cancel': Icons.cancel_outlined,
  'late': Icons.schedule,
  'review': Icons.star_outline,
};

Color _tone(String t) => switch (t) {
      'stock' || 'late' => Brule.amber,
      'cancel' => Brule.red,
      _ => Brule.blueText,
    };

/// Pusat notifikasi untuk semua peran. Staf juga melihat ringkasan "perlu perhatian" di atas.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _v = 0;
  bool _busy = false;

  Future<void> _readAll() async {
    setState(() => _busy = true);
    try {
      await Api.post('/notices/read-all');
      Notices.unread.value = 0;
      if (mounted) setState(() => _v++);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Map<String, dynamic> n) async {
    if (n['read'] != true) {
      try {
        await Api.post('/notices/${n['id']}/read');
      } on ApiException {
        // lanjut saja
      }
      Notices.refresh();
    }
    final code = n['code'];
    if (code == null || !mounted) {
      if (mounted) setState(() => _v++);
      return;
    }
    final staff = Api.user?['role'] != 'customer';
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => staff ? StaffOrderScreen(code: '$code') : OrderDetailScreen(code: '$code'),
    ));
    if (mounted) setState(() => _v++);
  }

  void _goto(String target) {
    Navigator.of(context).pop();
    Notices.goto.value = target;
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Notifikasi',
      child: Column(
        children: [
          Expanded(
            child: PagedList(
              key: ValueKey(_v),
              path: '/notices',
              params: const {},
              groupBy: dayGroup,
              empty: 'Belum ada notifikasi. Kabar pesanan dan stok akan muncul di sini.',
              header: (meta) {
                final alerts = ((meta?['alerts'] ?? []) as List).cast<Map<String, dynamic>>();
                if (alerts.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Label('PERLU PERHATIAN'),
                    for (final a in alerts)
                      Panel(
                        onTap: () => _goto('${a['target']}'),
                        child: Row(
                          children: [
                            Icon(_kIcons['${a['type']}'] ?? Icons.info_outline, color: _tone('${a['type']}')),
                            const SizedBox(width: 12),
                            Expanded(child: Text('${a['text']}')),
                            Icon(Icons.chevron_right, color: Brule.kraft),
                          ],
                        ),
                      ),
                  ],
                );
              },
              item: (context, n, refresh) {
                final type = '${n['type']}';
                final unread = n['read'] != true;
                return Panel(
                  onTap: () => _open(n),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _tone(type).withValues(alpha: 0.5)),
                        ),
                        child: Icon(_kIcons[type] ?? Icons.notifications_none, size: 18, color: _tone(type)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${n['title']}',
                                    style: TextStyle(
                                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                                      color: unread ? Brule.cream : Brule.kraft,
                                    ),
                                  ),
                                ),
                                Text(clockOf(n['created_at']), style: Brule.mono(9.5)),
                              ],
                            ),
                            if (n['body'] != null) ...[
                              const SizedBox(height: 2),
                              Text('${n['body']}', style: Brule.mono(10), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ],
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        Container(
                                                    width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: Brule.amber, shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          BottomBar(
            child: FilledButton.icon(
              onPressed: _busy ? null : _readAll,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('TANDAI SEMUA DIBACA'),
            ),
          ),
        ],
      ),
    );
  }
}
