import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/role_nav.dart';
import '../../core/widgets/bento_card.dart';
import '../auth/profile_setup_screen.dart';

/// Screen 14 — User Profile & Review Shuffle (M16).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Sesi tidak ditemukan.')),
      );
    }
    final demo = AppConfig.demoMode;
    final wallet = demo
        ? ref.watch(demoWalletBalanceProvider)
        : user.walletBalance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            onPressed: _saving ? null : () => _showEditProfile(user),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profil',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
          children: [
            BentoCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Ce.emerald600,
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Ce.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Ce.text,
                              ),
                            ),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Ce.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: Ce.warning,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  user.rating > 0
                                      ? user.rating.toStringAsFixed(1)
                                      : 'Belum ada rating',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Ce.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      StatusPill(
                        label: user.role.label,
                        icon: Icons.verified_user_rounded,
                      ),
                    ],
                  ),
                  const Divider(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _Info(
                          label: 'NIM',
                          value: user.nim.isEmpty ? 'Belum diisi' : user.nim,
                        ),
                      ),
                      Expanded(
                        child: _Info(
                          label: 'WhatsApp',
                          value: user.phone.isEmpty
                              ? 'Belum diisi'
                              : user.phone,
                        ),
                      ),
                    ],
                  ),
                  if (user.isDriver) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 16,
                          color: Ce.emerald500,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Saldo deposit',
                          style: TextStyle(fontSize: 11, color: Ce.textMuted),
                        ),
                        const Spacer(),
                        Text(
                          formatRupiah(wallet),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: wallet < AppConfig.driverMinBalance
                                ? Ce.danger
                                : Ce.emerald500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle(
              title: 'Peran aktif',
              subtitle:
                  'Peran hanya mengubah antarmuka; hak akses tetap '
                  'mengikuti persetujuan admin.',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final role in UserRole.values)
                  if (user.roles.contains(role.code))
                    ChoiceChip(
                      avatar: Icon(
                        _roleIcon(role),
                        size: 15,
                        color: user.role == role ? Ce.text : Ce.emerald500,
                      ),
                      label: Text(role.label),
                      selected: user.role == role,
                      onSelected: (_) => _switchRole(user, role),
                    ),
              ],
            ),
            const SizedBox(height: 16),
            const SectionTitle(title: 'Pintasan'),
            BentoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuRow(
                    icon: Icons.receipt_long_outlined,
                    title: 'Riwayat & e-receipt',
                    subtitle: 'Semua order dan struk digital',
                    onTap: () => context.go('/orders'),
                  ),
                  const Divider(height: 1),
                  if (!user.isDriverApproved)
                    _MenuRow(
                      icon: Icons.two_wheeler_outlined,
                      title: user.isDriver
                          ? 'Status pendaftaran driver'
                          : 'Daftar jadi driver',
                      subtitle: user.isDriver
                          ? 'Cek status verifikasi dokumen'
                          : 'Komisi 0,5%, saldo prepaid',
                      onTap: () => context.go('/register-driver'),
                    ),
                  if (user.isDriverApproved)
                    _MenuRow(
                      icon: Icons.radar_rounded,
                      title: 'Radar driver',
                      subtitle: 'Klaim order dan kelola pekerjaan',
                      onTap: () => context.go('/driver/radar'),
                    ),
                  if (user.isMerchant)
                    _MenuRow(
                      icon: Icons.storefront_outlined,
                      title: 'Dashboard merchant',
                      subtitle: 'Order masuk, menu, dan payout',
                      onTap: () => context.go('/merchant'),
                    ),
                  if (user.isAdmin)
                    _MenuRow(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Panel admin',
                      subtitle: 'Verifikasi, top-up, konfigurasi',
                      onTap: () => context.go('/admin'),
                    ),
                  const Divider(height: 1),
                  _MenuRow(
                    icon: Icons.support_agent_rounded,
                    title: 'Dispute & Safety',
                    subtitle: 'Bantuan, sengketa, dan darurat',
                    onTap: () => context.go('/support'),
                  ),
                  const Divider(height: 1),
                  _MenuRow(
                    icon: Icons.logout_rounded,
                    title: 'Keluar',
                    subtitle: 'Akhiri sesi di perangkat ini',
                    danger: true,
                    onTap: _signOut,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle(
              title: 'Review Shuffle',
              subtitle: 'Ulasan anonim dari pengguna kampus.',
            ),
            const _ReviewShuffle(),
            const SizedBox(height: 14),
            const InfoBanner(
              message:
                  'Data pribadi diproses sesuai UU PDP. Nomor WhatsApp hanya '
                  'dibagikan ke driver/merchant pada order aktif setelah '
                  'konfirmasi.',
              icon: Icons.privacy_tip_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchRole(AppUser user, UserRole role) async {
    ref.read(activeRoleProvider.notifier).setRole(role);
    if (AppConfig.demoMode) {
      ref
          .read(demoSessionProvider.notifier)
          .update((current) => current.copyWith(activeRole: role.code));
    } else if (FirebaseBootstrap.ready) {
      await ref.read(sessionRepositoryProvider).setActiveRole(role.code);
    }
    if (mounted) context.go(homePathForRole(role));
  }

  Future<void> _showEditProfile(AppUser user) async {
    final result = await showModalBottomSheet<_ProfileEdit>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _EditProfileSheet(user: user),
    );
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      if (AppConfig.demoMode) {
        ref
            .read(demoSessionProvider.notifier)
            .update(
              (current) => current.copyWith(
                displayName: result.name,
                nim: result.nim,
                phone: result.phone,
              ),
            );
      } else {
        await ref
            .read(authRepositoryProvider)
            .saveProfile(
              displayName: result.name,
              nim: result.nim,
              phone: result.phone,
            );
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profil diperbarui.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan profil.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Kamu perlu masuk kembali dengan Google kampus untuk memesan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (FirebaseBootstrap.ready) {
      await FirebaseAuth.instance.signOut();
    }
    ref.read(demoSessionProvider.notifier).signOut();
    if (mounted) context.go('/auth');
  }

  static IconData _roleIcon(UserRole role) {
    return switch (role) {
      UserRole.consumer => Icons.shopping_bag_rounded,
      UserRole.driver => Icons.two_wheeler_rounded,
      UserRole.merchant => Icons.storefront_rounded,
      UserRole.admin => Icons.admin_panel_settings_rounded,
    };
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, color: Ce.textMuted)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Ce.text,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: danger ? Ce.danger : Ce.emerald500, size: 21),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: danger ? Ce.danger : Ce.text,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 10, color: Ce.textMuted),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 19,
        color: Ce.textMuted,
      ),
    );
  }
}

