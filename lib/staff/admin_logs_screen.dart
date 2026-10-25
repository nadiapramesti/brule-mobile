import 'package:flutter/material.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'admin_kit.dart';

/// Log aktivitas: siapa mengubah apa, dengan filter jenis.
class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  String _g = '';

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Log aktivitas',
      child: PagedList(
        key: ValueKey(_g),
        path: '/admin/logs',
        params: {'jenis': _g},
        empty: 'Belum ada aktivitas tercatat.',
        header: (meta) {
          final groups = ((meta?['groups'] ?? []) as List).cast<Map<String, dynamic>>();
          final labels = {'': 'Semua', for (final g in groups) '${g['key']}': '${g['label']}'};
          return ChipPicker<String>(
            items: labels.keys.toList(),
            value: _g,
            label: (k) => labels[k]!,
            onChanged: (k) => setState(() => _g = k),
          );
        },
        item: (context, l, refresh) => Panel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l['text']}', style: const TextStyle(height: 1.35)),
              const SizedBox(height: 4),
              Text('${l['by'] ?? 'Sistem'} · ${dateTime('${l['created_at']}')}', style: Brule.mono(9)),
            ],
          ),
        ),
      ),
    );
  }
}
