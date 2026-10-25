import 'package:flutter/material.dart';
import 'notices.dart';

/// Ikon bel dengan lencana jumlah notifikasi belum dibaca.
class NoticeBell extends StatelessWidget {
  const NoticeBell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Notices.unread,
      builder: (context, n, _) => IconButton.filledTonal(
        tooltip: 'Notifikasi',
        onPressed: Notices.open,
        icon: Badge(
          label: Text(n > 99 ? '99+' : '$n'),
          isLabelVisible: n > 0,
          child: const Icon(Icons.notifications_none),
        ),
      ),
    );
  }
}