class _ProfileEdit {
  const _ProfileEdit(this.name, this.nim, this.phone);

  final String name;
  final String nim;
  final String phone;
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user});

  final AppUser user;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _nim;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.displayName);
    _nim = TextEditingController(text: widget.user.nim);
    _phone = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _nim.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profil',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Ce.text,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama tampilan'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2 || text.length > 40) {
                    return 'Nama 2–40 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nim,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'NIM',
                  helperText: 'NIM tidak dapat diubah setelah terverifikasi.',
                ),
                validator: (value) {
                  if (!RegExp(AppConfig.nimPattern).hasMatch(value ?? '')) {
                    return 'NIM tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Nomor WhatsApp'),
                validator: (value) {
                  final phone = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
                  if (!RegExp(AppConfig.phonePattern).hasMatch(phone)) {
                    return 'Nomor WhatsApp tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!(_formKey.currentState?.validate() ?? false)) return;
                    Navigator.of(context).pop(
                      _ProfileEdit(
                        _name.text.trim(),
                        _nim.text.trim(),
                        ProfileSetupScreen.normalizePhone(_phone.text.trim()),
                      ),
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Review {
  const _Review(this.name, this.role, this.rating, this.text);

  final String name;
  final String role;
  final int rating;
  final String text;
}

const _reviews = [
  _Review(
    'Rani',
    'Konsumen',
    5,
    'Driver sampai 3 menit lebih cepat dari ETA. PIN jelas, barang aman.',
  ),
  _Review(
    'Dimas',
    'Driver',
    5,
    'Klaim order simpel, komisi kecil. Saldo deposit membantu disiplin.',
  ),
  _Review(
    'Bu Siti',
    'Merchant',
    4,
    'Menu mudah diubah. Semoga bisa tambah foto produk lebih banyak.',
  ),
  _Review(
    'Fajar',
    'Konsumen',
    5,
    'Numpang ke Gate 2 cuma Rp 5.000 dan tidak perlu tawar-menawar.',
  ),
  _Review(
    'Nadia',
    'Admin',
    4,
    'Antrean verifikasi driver rapi. Perlu filter tambahan untuk top-up.',
  ),
];

class _ReviewShuffle extends StatefulWidget {
  const _ReviewShuffle();

  @override
  State<_ReviewShuffle> createState() => _ReviewShuffleState();
}

class _ReviewShuffleState extends State<_ReviewShuffle> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final review = _reviews[_index % _reviews.length];
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 2; i >= 0; i--)
                Transform.translate(
                  offset: Offset(0, i * 8.0),
                  child: Transform.scale(
                    scale: 1 - i * 0.035,
                    child: Opacity(
                      opacity: 1 - i * 0.22,
                      child: BentoCard(
                        padding: const EdgeInsets.all(14),
                        child: i == 0
                            ? _ReviewBody(review: review)
                            : const SizedBox(height: 104),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            final random = Random();
            var next = random.nextInt(_reviews.length);
            if (next == _index) next = (next + 1) % _reviews.length;
            setState(() => _index = next);
          },
          icon: const Icon(Icons.shuffle_rounded, size: 18),
          label: const Text('Acak ulasan'),
        ),
      ],
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({required this.review});

  final _Review review;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Ce.emerald600,
              child: Text(
                review.name.substring(0, 1),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Ce.text,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              review.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Ce.text,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '· ${review.role}',
              style: const TextStyle(fontSize: 9.5, color: Ce.textMuted),
            ),
            const Spacer(),
            for (var i = 0; i < 5; i++)
              Icon(
                i < review.rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 13,
                color: Ce.warning,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          review.text,
          style: const TextStyle(fontSize: 11.5, color: Ce.text, height: 1.4),
        ),
      ],
    );
  }
}
