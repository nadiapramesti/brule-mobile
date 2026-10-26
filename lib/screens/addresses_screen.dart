import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

const kMaxAddresses = 5;

/// Buku alamat. Dengan [pick] = true dipakai sebagai pemilih dari checkout.
class AddressesScreen extends StatefulWidget {
  final bool pick;
  const AddressesScreen({super.key, this.pick = false});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  int _v = 0;

  Future<List<Address>> _load() async {
    final res = await Api.get('/addresses');
    return (res['data'] as List)
        .map((e) => Address.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _reload() => setState(() => _v++);

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _form([Address? a]) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddressFormScreen(address: a)),
    );
    if (ok == true) _reload();
  }

  Future<void> _makeDefault(Address a) async {
    try {
      await Api.post('/addresses/${a.id}/default');
      _reload();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _delete(Address a) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Brule.field,
        title: Text('Hapus alamat "${a.label}"?', style: Brule.condensed(20)),
        content: const Text('Alamat ini dihapus dari buku alamatmu.'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('BATAL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(96, 44),
              backgroundColor: Brule.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await Api.delete('/addresses/${a.id}');
      _reload();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pick ? 'PILIH ALAMAT' : 'BUKU ALAMAT')),
      body: Narrow(
        child: Loader<List<Address>>(
          key: ValueKey(_v),
          load: _load,
          builder: (context, list, _) {
            final full = list.length >= kMaxAddresses;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                FilledButton.icon(
                  onPressed: full ? null : () => _form(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('TAMBAH ALAMAT'),
                ),
                const SizedBox(height: 6),
                Text(
                  full
                      ? 'Maksimal $kMaxAddresses alamat tersimpan.'
                      : '${list.length} dari $kMaxAddresses alamat tersimpan',
                  style: Brule.mono(10),
                ),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(Icons.location_off_outlined,
                            size: 52, color: Brule.kraft.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text('Belum ada alamat tersimpan.'),
                        const SizedBox(height: 4),
                        Text('Simpan sekali, checkout jadi lebih cepat.',
                            style: Brule.mono(11)),
                      ],
                    ),
                  ),
                for (final a in list)
                  _AddressCard(
                    a: a,
                    pick: widget.pick,
                    onUse: () => Navigator.of(context).pop(a),
                    onEdit: () => _form(a),
                    onDefault: () => _makeDefault(a),
                    onDelete: () => _delete(a),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address a;
  final bool pick;
  final VoidCallback onUse;
  final VoidCallback onEdit;
  final VoidCallback onDefault;
  final VoidCallback onDelete;
  const _AddressCard({
    required this.a,
    required this.pick,
    required this.onUse,
    required this.onEdit,
    required this.onDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const small = Size(0, 42);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Brule.field,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: a.isDefault
              ? Brule.amber.withValues(alpha: 0.5)
              : Brule.hair(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tag(a.label.toUpperCase()),
              if (a.isDefault) ...[
                const SizedBox(width: 8),
                Tag('UTAMA', color: Brule.amber),
              ],
              const Spacer(),
              if (!pick)
                IconButton(
                  tooltip: 'Hapus',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(a.recipient, style: Brule.condensed(18)),
          const SizedBox(height: 2),
          Text(a.phone, style: Brule.mono(11, color: Brule.amber)),
          const SizedBox(height: 8),
          Text(a.address,
              style: TextStyle(color: Brule.kraft.withValues(alpha: 0.9), height: 1.45)),
          const SizedBox(height: 14),
          if (pick)
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: small),
              onPressed: onUse,
              child: const Text('PAKAI ALAMAT INI'),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: small),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: const Text('EDIT'),
                  ),
                ),
                if (!a.isDefault) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: small),
                      onPressed: onDefault,
                      child: const Text('JADIKAN UTAMA'),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class AddressFormScreen extends StatefulWidget {
  final Address? address;
  const AddressFormScreen({super.key, this.address});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  late final _label = TextEditingController(text: widget.address?.label ?? '');
  late final _recipient = TextEditingController(
      text: widget.address?.recipient ?? '${Api.user?['name'] ?? ''}');
  late final _phone = TextEditingController(
      text: widget.address?.phone ?? '${Api.user?['phone'] ?? ''}');
  late final _address = TextEditingController(text: widget.address?.address ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _recipient.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_label.text.trim().isEmpty) return 'Nama alamat wajib diisi, contoh: Rumah.';
    if (_recipient.text.trim().isEmpty) return 'Nama penerima wajib diisi.';
    if (!RegExp(r'^(\+62|62|0)8[0-9]{7,12}$').hasMatch(_phone.text.trim())) {
      return 'Nomor WhatsApp tidak valid. Contoh: 0812xxxxxxxx';
    }
    if (_address.text.trim().length < 15) {
      return 'Alamat terlalu pendek. Tulis jalan, nomor, kota, dan kode pos.';
    }
    return null;
  }

  Future<void> _save() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = {
      'label': _label.text.trim(),
      'recipient': _recipient.text.trim(),
      'phone': _phone.text.trim(),
      'address': _address.text.trim(),
    };
    try {
      if (widget.address == null) {
        await Api.post('/addresses', body);
      } else {
        await Api.put('/addresses/${widget.address!.id}', body);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.address == null ? 'ALAMAT BARU' : 'EDIT ALAMAT')),
      body: Narrow(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const Label('NAMA ALAMAT'),
            TextField(
              controller: _label,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'contoh: Rumah, Kantor'),
            ),
            const Label('NAMA PENERIMA'),
            TextField(
              controller: _recipient,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'contoh: Nadia Pramesti'),
            ),
            const Label('NOMOR WHATSAPP'),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'contoh: 081234567890'),
            ),
            const Label('ALAMAT LENGKAP'),
            TextField(
              controller: _address,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'contoh: Jl. Melati No. 5, Karawang, 41361',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              ErrorBox(_error!),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'MENYIMPAN...' : 'SIMPAN ALAMAT'),
            ),
          ],
        ),
      ),
    );
  }
}
