import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/firebase/firestore_paths.dart';
import '../../core/models/app_user.dart';
import '../../core/models/order.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/role_nav.dart';
import '../../core/widgets/bento_card.dart';
import 'widgets/sales_ping_toast.dart';
import 'widgets/word_rotator.dart';

final _consumerOrdersProvider = StreamProvider<List<Order>>((ref) {
  if (!FirebaseBootstrap.ready) return Stream<List<Order>>.value(const []);
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream<List<Order>>.value(const []);
  return FirebaseFirestore.instance
      .collection(FirestorePaths.orders)
      .where('consumer_id', isEqualTo: uid)
      .orderBy('created_at', descending: true)
      .limit(5)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Order.fromMap(doc.id, doc.data()))
            .toList(),
      );
});

/// Screen 03 — Consumer Home Bento Dashboard (M04, M20).
class ConsumerHomeScreen extends ConsumerWidget {
  const ConsumerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final demo = AppConfig.demoMode;
    final demoOrder = ref.watch(demoActiveOrderProvider);
    final realOrders = ref.watch(_consumerOrdersProvider).value ?? const [];
    final activeOrder = demo ? demoOrder : _firstActiveOrder(realOrders);
    final name = user?.displayName ?? 'Mahasiswa';

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: Ce.emerald500,
              onRefresh: () async {
                if (!demo) {
                  ref.invalidate(_consumerOrdersProvider);
                }
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
                children: [
                  _Header(user: user),
                  const SizedBox(height: 18),
                  Text(
                    'Halo, $name 👋',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Ce.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Mau',
                        style: TextStyle(fontSize: 13, color: Ce.textMuted),
                      ),
                      const SizedBox(width: 4),
                      WordRotator(
                        words: const ['numpang', 'jastip', 'kirim', 'jajan'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Ce.emerald500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'hari ini?',
                        style: TextStyle(fontSize: 13, color: Ce.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _ServiceBento(),
                  const SizedBox(height: 20),
                  const SectionTitle(
                    title: 'Order aktif',
                    subtitle: 'Pantau posisi dan ETA secara realtime.',
                  ),
                  if (activeOrder != null)
                    _ActiveOrderCard(order: activeOrder)
                  else
                    BentoCard(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 34,
                            color: Ce.emerald600,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Belum ada order aktif',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Ce.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pilih layanan di atas untuk mulai memesan.',
                            style: TextStyle(fontSize: 12, color: Ce.textMuted),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () => context.go('/catalog'),
                            child: const Text('Lihat katalog'),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  const SectionTitle(
                    title: 'Kampus hari ini',
                    subtitle: 'Data agregat, tanpa identitas pengguna.',
                  ),
                  const _StatsRow(),
                  const SizedBox(height: 20),
                  if (user != null && (user.isDriver || user.isMerchant)) ...[
                    const SectionTitle(title: 'Pintasan peran'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (user.isDriver)
                          ActionChip(
                            avatar: const Icon(
                              Icons.radar_rounded,
                              size: 16,
                              color: Ce.emerald500,
                            ),
                            label: const Text('Radar Driver'),
                            onPressed: () => context.go('/driver/radar'),
                          ),
                        if (user.isMerchant)
                          ActionChip(
                            avatar: const Icon(
                              Icons.storefront_rounded,
                              size: 16,
                              color: Ce.emerald500,
                            ),
                            label: const Text('Dashboard Merchant'),
                            onPressed: () => context.go('/merchant'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  const SectionTitle(
                    title: 'Akses cepat',
                    subtitle: 'Semua fitur utama dalam satu tempat.',
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickLink(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat',
                        onTap: () => context.go(
                          '/chat/${activeOrder?.id ?? 'order-aktif'}',
                        ),
                      ),
                      _QuickLink(
                        icon: Icons.receipt_long_rounded,
                        label: 'Riwayat',
                        onTap: () => context.go('/orders'),
                      ),
                      _QuickLink(
                        icon: Icons.person_outline_rounded,
                        label: 'Profil',
                        onTap: () => context.go('/profile'),
                      ),
                      _QuickLink(
                        icon: Icons.support_agent_rounded,
                        label: 'Bantuan',
                        onTap: () => context.go('/support'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SalesPingToast(),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Ce.emerald500, Ce.emerald600],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.bolt_rounded, color: Ce.text),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Campus Express',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Ce.text,
                ),
              ),
              Text(
                'Go-Campus · UIN',
                style: TextStyle(fontSize: 10, color: Ce.textMuted),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.go('/orders'),
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'Notifikasi',
        ),
        if (user != null)
          GestureDetector(
            onTap: () => _showRoleSwitcher(context, ref, user!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Ce.surfaceHigh,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Ce.emerald900),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user!.role.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Ce.emerald500,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 15,
                    color: Ce.emerald500,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> _showRoleSwitcher(
  BuildContext context,
  WidgetRef ref,
  AppUser user,
) async {
  final selected = await showModalBottomSheet<UserRole>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final roles = UserRole.values
          .where((role) => user.roles.contains(role.code))
          .toList();
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ganti peran aktif',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Ce.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Peran aktif hanya mengubah antarmuka. Hak akses tetap mengikuti '
              'peran yang disetujui.',
              style: TextStyle(fontSize: 11, color: Ce.textMuted),
            ),
            const SizedBox(height: 12),
            for (final role in roles)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(switch (role) {
                  UserRole.consumer => Icons.shopping_bag_rounded,
                  UserRole.driver => Icons.two_wheeler_rounded,
                  UserRole.merchant => Icons.storefront_rounded,
                  UserRole.admin => Icons.admin_panel_settings_rounded,
                }, color: Ce.emerald500),
                title: Text(role.label),
                trailing: user.role == role
                    ? const Icon(Icons.check_circle, color: Ce.emerald500)
                    : null,
                onTap: () => Navigator.of(context).pop(role),
              ),
          ],
        ),
      );
    },
  );

  if (selected == null || !context.mounted) return;
  ref.read(activeRoleProvider.notifier).setRole(selected);
  if (AppConfig.demoMode) {
    ref
        .read(demoSessionProvider.notifier)
        .update((current) => current.copyWith(activeRole: selected.code));
  } else if (FirebaseBootstrap.ready) {
    await ref.read(sessionRepositoryProvider).setActiveRole(selected.code);
  }
  if (context.mounted) context.go(homePathForRole(selected));
}

class _ServiceBento extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const services = [
      (
        title: 'Numpang',
        subtitle: 'Tumpangan motor',
        icon: Icons.two_wheeler_rounded,
        color: Ce.emerald500,
        route: '/landmarks?service=numpang',
        badge: 'Zona',
      ),
      (
        title: 'Jastip',
        subtitle: 'Titip makanan',
        icon: Icons.fastfood_rounded,
        color: Color(0xFFF59E0B),
        route: '/catalog',
        badge: 'Favorit',
      ),
      (
        title: 'Express',
        subtitle: 'Kirim paket',
        icon: Icons.local_shipping_rounded,
        color: Color(0xFF60A5FA),
        route: '/landmarks?service=paket',
        badge: '≤ 5 kg',
      ),
      (
        title: 'UMKM',
        subtitle: 'Katalog kampus',
        icon: Icons.storefront_rounded,
        color: Color(0xFFA78BFA),
        route: '/catalog',
        badge: 'Lokal',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Ce.gap,
      crossAxisSpacing: Ce.gap,
      childAspectRatio: 1.32,
      children: [
        for (final service in services)
          BentoCard(
            onTap: () => context.go(service.route),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: service.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(service.icon, color: service.color, size: 20),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Ce.bg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        service.badge,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Ce.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  service.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Ce.text,
                  ),
                ),
                Text(
                  service.subtitle,
                  style: const TextStyle(fontSize: 11, color: Ce.textMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final minutes = order.etaSeconds <= 0 ? 12 : (order.etaSeconds / 60).ceil();
    return BentoCard(
      borderColor: Ce.emerald500.withValues(alpha: 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                label: order.status.label,
                icon: Icons.radio_button_checked_rounded,
              ),
              const Spacer(),
              Text(
                order.type.shortLabel,
                style: const TextStyle(fontSize: 11, color: Ce.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${order.pickupName} → ${order.dropoffName}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Ce.text,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 15, color: Ce.emerald500),
              const SizedBox(width: 4),
              Text(
                'ETA $minutes menit',
                style: const TextStyle(
                  fontSize: 12,
                  color: Ce.emerald500,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.payments_outlined,
                size: 15,
                color: Ce.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                formatRupiah(order.totalPrice),
                style: const TextStyle(fontSize: 12, color: Ce.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.go('/tracking/${order.id}'),
                  icon: const Icon(Icons.map_outlined, size: 17),
                  label: const Text('Lacak order'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: () => context.go('/chat/${order.id}'),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                tooltip: 'Chat',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(
            value: 1284,
            label: 'Order bulan ini',
            icon: Icons.receipt_long_rounded,
          ),
        ),
        SizedBox(width: Ce.gap),
        Expanded(
          child: _StatCard(
            value: 150,
            label: 'Driver aktif',
            icon: Icons.two_wheeler_rounded,
          ),
        ),
        SizedBox(width: Ce.gap),
        Expanded(
          child: _StatCard(
            value: 40,
            label: 'Merchant',
            icon: Icons.storefront_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final int value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Ce.emerald500),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, current, _) => Text(
              current.round().toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Ce.text,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, color: Ce.textMuted),
          ),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: Ce.emerald500),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

Order? _firstActiveOrder(List<Order> orders) {
  for (final order in orders) {
    if (order.status.isActive) return order;
  }
  return null;
}
