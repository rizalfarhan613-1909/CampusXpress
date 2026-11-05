import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models/order.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/bento_card.dart';

/// Screen 22 — Dispute Center & Safety Help Desk (M18).
class DisputeCenterScreen extends ConsumerStatefulWidget {
  const DisputeCenterScreen({super.key});

  @override
  ConsumerState<DisputeCenterScreen> createState() =>
      _DisputeCenterScreenState();
}

class _DisputeCenterScreenState extends ConsumerState<DisputeCenterScreen> {
  String _tab = 'Buat';
  String _category = 'Pesanan tidak sesuai';
  final _description = TextEditingController();
  String? _orderId;
  bool _evidence = false;
  bool _submitting = false;
  String? _error;
  final List<_DisputeCase> _cases = [
    _DisputeCase(
      id: 'DSP-1042',
      orderId: 'order-selesai',
      category: 'Pembayaran',
      description: 'Bukti QRIS sudah diunggah tetapi status belum berubah.',
      status: 'Diproses',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static const _categories = [
    'Pesanan tidak sesuai',
    'Pesanan tidak sampai',
    'Item rusak / tumpah',
    'Pembayaran',
    'Perilaku driver/merchant',
    'Lainnya',
  ];

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(demoOrdersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispute & Safety'),
        actions: [
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profil',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
          children: [
            BentoCard(
              borderColor: Ce.danger.withValues(alpha: 0.5),
              color: const Color(0xFF2A1518),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emergency_share_rounded, color: Ce.danger),
                      SizedBox(width: 8),
                      Text(
                        'Darurat di kampus?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Ce.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Gunakan tombol darurat hanya untuk keselamatan: kecelakaan, '
                    'pelecehan, atau barang berbahaya. Untuk kendala biasa, '
                    'buat dispute.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Ce.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _emergency,
                          style: FilledButton.styleFrom(
                            backgroundColor: Ce.danger,
                          ),
                          icon: const Icon(Icons.call_rounded, size: 17),
                          label: const Text('Telepon'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyWhatsApp,
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 17,
                          ),
                          label: const Text('WA Darurat'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Buat',
                  label: Text('Buat dispute'),
                  icon: Icon(Icons.add_comment_outlined, size: 16),
                ),
                ButtonSegment(
                  value: 'Kasus',
                  label: Text('Kasus saya'),
                  icon: Icon(Icons.folder_open_outlined, size: 16),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (value) => setState(() => _tab = value.first),
            ),
            const SizedBox(height: 14),
            if (_tab == 'Buat') _buildForm(orders) else _buildCases(),
            const SizedBox(height: 14),
            const InfoBanner(
              message:
                  'Help Desk kampus: Senin–Jumat 08.00–16.00 WIB · '
                  'helpdesk@campus-express.id · 0812-3456-7890. '
                  'Kasus diselesaikan maksimal 3 hari kerja.',
              icon: Icons.support_agent_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(List<Order> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Buat dispute',
          subtitle: 'Sertakan bukti agar kasus cepat diproses.',
        ),
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _orderId,
                decoration: const InputDecoration(
                  labelText: 'Order terkait',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
                items: [
                  for (final order in orders)
                    DropdownMenuItem(
                      value: order.id,
                      child: Text(
                        '#${order.id} · ${order.type.shortLabel}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _orderId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori masalah',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final category in _categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLength: 500,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi kronologi',
                  hintText:
                      'Contoh: pesanan tiba 30 menit lewat ETA dan minuman tumpah.',
                ),
              ),
              const SizedBox(height: 4),
              _UploadTile(
                attached: _evidence,
                onTap: () => setState(() => _evidence = !_evidence),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                InfoBanner(
                  message: _error!,
                  icon: Icons.error_outline_rounded,
                  color: Ce.danger,
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Ce.text,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_submitting ? 'Mengirim…' : 'Ajukan dispute'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCases() {
    if (_cases.isEmpty) {
      return const EmptyState(
        title: 'Belum ada kasus',
        message: 'Dispute yang kamu buat akan muncul di sini.',
        icon: Icons.folder_open_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Kasus saya',
          subtitle: 'Status diperbarui oleh Help Desk kampus.',
        ),
        for (final dispute in _cases)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BentoCard(
              borderColor: _caseColor(dispute.status).withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dispute.id,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Ce.text,
                        ),
                      ),
                      const Spacer(),
                      StatusPill(
                        label: dispute.status,
                        color: _caseColor(dispute.status),
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dispute.category} · #${dispute.orderId}',
                    style: const TextStyle(fontSize: 10, color: Ce.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dispute.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Ce.text,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        timeAgo(dispute.createdAt),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Ce.textMuted,
                        ),
                      ),
                      const Spacer(),
                      if (dispute.status != 'Selesai')
                        TextButton(
                          onPressed: () => _escalate(dispute),
                          child: const Text('Eskalasi'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _Timeline(status: dispute.status),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static Color _caseColor(String status) {
    return switch (status) {
      'Selesai' => Ce.emerald500,
      'Diproses' => Ce.warning,
      _ => Ce.info,
    };
  }

  Future<void> _submit() async {
    if (_orderId == null) {
      setState(() => _error = 'Pilih order terkait.');
      return;
    }
    if (_description.text.trim().length < 15) {
      setState(() => _error = 'Deskripsi minimal 15 karakter.');
      return;
    }
    if (!_evidence) {
      setState(() => _error = 'Unggah minimal satu bukti (foto/struk).');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final dispute = _DisputeCase(
      id: 'DSP-${DateTime.now().millisecondsSinceEpoch % 10000}',
      orderId: _orderId!,
      category: _category,
      description: _description.text.trim(),
      status: 'Terbuka',
      createdAt: DateTime.now(),
    );
    setState(() {
      _cases.insert(0, dispute);
      _submitting = false;
      _tab = 'Kasus';
      _description.clear();
      _evidence = false;
      _error = null;
    });
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dispute terkirim'),
        content: Text(
          'Kasus ${dispute.id} dibuat. Help Desk akan menghubungi kamu melalui '
          'WhatsApp kampus maksimal 1×24 jam.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _escalate(_DisputeCase dispute) {
    setState(() => dispute.status = 'Diproses');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${dispute.id} dieskalasi ke Help Desk kampus.')),
    );
  }

  Future<void> _emergency() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Telepon darurat?'),
        content: const Text(
          'Nomor Help Desk & Safety: 0812-3456-7890.\n\n'
          'Gunakan hanya untuk situasi keselamatan. Untuk kendala pesanan, '
          'buat dispute agar tercatat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Ce.danger),
            child: const Text('Salin & telepon'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await Clipboard.setData(const ClipboardData(text: '081234567890'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor darurat disalin: 0812-3456-7890')),
      );
    }
  }

  Future<void> _copyWhatsApp() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bagikan nomor ke WhatsApp?'),
        content: const Text(
          'Nomor Help Desk akan disalin ke clipboard. Jangan bagikan PIN atau '
          'data pembayaran melalui WhatsApp.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salin nomor'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await Clipboard.setData(const ClipboardData(text: '+6281234567890'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor WhatsApp Help Desk disalin.')),
      );
    }
  }
}

class _DisputeCase {
  _DisputeCase({
    required this.id,
    required this.orderId,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String category;
  final String description;
  String status;
  final DateTime createdAt;
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({required this.attached, required this.onTap});

  final bool attached;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Ce.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: attached ? Ce.emerald500 : Ce.emerald900),
        ),
        child: Row(
          children: [
            Icon(
              attached
                  ? Icons.check_circle_rounded
                  : Icons.add_photo_alternate_outlined,
              color: attached ? Ce.emerald500 : Ce.textMuted,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                attached
                    ? 'Bukti terpasang · WebP ≤ 80 KB'
                    : 'Unggah foto / struk bukti',
                style: TextStyle(
                  fontSize: 11,
                  color: attached ? Ce.emerald500 : Ce.textMuted,
                ),
              ),
            ),
            Text(
              attached ? 'Ganti' : 'Unggah',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Ce.emerald500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    const steps = ['Terbuka', 'Diproses', 'Selesai'];
    final current = steps.indexOf(status);
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: i <= current ? Ce.emerald500 : Ce.emerald900,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 8,
                    color: i <= current ? Ce.text : Ce.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (i < steps.length - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }
}
