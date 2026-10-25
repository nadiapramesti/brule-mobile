import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../widgets.dart';
import 'order_row.dart';
import 'staff_order_screen.dart';

/// Semua pesanan untuk admin: filter status, cari, dan buka detail.
class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  final List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _tabs = [];
  String _tab = '';
  String _q = '';
  int _page = 0;
  int _last = 1;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);
  }

  Future<void> _fetch({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _page = 0;
        _last = 1;
      }
    });
    try {
      final res = await Api.get('/admin/orders', {
        'tab': _tab,
        if (_q.isNotEmpty) 'q': _q,
        'page': '${_page + 1}',
      });
      if (!mounted) return;
      setState(() {
        _items.addAll(((res['data'] ?? []) as List).cast<Map<String, dynamic>>());
        _tabs = ((res['tabs'] ?? []) as List).cast<Map<String, dynamic>>();
        _page = (res['page'] as num).toInt();
        _last = (res['last_page'] as num).toInt();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(String code) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => StaffOrderScreen(code: code)));
    if (mounted) _fetch(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 18, height: 3, color: Brule.amber),
                    const SizedBox(width: 10),
                    Text('SEMUA PESANAN', style: Brule.condensed(22, spacing: 2)),
                  ],
                ),
                const SizedBox(height: 12),
                SearchBox(
                  hint: 'cari kode, nama, email, atau resi',
                  onChanged: (v) {
                    _q = v;
                    _fetch(reset: true);
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final t in _tabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${t['label']} · ${t['count']}'),
                      selected: _tab == '${t['key']}',
                      onSelected: (_) {
                        _tab = '${t['key']}';
                        _fetch(reset: true);
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Brule.amber,
              onRefresh: () => _fetch(reset: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (_error != null) ErrorBox(_error!),
                  if (_items.isEmpty && !_loading && _error == null)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Tidak ada pesanan.')),
                    ),
                  for (final o in _items)
                    OrderRow(o: o, showTotal: true, onTap: () => _open('${o['code']}')),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator(color: Brule.amber)),
                    )
                  else if (_page < _last)
                    OutlinedButton(
                      onPressed: _fetch,
                      child: const Text('MUAT LEBIH BANYAK'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
