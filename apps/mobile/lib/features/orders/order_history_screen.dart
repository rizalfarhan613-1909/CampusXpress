import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
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
import '../../core/widgets/async_state.dart';
import '../../core/widgets/bento_card.dart';

final _historyProvider = StreamProvider<List<Order>>((ref) {
  if (!FirebaseBootstrap.ready) return Stream<List<Order>>.value(const []);
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream<List<Order>>.value(const []);
  final role = ref.watch(activeRoleProvider);
  final field = switch (role) {
    UserRole.driver => 'driver_id',
    UserRole.merchant => 'merchant_id',
    _ => 'consumer_id',
  };
  return FirebaseFirestore.instance
      .collection(FirestorePaths.orders)
      .where(field, isEqualTo: user.uid)
      .orderBy('created_at', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Order.fromMap(doc.id, doc.data()))
            .toList(),
      );
});

/// Screen 18 — Order History & Digital E-Receipt (M17).
class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  String _tab = 'Semua';
  int _limit = 8;

  @override
  Widget build(BuildContext context) {
    final demo = AppConfig.demoMode;
    final realOrders = ref.watch(_historyProvider);
    final all = demo
        ? ref.watch(demoOrdersProvider)
        : (realOrders.value ?? const <Order>[]);
    final filtered = all.where((order) {
      return switch (_tab) {
        'Aktif' => order.status.isActive,
        'Selesai' => order.status.isFinished,
        _ => true,
      };
    }).toList();
    final visible = filtered.take(_limit).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Order'),
        actions: [
          IconButton(
            onPressed: () => context.go('/catalog'),
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'Katalog',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: Ce.emerald500,
          onRefresh: () async {
            if (!demo) ref.invalidate(_historyProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final tab in const ['Semua', 'Aktif', 'Selesai'])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(tab),
                          selected: _tab == tab,
                          onSelected: (_) => setState(() {
                            _tab = tab;
                            _limit = 8;
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!demo && realOrders.isLoading)
                const SkeletonList(count: 4)
              else if (visible.isEmpty)
                EmptyState(
                  title: _tab == 'Aktif'
                      ? 'Tidak ada order aktif'
                      : 'Riwayat masih kosong',
                  message: _tab == 'Selesai'
                      ? 'Order yang selesai akan muncul di sini beserta struk.'
                      : 'Mulai pesan numpang, jastip, paket, atau jajan UMKM.',
                  icon: Icons.receipt_long_outlined,
                  action: FilledButton(
                    onPressed: () => context.go('/catalog'),
                    child: const Text('Buka katalog'),
                  ),
                )
              else ...[
                for (final order in visible) ...[
                  _HistoryCard(order: order),
                  const SizedBox(height: 9),
                ],
                if (filtered.length > _limit)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _limit += 8),
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text(
                      'Muat lebih banyak (${filtered.length - _limit})',
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      OrderStatus.COMPLETED => Ce.emerald500,
      OrderStatus.CANCELLED ||
      OrderStatus.EXPIRED ||
      OrderStatus.DISPUTED => Ce.danger,
      _ => Ce.warning,
    };
    return BentoCard(
      onTap: () => context.go('/orders/${order.id}'),
      borderColor: statusColor.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                label: order.type.shortLabel,
                icon: Icons.receipt_long_rounded,
              ),
              const Spacer(),
              StatusPill(
                label: order.status.label,
                color: statusColor,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '#${order.id}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Ce.text,
            ),
          ),
          Text(
            '${order.pickupName} → ${order.dropoffName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Ce.textMuted),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                formatDateTime(order.createdAt),
                style: const TextStyle(fontSize: 9.5, color: Ce.textMuted),
              ),
              const Spacer(),
              Text(
                formatRupiah(order.totalPrice),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Ce.text,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Ce.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
