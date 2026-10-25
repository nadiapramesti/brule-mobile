import 'package:flutter/material.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'admin_kit.dart';

const _kTabs = {
  '': 'Semua',
  'ordered': 'Pernah pesan',
  'repeat': 'Langganan',
  'never': 'Belum pesan',
  'new': 'Baru (30 hari)',
};
const _kSorts = {
  'newest': 'Terbaru',
  'spent': 'Total belanja',
  'orders': 'Jumlah pesanan',
  'last': 'Terakhir pesan',
};

/// Daftar pelanggan: statistik, filter, urutan, pencarian.
class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  String _tab = '';
  String _sort = 'newest';
  String _q = '';

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Pelanggan',
      child: PagedList(
        key: ValueKey('$_tab|$_sort|$_q'),
        path: '/admin/customers',
        params: {'tab': _tab, 'sort': _sort, if (_q.isNotEmpty) 'q': _q},
        empty: 'Belum ada pelanggan yang cocok.',
        header: (meta) {
          final st = (meta?['stats'] ?? {}) as Map;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stat('TOTAL', '${asInt(st['total'])}'),
                  Stat('PERNAH PESAN', '${asInt(st['ordered'])}'),
                  Stat('LANGGANAN', '${asInt(st['repeat'])}'),
                  Stat('KONVERSI', '${asInt(st['conversion'])}%'),
                ],
              ),
              const SizedBox(height: 10),
              SearchBox(hint: 'cari nama, email, atau nomor HP', onChanged: (v) => setState(() => _q = v.trim())),
              const SizedBox(height: 10),
              ChipPicker<String>(
                items: _kTabs.keys.toList(),
                value: _tab,
                label: (k) => _kTabs[k]!,
                onChanged: (k) => setState(() => _tab = k),
              ),
              const Label('URUTKAN'),
              ChipPicker<String>(
                items: _kSorts.keys.toList(),
                value: _sort,
                label: (k) => _kSorts[k]!,
                onChanged: (k) => setState(() => _sort = k),
              ),
            ],
          );
        },
        item: (context, c, refresh) => Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('${c['name']}', style: Brule.condensed(18))),
                  if (c['blocked'] == true) const Tag('DIBLOKIR', color: Brule.red),
                ],
              ),
              const SizedBox(height: 2),
              Text('${c['email']}${c['phone'] == null ? '' : ' · ${c['phone']}'}', style: Brule.mono(10)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('${asInt(c['orders'])} pesanan', style: Brule.mono(10, color: Brule.cream)),
                  const Spacer(),
                  Text(rupiah(asInt(c['spent'])), style: Brule.condensed(17)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                [
                  'Gabung ${dayMonth('${c['joined_at']}')}',
                  if (c['last_order_at'] != null) 'Terakhir pesan ${dayMonth('${c['last_order_at']}')}',
                ].join(' · '),
                style: Brule.mono(9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
