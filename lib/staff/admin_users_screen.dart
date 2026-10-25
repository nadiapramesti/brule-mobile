import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'admin_kit.dart';

const _kRoles = {
  '': 'Semua',
  'admin': 'Admin',
  'roaster': 'Roaster',
  'customer': 'Customer',
  'blocked': 'Diblokir',
};

/// Pengguna: semua peran, cari, blokir atau buka blokir akun pembeli.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _role = '';
  String _q = '';

  Future<void> _block(Map<String, dynamic> u, Future<void> Function() refresh) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Blokir ${u['name']}?', style: Brule.condensed(20)),
        content: TextField(
          controller: c,
          maxLength: 300,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'alasan (opsional), contoh: pesanan fiktif berulang'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('BATAL')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44), backgroundColor: Brule.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('BLOKIR'),
          ),
        ],
      ),
    );
    final reason = c.text.trim();
    c.dispose();
    if (ok != true || !mounted) return;
    final done = await runAction(context, () => Api.post('/admin/users/${u['id']}/block', {'reason': reason}),
        done: '${u['name']} diblokir');
    if (done) await refresh();
  }

  Future<void> _unblock(Map<String, dynamic> u, Future<void> Function() refresh) async {
    final done = await runAction(context, () => Api.post('/admin/users/${u['id']}/unblock'),
        done: 'Blokir ${u['name']} dibuka');
    if (done) await refresh();
  }

  Color _roleColor(String r) => r == 'admin' ? Brule.amber : (r == 'roaster' ? Brule.blueText : Brule.kraft);

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Pengguna',
      child: PagedList(
        key: ValueKey('$_role|$_q'),
        path: '/admin/users',
        params: {'role': _role, if (_q.isNotEmpty) 'q': _q},
        header: (meta) {
          final cn = (meta?['counts'] ?? {}) as Map;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SearchBox(hint: 'cari nama, email, atau nomor HP', onChanged: (v) => setState(() => _q = v.trim())),
              const SizedBox(height: 10),
              ChipPicker<String>(
                items: _kRoles.keys.toList(),
                value: _role,
                label: (k) => '${_kRoles[k]} ${asInt(cn[k == '' ? 'all' : k])}',
                onChanged: (k) => setState(() => _role = k),
              ),
              const SizedBox(height: 4),
              Text('Tambah staf, ubah peran, dan hapus akun dilakukan lewat panel web.', style: Brule.mono(9)),
            ],
          );
        },
        item: (context, u, refresh) {
          final role = '${u['role']}';
          final staff = role != 'customer';
          final blocked = u['blocked'] == true;
          return Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('${u['name']}${u['is_me'] == true ? ' (kamu)' : ''}', style: Brule.condensed(18))),
                    Tag(role.toUpperCase(), color: _roleColor(role)),
                    if (blocked) ...[const SizedBox(width: 6), const Tag('DIBLOKIR', color: Brule.red)],
                  ],
                ),
                const SizedBox(height: 2),
                Text('${u['email']}${u['phone'] == null ? '' : ' · ${u['phone']}'}', style: Brule.mono(10)),
                if (blocked && u['blocked_reason'] != null) ...[
                  const SizedBox(height: 4),
                  Text('Alasan: ${u['blocked_reason']}', style: Brule.mono(9.5, color: Brule.red)),
                ],
                if (!staff) ...[
                  const SizedBox(height: 4),
                  Text('${asInt(u['orders'])} pesanan', style: Brule.mono(9.5)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: blocked
                        ? OutlinedButton(onPressed: () => _unblock(u, refresh), child: const Text('BUKA BLOKIR'))
                        : OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: Brule.red),
                            onPressed: () => _block(u, refresh),
                            child: const Text('BLOKIR'),
                          ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
