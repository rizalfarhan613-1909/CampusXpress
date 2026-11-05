import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/bento_card.dart';

/// Screen 15 — Admin Zone & Approval Panel (M19).
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  String _tab = 'Driver';
  final List<_DriverRequest> _drivers = [
    _DriverRequest(
      name: 'Ahmad Fauzi',
      nim: '221234567891',
      vehicle: 'Honda Vario · B 1234 XY',
      submitted: DateTime.now().subtract(const Duration(minutes: 25)),
      docsComplete: true,
    ),
    _DriverRequest(
      name: 'Sari Dewi',
      nim: '221234567892',
      vehicle: 'Yamaha NMAX · B 5678 ZZ',
      submitted: DateTime.now().subtract(const Duration(hours: 2)),
      docsComplete: false,
    ),
    _DriverRequest(
      name: 'Rizky Pratama',
      nim: '221234567893',
      vehicle: 'Honda Beat · B 9012 AB',
      submitted: DateTime.now().subtract(const Duration(hours: 5)),
      docsComplete: true,
    ),
  ];
  final List<_TopUpRequest> _topUps = [
    _TopUpRequest(
      driver: 'Dimas Driver',
      amount: 50000,
      submitted: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    _TopUpRequest(
      driver: 'Ahmad Fauzi',
      amount: 25000,
      submitted: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];
  bool _autoClose = true;
  bool _chatFilter = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
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
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Driver pending',
                    value: '${_drivers.length}',
                    icon: Icons.two_wheeler_rounded,
                    color: Ce.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                    label: 'Top-up pending',
                    value: '${_topUps.length}',
                    icon: Icons.account_balance_wallet_rounded,
                    color: Ce.info,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: _Stat(
                    label: 'Dispute aktif',
                    value: '2',
                    icon: Icons.gavel_rounded,
                    color: Ce.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Driver',
                  label: Text('Driver'),
                  icon: Icon(Icons.badge_outlined, size: 16),
                ),
                ButtonSegment(
                  value: 'Top-up',
                  label: Text('Top-up'),
                  icon: Icon(Icons.payments_outlined, size: 16),
                ),
                ButtonSegment(
                  value: 'Config',
                  label: Text('Config'),
                  icon: Icon(Icons.tune_rounded, size: 16),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (value) => setState(() => _tab = value.first),
            ),
            const SizedBox(height: 14),
            if (_tab == 'Driver')
              _buildDrivers()
            else if (_tab == 'Top-up')
              _buildTopUps()
            else
              _buildConfig(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrivers() {
    if (_drivers.isEmpty) {
      return const EmptyState(
        title: 'Antrean verifikasi kosong',
        message: 'Semua pengajuan driver sudah diproses.',
        icon: Icons.verified_rounded,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Verifikasi driver',
          subtitle: 'Periksa KTM, SIM, dan data kendaraan sebelum menyetujui.',
        ),
        for (final driver in _drivers)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BentoCard(
              borderColor: driver.docsComplete ? Ce.emerald900 : Ce.warning,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Ce.emerald600,
                        child: Text(
                          driver.name.substring(0, 1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Ce.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driver.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Ce.text,
                              ),
                            ),
                            Text(
                              'NIM ${driver.nim} · ${driver.vehicle}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Ce.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusPill(
                        label: driver.docsComplete ? 'Lengkap' : 'Kurang',
                        color: driver.docsComplete ? Ce.emerald500 : Ce.warning,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: Ce.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Diajukan ${timeAgo(driver.submitted)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Ce.textMuted,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _decideDriver(driver, false),
                        child: const Text('Tolak'),
                      ),
                      const SizedBox(width: 4),
                      FilledButton(
                        onPressed: driver.docsComplete
                            ? () => _decideDriver(driver, true)
                            : null,
                        child: const Text('Setujui'),
                      ),
                    ],
                  ),
                  if (!driver.docsComplete)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Dokumen belum lengkap. Minta driver mengunggah ulang SIM.',
                        style: TextStyle(fontSize: 9.5, color: Ce.warning),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopUps() {
    if (_topUps.isEmpty) {
      return const EmptyState(
        title: 'Tidak ada top-up pending',
        message: 'Semua pengajuan top-up sudah diproses.',
        icon: Icons.account_balance_wallet_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Persetujuan top-up',
          subtitle: 'Cocokkan bukti QRIS dengan mutasi sebelum menyetujui.',
        ),
        for (final topUp in _topUps)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BentoCard(
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: Ce.emerald500),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topUp.driver,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Ce.text,
                          ),
                        ),
                        Text(
                          '${formatRupiah(topUp.amount)} · '
                          '${timeAgo(topUp.submitted)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Ce.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _decideTopUp(topUp, false),
                    icon: const Icon(Icons.close_rounded, color: Ce.danger),
                    tooltip: 'Tolak',
                  ),
                  FilledButton(
                    onPressed: () => _decideTopUp(topUp, true),
                    child: const Text('Setujui'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Konfigurasi platform',
          subtitle: 'Perubahan berlaku untuk order baru.',
        ),
        BentoCard(
          child: Column(
            children: [
              _ConfigRow(
                label: 'Komisi platform',
                value: '0,5%',
                icon: Icons.percent_rounded,
              ),
              const Divider(height: 20),
              _ConfigRow(
                label: 'Batas COD',
                value: formatRupiah(AppConfig.codMax),
                icon: Icons.payments_outlined,
              ),
              const Divider(height: 20),
              _ConfigRow(
                label: 'Maks. order',
                value: formatRupiah(AppConfig.orderMax),
                icon: Icons.shopping_cart_outlined,
              ),
              const Divider(height: 20),
              _ConfigRow(
                label: 'Maks. pekerjaan aktif',
                value: '${AppConfig.maxActiveJobsPerDriver} per driver',
                icon: Icons.work_outline_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        BentoCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _autoClose,
                activeThumbColor: Ce.emerald500,
                title: const Text(
                  'Tutup toko otomatis',
                  style: TextStyle(fontSize: 13, color: Ce.text),
                ),
                subtitle: const Text(
                  'Toko ditutup di luar jam operasional.',
                  style: TextStyle(fontSize: 10, color: Ce.textMuted),
                ),
                onChanged: (value) => setState(() => _autoClose = value),
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _chatFilter,
                activeThumbColor: Ce.emerald500,
                title: const Text(
                  'Filter kata kasar chat',
                  style: TextStyle(fontSize: 13, color: Ce.text),
                ),
                subtitle: const Text(
                  'Pesan terflag otomatis masuk antrean moderasi.',
                  style: TextStyle(fontSize: 10, color: Ce.textMuted),
                ),
                onChanged: (value) => setState(() => _chatFilter = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const InfoBanner(
          message:
              'Konfigurasi produksi dibaca dari config/app. Nilai di layar ini '
              'adalah fallback lokal sesuai Rules.md.',
          icon: Icons.info_outline_rounded,
        ),
      ],
    );
  }

  void _decideDriver(_DriverRequest driver, bool approve) {
    setState(() => _drivers.remove(driver));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approve
              ? '${driver.name} disetujui sebagai driver.'
              : '${driver.name} ditolak. Alasan dikirim ke email kampus.',
        ),
      ),
    );
  }

  void _decideTopUp(_TopUpRequest topUp, bool approve) {
    setState(() => _topUps.remove(topUp));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approve
              ? 'Top-up ${formatRupiah(topUp.amount)} ${topUp.driver} disetujui.'
              : 'Top-up ${topUp.driver} ditolak. Bukti tidak cocok.',
        ),
      ),
    );
  }
}

class _DriverRequest {
  const _DriverRequest({
    required this.name,
    required this.nim,
    required this.vehicle,
    required this.submitted,
    required this.docsComplete,
  });

  final String name;
  final String nim;
  final String vehicle;
  final DateTime submitted;
  final bool docsComplete;
}

class _TopUpRequest {
  const _TopUpRequest({
    required this.driver,
    required this.amount,
    required this.submitted,
  });

  final String driver;
  final int amount;
  final DateTime submitted;
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Ce.text,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 8.5, color: Ce.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Ce.emerald500),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Ce.textMuted),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Ce.text,
          ),
        ),
      ],
    );
  }
}
