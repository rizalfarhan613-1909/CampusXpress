import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/models/wallet.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/bento_card.dart';

/// Screen 11 — Driver Prepaid Wallet & Top-Up (M13).
class DriverWalletScreen extends ConsumerStatefulWidget {
  const DriverWalletScreen({super.key});

  @override
  ConsumerState<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends ConsumerState<DriverWalletScreen> {
  final List<_TopUpRequest> _requests = [];

  @override
  Widget build(BuildContext context) {
    final demo = AppConfig.demoMode;
    final user = ref.watch(authStateProvider).value;
    final balance = demo
        ? ref.watch(demoWalletBalanceProvider)
        : (user?.walletBalance ?? 0);
    final ledger = demo ? ref.watch(demoWalletTxProvider) : const <WalletTx>[];
    final low = balance < AppConfig.driverLowBalanceWarn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dompet Driver'),
        actions: [
          IconButton(
            onPressed: () => context.go('/driver/radar'),
            icon: const Icon(Icons.radar_rounded),
            tooltip: 'Radar order',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: Ce.emerald500,
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 350));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
            children: [
              BentoCard(
                borderColor: low ? Ce.warning : Ce.emerald500,
                color: const Color(0xFF0B2C20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Ce.emerald500,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Saldo deposit',
                          style: TextStyle(fontSize: 12, color: Ce.textMuted),
                        ),
                        const Spacer(),
                        StatusPill(
                          label: low ? 'Saldo rendah' : 'Sehat',
                          color: low ? Ce.warning : Ce.emerald500,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formatRupiah(balance),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: balance < AppConfig.driverMinBalance
                            ? Ce.danger
                            : Ce.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      balance < AppConfig.driverMinBalance
                          ? 'Minimal ${formatRupiah(AppConfig.driverMinBalance)} '
                                'untuk dapat mengklaim order.'
                          : 'Komisi 0,5% dipotong otomatis saat order selesai.',
                      style: TextStyle(
                        fontSize: 11,
                        color: balance < AppConfig.driverMinBalance
                            ? Ce.danger
                            : Ce.textMuted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _openTopUp(),
                            icon: const Icon(Icons.add_card_rounded, size: 18),
                            label: const Text('Top-Up QRIS'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          onPressed: () => _showRules(),
                          icon: const Icon(Icons.info_outline_rounded),
                          tooltip: 'Aturan dompet',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (low) ...[
                const SizedBox(height: 10),
                InfoBanner(
                  message: balance < AppConfig.driverMinBalance
                      ? 'Saldo di bawah batas klaim. Top-up minimal '
                            '${formatRupiah(AppConfig.topupMin)} agar radar aktif.'
                      : 'Saldo mendekati batas klaim. Segera top-up.',
                  icon: Icons.warning_amber_rounded,
                  color: Ce.warning,
                ),
              ],
              if (_requests.isNotEmpty) ...[
                const SizedBox(height: 16),
                const SectionTitle(
                  title: 'Pengajuan top-up',
                  subtitle: 'Diproses admin maksimal 1×24 jam.',
                ),
                for (final request in _requests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BentoCard(
                      padding: const EdgeInsets.all(12),
                      borderColor: request.approved
                          ? Ce.emerald500
                          : Ce.warning,
                      child: Row(
                        children: [
                          Icon(
                            request.approved
                                ? Icons.check_circle_rounded
                                : Icons.hourglass_top_rounded,
                            color: request.approved
                                ? Ce.emerald500
                                : Ce.warning,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatRupiah(request.amount),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Ce.text,
                                  ),
                                ),
                                Text(
                                  request.approved
                                      ? 'Disetujui · saldo sudah ditambahkan'
                                      : 'Menunggu persetujuan admin',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Ce.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusPill(
                            label: request.approved ? 'Disetujui' : 'Pending',
                            color: request.approved
                                ? Ce.emerald500
                                : Ce.warning,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              const SectionTitle(
                title: 'Riwayat transaksi',
                subtitle:
                    'Ledger append-only; saldo tidak dapat diubah manual.',
              ),
              if (ledger.isEmpty)
                const EmptyState(
                  title: 'Belum ada transaksi',
                  message: 'Top-up dan potongan komisi akan tampil di sini.',
                  icon: Icons.receipt_long_outlined,
                )
              else
                for (final tx in ledger)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BentoCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: (tx.isCredit ? Ce.emerald500 : Ce.danger)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              tx.isCredit
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded,
                              size: 18,
                              color: tx.isCredit ? Ce.emerald500 : Ce.danger,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Ce.text,
                                  ),
                                ),
                                Text(
                                  '${tx.type.label} · ${timeAgo(tx.createdAt)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Ce.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${tx.isCredit ? '+' : ''}${formatRupiah(tx.amount)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: tx.isCredit ? Ce.emerald500 : Ce.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 14),
              const InfoBanner(
                message:
                    'Top-up diproses manual oleh admin. Simpan bukti QRIS sampai '
                    'saldo masuk. Komisi hanya 0,5% per order selesai.',
                icon: Icons.verified_user_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTopUp() async {
    final amount = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _TopUpSheet(),
    );
    if (amount == null || !mounted) return;

    final request = _TopUpRequest(amount: amount);
    setState(() => _requests.insert(0, request));
    try {
      if (!AppConfig.demoMode) {
        await ref
            .read(gatewayClientProvider)
            .topUp(amount: amount, proofKey: 'pending-upload');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim pengajuan. Coba lagi.')),
        );
      }
    }

    // Demo: admin menyetujui otomatis setelah 1,5 detik agar saldo bisa dipakai.
    if (AppConfig.demoMode) {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      ref.read(demoWalletBalanceProvider.notifier).topUp(amount);
      setState(() => request.approved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Top-up ${formatRupiah(amount)} disetujui admin (demo).',
            ),
          ),
        );
      }
    }
  }

  void _showRules() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aturan dompet driver'),
        content: const Text(
          '• Saldo minimal Rp 5.000 untuk klaim order.\n'
          '• Maksimal 2 pekerjaan aktif bersamaan.\n'
          '• Komisi 0,5% dipotong dari saldo saat PIN serah-terima valid.\n'
          '• Top-up diproses admin; tidak ada penarikan saldo di aplikasi v1.',
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
}

class _TopUpRequest {
  _TopUpRequest({required this.amount});

  final int amount;
  bool approved = false;
}

class _TopUpSheet extends ConsumerStatefulWidget {
  const _TopUpSheet();

  @override
  ConsumerState<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends ConsumerState<_TopUpSheet> {
  final _controller = TextEditingController(text: '25000');
  bool _proofAttached = false;
  String? _error;

  static const _presets = [10000, 25000, 50000, 100000];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _amount => int.tryParse(_controller.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final amount = _amount;
    final valid =
        amount >= AppConfig.topupMin &&
        amount <= AppConfig.topupMax &&
        _proofAttached;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top-Up Saldo Driver',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Ce.text,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Transfer ke QRIS statis Campus Express, lalu unggah bukti. '
            'Admin menyetujui manual.',
            style: TextStyle(fontSize: 11, color: Ce.textMuted, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _presets)
                ChoiceChip(
                  label: Text(formatRupiah(preset)),
                  selected: amount == preset,
                  onSelected: (_) {
                    _controller.text = '$preset';
                    setState(() => _error = null);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Nominal top-up',
              prefixText: 'Rp ',
              helperText:
                  'Min ${formatRupiah(AppConfig.topupMin)} · maks ${formatRupiah(AppConfig.topupMax)}',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          BentoCard(
            borderColor: _proofAttached ? Ce.emerald500 : Ce.warning,
            child: Row(
              children: [
                Icon(
                  _proofAttached
                      ? Icons.check_circle_rounded
                      : Icons.qr_code_2_rounded,
                  color: _proofAttached ? Ce.emerald500 : Ce.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _proofAttached
                            ? 'Bukti QRIS terpasang'
                            : 'QRIS statis + unggah bukti',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Ce.text,
                        ),
                      ),
                      const Text(
                        'Gambar dikompres WebP ≤ 80 KB.',
                        style: TextStyle(fontSize: 10, color: Ce.textMuted),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _proofAttached = true),
                  child: Text(_proofAttached ? 'Ganti' : 'Unggah'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: valid
                  ? () {
                      if (amount < AppConfig.topupMin) {
                        setState(() => _error = 'Nominal minimal Rp 10.000.');
                        return;
                      }
                      Navigator.of(context).pop(amount);
                    }
                  : null,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _proofAttached ? 'Kirim pengajuan' : 'Unggah bukti dulu',
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Saldo baru dapat dipakai setelah admin menyetujui.',
            style: TextStyle(fontSize: 9.5, color: Ce.textMuted),
          ),
        ],
      ),
    );
  }
}
