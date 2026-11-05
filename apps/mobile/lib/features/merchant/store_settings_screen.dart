import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/bento_card.dart';
import '../catalog/catalog_data.dart';
import '../landmarks/landmark_data.dart';

/// Screen 21 — UMKM Store Settings & Payout Profile (M15).
class StoreSettingsScreen extends ConsumerStatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  ConsumerState<StoreSettingsScreen> createState() =>
      _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _bankName;
  late final TextEditingController _accountNumber;
  late final TextEditingController _accountHolder;
  late String _landmarkId;
  TimeOfDay _openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 20, minute: 0);
  bool _qrisAttached = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final merchant = CatalogData.byId('merchant-kantin');
    _name = TextEditingController(text: merchant.name);
    _description = TextEditingController(text: merchant.description);
    _bankName = TextEditingController(text: 'Bank Syariah Indonesia');
    _accountNumber = TextEditingController(text: '7123456789');
    _accountHolder = TextEditingController(text: 'Siti Aminah');
    _landmarkId = merchant.landmarkId;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _bankName.dispose();
    _accountNumber.dispose();
    _accountHolder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final open = ref.watch(demoMerchantOpenProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Toko'),
        actions: [
          IconButton(
            onPressed: () => context.go('/merchant'),
            icon: const Icon(Icons.dashboard_outlined),
            tooltip: 'Dashboard',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
            children: [
              BentoCard(
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded, color: Ce.emerald500),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Profil toko tampil di katalog konsumen. Pastikan nama, '
                        'lokasi, dan jam buka akurat.',
                        style: TextStyle(fontSize: 11, color: Ce.textMuted),
                      ),
                    ),
                    Switch(
                      value: open,
                      activeThumbColor: Ce.emerald500,
                      onChanged: (value) => ref
                          .read(demoMerchantOpenProvider.notifier)
                          .setOpen(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle(title: 'Identitas toko'),
              BentoCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      maxLength: 40,
                      decoration: const InputDecoration(
                        labelText: 'Nama toko',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.length < 3) return 'Nama minimal 3 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _description,
                      maxLength: 140,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi singkat',
                        hintText: 'Masakan rumahan, siap 15 menit…',
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _landmarkId,
                      decoration: const InputDecoration(
                        labelText: 'Landmark toko',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      items: [
                        for (final landmark in LandmarkData.all)
                          DropdownMenuItem(
                            value: landmark.id,
                            child: Text(landmark.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _landmarkId = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle(
                title: 'Jam operasional',
                subtitle: 'Toko ditutup otomatis di luar jam ini.',
              ),
              BentoCard(
                child: Row(
                  children: [
                    Expanded(
                      child: _TimeField(
                        label: 'Buka',
                        value: _openTime,
                        onTap: () => _pickTime(isOpen: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TimeField(
                        label: 'Tutup',
                        value: _closeTime,
                        onTap: () => _pickTime(isOpen: false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle(
                title: 'Pembayaran & payout',
                subtitle:
                    'QRIS statis untuk pembayaran, rekening untuk payout.',
              ),
              BentoCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _qrisAttached
                              ? Icons.qr_code_2_rounded
                              : Icons.qr_code_scanner_rounded,
                          color: _qrisAttached ? Ce.emerald500 : Ce.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _qrisAttached
                                ? 'QRIS statis terpasang'
                                : 'QRIS statis belum diunggah',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Ce.text,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _qrisAttached = !_qrisAttached),
                          child: Text(_qrisAttached ? 'Ganti' : 'Unggah'),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    TextFormField(
                      controller: _bankName,
                      decoration: const InputDecoration(
                        labelText: 'Nama bank',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Nama bank wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accountNumber,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Nomor rekening',
                        prefixIcon: Icon(Icons.numbers_rounded),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.length < 8) {
                          return 'Nomor rekening tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _accountHolder,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama pemilik rekening',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) => (value?.trim().length ?? 0) < 3
                          ? 'Nama pemilik wajib diisi'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const InfoBanner(
                message:
                    'Payout dilakukan setiap Senin. Komisi 0,5% sudah dipotong '
                    'dari nilai transaksi. Data rekening hanya dapat diubah '
                    'oleh pemilik toko.',
                icon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Ce.text,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(_saving ? 'Menyimpan…' : 'Simpan pengaturan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime({required bool isOpen}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _openTime : _closeTime,
    );
    if (picked == null) return;
    setState(() {
      if (isOpen) {
        _openTime = picked;
      } else {
        _closeTime = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_qrisAttached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unggah QRIS statis terlebih dahulu.')),
      );
      return;
    }
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Pengaturan toko disimpan.')));
    context.go('/merchant');
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Ce.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Ce.emerald900),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 9.5, color: Ce.textMuted),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: Ce.emerald500,
                ),
                const SizedBox(width: 5),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Ce.text,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
