import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'admin_kit.dart';

const _kShow = {'all': 'Semua', 'live': 'Berlaku', 'ended': 'Tidak berlaku'};

const _kStates = {
  'active': ('BERLAKU', Brule.blueText),
  'inactive': ('MATI', Brule.kraft),
  'scheduled': ('BELUM MULAI', Brule.amber),
  'expired': ('KEDALUWARSA', Brule.red),
  'exhausted': ('KUOTA HABIS', Brule.red),
};

/// Voucher: lihat, buat, ubah, aktif/nonaktif, hapus (jika belum dipakai).
class AdminVouchersScreen extends StatefulWidget {
  const AdminVouchersScreen({super.key});

  @override
  State<AdminVouchersScreen> createState() => _AdminVouchersScreenState();
}

class _AdminVouchersScreenState extends State<AdminVouchersScreen> {
  String _show = 'all';
  int _v = 0;

  Future<void> _form([Map<String, dynamic>? v]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF161616),
      constraints: const BoxConstraints(maxWidth: 560),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) => _VoucherForm(voucher: v),
    );
    if (saved == true && mounted) {
      setState(() => _v++);
      toast(context, 'Voucher tersimpan');
    }
  }

  Future<void> _act(Future<void> Function() a, {String? done}) async {
    if (await runAction(context, a, done: done) && mounted) setState(() => _v++);
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Voucher',
      fab: FloatingActionButton.extended(
        onPressed: () => _form(),
        icon: const Icon(Icons.add),
        label: const Text('VOUCHER BARU'),
      ),
      child: Loader<Map<String, dynamic>>(
        key: ValueKey('$_show|$_v'),
        load: () => Api.get('/admin/vouchers', {'tampil': _show}),
        builder: (context, d, reload) {
          final cn = (d['counts'] ?? {}) as Map;
          final list = ((d['data'] ?? []) as List).cast<Map<String, dynamic>>();
          return RefreshIndicator(
            color: Brule.amber,
            onRefresh: reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              children: [
                ChipPicker<String>(
                  items: _kShow.keys.toList(),
                  value: _show,
                  label: (k) => '${_kShow[k]} ${asInt(cn[k])}',
                  onChanged: (k) => setState(() => _show = k),
                ),
                const SizedBox(height: 10),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('Belum ada voucher.', style: Brule.mono(11))),
                  ),
                for (final v in list) _tile(v),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tile(Map<String, dynamic> v) {
    final st = _kStates['${v['state']}'] ?? ('-', Brule.kraft);
    final percent = v['type'] == 'percent';
    final potongan = percent ? '${asInt(v['value'])}%' : rupiah(asInt(v['value']));
    final used = asInt(v['used_count']);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('${v['code']}', style: Brule.condensed(20, spacing: 1))),
              Tag(st.$1, color: st.$2),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            [
              'Potongan $potongan',
              if (asInt(v['min_subtotal']) > 0) 'min. ${rupiah(asInt(v['min_subtotal']))}',
              if (percent && v['max_discount'] != null) 'maks. ${rupiah(asInt(v['max_discount']))}',
            ].join(' · '),
            style: Brule.mono(10, color: Brule.cream),
          ),
          const SizedBox(height: 2),
          Text(
            [
              'Dipakai $used${v['quota'] == null ? '' : ' / ${v['quota']}'}',
              if (v['starts_at'] != null) 'mulai ${v['starts_at']}',
              if (v['expires_at'] != null) 'sampai ${v['expires_at']}',
            ].join(' · '),
            style: Brule.mono(9.5),
          ),
          if ('${v['note'] ?? ''}'.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('${v['note']}', style: Brule.mono(9.5)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(onPressed: () => _form(v), child: const Text('UBAH')),
              OutlinedButton(
                onPressed: () => _act(() => Api.post('/admin/vouchers/${v['id']}/toggle'),
                    done: v['is_active'] == true ? 'Voucher dimatikan' : 'Voucher diaktifkan'),
                child: Text(v['is_active'] == true ? 'MATIKAN' : 'AKTIFKAN'),
              ),
              if (used == 0)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Brule.red),
                  onPressed: () async {
                    if (await confirmDialog(context, 'Hapus ${v['code']}?', 'Voucher yang belum dipakai akan dihapus permanen.',
                        ok: 'HAPUS', danger: true)) {
                      await _act(() => Api.delete('/admin/vouchers/${v['id']}'), done: 'Voucher dihapus');
                    }
                  },
                  child: const Text('HAPUS'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoucherForm extends StatefulWidget {
  final Map<String, dynamic>? voucher;
  const _VoucherForm({this.voucher});

  @override
  State<_VoucherForm> createState() => _VoucherFormState();
}

class _VoucherFormState extends State<_VoucherForm> {
  late final Map<String, dynamic>? _v = widget.voucher;
  late final _code = TextEditingController(text: '${_v?['code'] ?? ''}');
  late final _value = TextEditingController(text: '${_v?['value'] ?? ''}');
  late final _min = TextEditingController(text: asInt(_v?['min_subtotal']) > 0 ? '${_v?['min_subtotal']}' : '');
  late final _max = TextEditingController(text: '${_v?['max_discount'] ?? ''}');
  late final _quota = TextEditingController(text: '${_v?['quota'] ?? ''}');
  late final _start = TextEditingController(text: '${_v?['starts_at'] ?? ''}');
  late final _end = TextEditingController(text: '${_v?['expires_at'] ?? ''}');
  late final _note = TextEditingController(text: '${_v?['note'] ?? ''}');
  late String _type = '${_v?['type'] ?? 'percent'}';
  late bool _active = _v?['is_active'] ?? true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_code, _value, _min, _max, _quota, _start, _end, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _n(TextEditingController c) => c.text.trim().isEmpty ? null : int.tryParse(c.text.trim());

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = {
      'code': _code.text.trim(),
      'type': _type,
      'value': _n(_value),
      'min_subtotal': _n(_min),
      'max_discount': _type == 'percent' ? _n(_max) : null,
      'quota': _n(_quota),
      'starts_at': _start.text.trim().isEmpty ? null : _start.text.trim(),
      'expires_at': _end.text.trim().isEmpty ? null : _end.text.trim(),
      'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
      'is_active': _active,
    };
    try {
      if (_v == null) {
        await Api.post('/admin/vouchers', body);
      } else {
        await Api.put('/admin/vouchers/${_v!['id']}', body);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate(TextEditingController c) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(c.text) ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (d != null) {
      c.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }

  Widget _field(String label, TextEditingController c, String hint,
      {bool number = false, int? maxLength, TextCapitalization cap = TextCapitalization.none}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Label(label),
        TextField(
          controller: c,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          maxLength: maxLength,
          textCapitalization: cap,
          decoration: InputDecoration(hintText: hint, counterText: ''),
        ),
      ],
    );
  }

  Widget _date(String label, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Label(label),
        TextField(
          controller: c,
          readOnly: true,
          onTap: () => _pickDate(c),
          decoration: InputDecoration(
            hintText: 'contoh: 2026-12-31',
            suffixIcon: c.text.isEmpty
                ? const Icon(Icons.calendar_today, size: 18)
                : IconButton(
                    tooltip: 'Hapus tanggal',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(c.clear),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(_v == null ? 'Voucher baru' : 'Ubah voucher', style: Brule.condensed(22))),
                IconButton(tooltip: 'Tutup', icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            if (_error != null) ...[ErrorBox(_error!), const SizedBox(height: 4)],
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'MENYIMPAN...' : 'SIMPAN VOUCHER'),
            ),
            _field('KODE', _code, 'contoh: HEMAT10', maxLength: 24, cap: TextCapitalization.characters),
            const Label('JENIS POTONGAN'),
            ChipPicker<String>(
              items: const ['percent', 'fixed'],
              value: _type,
              label: (k) => k == 'percent' ? 'Persen (%)' : 'Nominal (Rp)',
              onChanged: (k) => setState(() => _type = k),
            ),
            _field(_type == 'percent' ? 'NILAI (1-100 %)' : 'NILAI (Rp)', _value,
                _type == 'percent' ? 'contoh: 10' : 'contoh: 25000', number: true),
            _field('MINIMAL BELANJA (Rp, OPSIONAL)', _min, 'contoh: 100000', number: true),
            if (_type == 'percent')
              _field('MAKSIMAL POTONGAN (Rp, OPSIONAL)', _max, 'contoh: 50000', number: true),
            _field('KUOTA PEMAKAIAN (OPSIONAL)', _quota, 'contoh: 100', number: true),
            _date('MULAI BERLAKU (OPSIONAL)', _start),
            _date('BERAKHIR (OPSIONAL)', _end),
            _field('CATATAN (OPSIONAL)', _note, 'contoh: Promo pelanggan baru', maxLength: 120),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktif'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
          ],
        ),
      ),
    );
  }
}
