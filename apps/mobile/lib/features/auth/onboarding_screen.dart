import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/bento_card.dart';
import '../home/widgets/word_rotator.dart';

/// Screen 01 — Onboarding & Role Selector (M02).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  UserRole _selected = UserRole.consumer;

  static const _roles = [
    (
      role: UserRole.consumer,
      icon: Icons.shopping_bag_rounded,
      title: 'Saya Konsumen',
      subtitle: 'Pesan numpang, jastip, paket, dan jajan UMKM kampus.',
      points: ['Pilih landmark preset', 'Lacak pesanan 3D', 'PIN serah-terima'],
    ),
    (
      role: UserRole.driver,
      icon: Icons.two_wheeler_rounded,
      title: 'Saya Driver',
      subtitle: 'Klaim order realtime, komisi hanya 0,5%, saldo prepaid.',
      points: ['Radar order 1-klik', 'Checkpoint jelas', 'Dompet deposit'],
    ),
    (
      role: UserRole.merchant,
      icon: Icons.storefront_rounded,
      title: 'Saya UMKM',
      subtitle: 'Etalase digital, kelola menu, dan terima order tanpa ribet.',
      points: ['Buka/tutup toko', 'Kelola 150 produk', 'Payout transparan'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF07251A), Ce.bg, Ce.bg],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Ce.emerald500.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Ce.emerald500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Campus Express',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Ce.text,
                      ),
                    ),
                    const Spacer(),
                    const StatusPill(
                      label: 'Go-Campus',
                      color: Ce.emerald500,
                      icon: Icons.school_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                const Text(
                  'Mau',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Ce.text,
                    height: 1.1,
                  ),
                ),
                const WordRotator(
                  words: ['Numpang', 'Jastip', 'Kirim Paket', 'Jajan'],
                ),
                const Text(
                  'di kampus?',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Ce.text,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Satu aplikasi untuk empat layanan hiper-lokal kampus. '
                  'Komisi 0,5%, transparan, dan tanpa biaya tersembunyi.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Ce.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),
                const SectionTitle(
                  title: 'Pilih peranmu',
                  subtitle:
                      'Peran aktif bisa diganti kapan saja setelah masuk.',
                ),
                for (final item in _roles) ...[
                  _RoleCard(
                    icon: item.icon,
                    title: item.title,
                    subtitle: item.subtitle,
                    points: item.points,
                    selected: _selected == item.role,
                    onTap: () => setState(() => _selected = item.role),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(activeRoleProvider.notifier).setRole(_selected);
                    context.go('/auth');
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: Text('Lanjut sebagai ${_selected.label}'),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Dengan melanjutkan, kamu menyetujui aturan komunitas, '
                  'kebijakan privasi, dan pemrosesan data sesuai UU PDP.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Ce.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> points;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      onTap: onTap,
      borderColor: selected ? Ce.emerald500 : Ce.emerald900,
      color: selected ? const Color(0xFF0B2C20) : Ce.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected
                  ? Ce.emerald500.withValues(alpha: 0.2)
                  : Ce.surfaceHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: selected ? Ce.emerald500 : Ce.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Ce.text,
                        ),
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 20,
                      color: selected ? Ce.emerald500 : Ce.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Ce.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final point in points)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Ce.bg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          point,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Ce.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
