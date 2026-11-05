import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/firebase/firestore_paths.dart';
import '../../core/models/order.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/bento_card.dart';

final _merchantOrdersProvider = StreamProvider<List<Order>>((ref) {
  if (!FirebaseBootstrap.ready) return Stream<List<Order>>.value(const []);
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream<List<Order>>.value(const []);
  return FirebaseFirestore.instance
      .collection(FirestorePaths.orders)
      .where('merchant_id', isEqualTo: uid)
      .orderBy('created_at', descending: true)
      .limit(20)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Order.fromMap(doc.id, doc.data()))
            .toList(),
      );
});

/// Screen 12 — Merchant Operational Dashboard (M14).
class MerchantDashboardScreen extends ConsumerStatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  ConsumerState<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState
    extends ConsumerState<MerchantDashboardScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final demo = AppConfig.demoMode;
    final user = ref.watch(authStateProvider).value;
    final merchantId = demo ? 'merchant-kantin' : (user?.uid ?? '');
    final demoOpen = ref.watch(demoMerchantOpenProvider);
    final open = demo ? demoOpen : (user != null);
    final demoOrders = ref.watch(demoOrdersProvider);
    final realOrders = ref.watch(_merchantOrdersProvider);
    final orders = demo
        ? demoOrders.where((order) => order.merchantId == merchantId).toList()
        : (realOrders.value ?? const <Order>[]);
    final incoming = orders
        .where(
          (order) =>
              order.status == OrderStatus.PLACED ||
              order.status == OrderStatus.ACCEPTED,
        )
        .length;
    final ready = orders
        .where((order) => order.status == OrderStatus.READY)
        .length;
    final completed = orders
        .where((order) => order.status == OrderStatus.COMPLETED)
        .toList();
    final revenue = completed.fold<int>(
      0,
      (total, order) => total + order.totalPrice,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Merchant'),
        actions: [
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profil',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: Ce.emerald500,
          onRefresh: () async {
            if (!demo) ref.invalidate(_merchantOrdersProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              BentoCard(
                borderColor: open ? Ce.emerald500 : Ce.danger,
                color: open ? const Color(0xFF0B2C20) : Ce.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (open ? Ce.emerald500 : Ce.danger)
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            open
                                ? Icons.storefront_rounded
                                : Icons.store_mall_directory_outlined,
                            color: open ? Ce.emerald500 : Ce.danger,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'Kantin Bu Siti',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Ce.text,
                                ),
                              ),
                              Text(
                                open
                                    ? 'Toko buka · menerima order'
                                    : 'Toko tutup · order baru ditahan',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: open ? Ce.emerald500 : Ce.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: open,
                          activeThumbColor: Ce.emerald500,
                          onChanged: _saving ? null : (value) => _toggle(value),
                        ),
                      ],
                    ),
                    if (!open) ...[
                      const SizedBox(height: 10),
                      const InfoBanner(
                        message:
                            'Toko tutup otomatis setelah jam operasional. '
                            'Order baru tidak masuk sampai kamu membuka toko.',
                        icon: Icons.schedule_rounded,
                        color: Ce.warning,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Metric(
                            label: 'Order masuk',
                            value: '$incoming',
                            icon: Icons.inbox_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Metric(
                            label: 'Siap diambil',
                            value: '$ready',
                            icon: Icons.checklist_rounded,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Metric(
                            label: 'Pendapatan',
                            value: formatRupiah(revenue),
                            icon: Icons.payments_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle(
                title: 'Aksi cepat',
                subtitle: 'Semua operasi toko dalam satu ketukan.',
              ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: Ce.gap,
                crossAxisSpacing: Ce.gap,
                childAspectRatio: 1.55,
                children: [
                  _ActionTile(
                    icon: Icons.receipt_long_rounded,
                    title: 'Order masuk',
                    subtitle: incoming == 0
                        ? 'Tidak ada order baru'
                        : '$incoming menunggu konfirmasi',
                    badge: incoming,
                    onTap: () => context.go('/merchant/orders'),
                  ),
                  _ActionTile(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Kelola menu',
                    subtitle: 'Tambah, edit, atur stok',
                    onTap: () => context.go('/merchant/menu'),
                  ),
                  _ActionTile(
                    icon: Icons.settings_rounded,
                    title: 'Pengaturan toko',
                    subtitle: 'Jam buka, QRIS, rekening',
                    onTap: () => context.go('/merchant/settings'),
                  ),
                  _ActionTile(
                    icon: Icons.insights_rounded,
                    title: 'Riwayat order',
                    subtitle: 'Struk & rekap transaksi',
                    onTap: () => context.go('/orders'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SectionTitle(
                title: 'Order terbaru',
                subtitle: demo
                    ? 'Data demo merchant'
                    : 'Realtime dari koleksi orders',
                action: TextButton(
                  onPressed: () => context.go('/merchant/orders'),
                  child: const Text('Lihat semua'),
                ),
              ),
              if (!demo && realOrders.isLoading)
                const SkeletonList(count: 3)
              else if (orders.isEmpty)
                const EmptyState(
                  title: 'Belum ada order',
                  message: 'Order baru akan muncul di sini secara realtime.',
                  icon: Icons.receipt_long_outlined,
                )
              else
                for (final order in orders.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _OrderRow(order: order),
                  ),
              const SizedBox(height: 14),
              const InfoBanner(
                message:
                    'Komisi platform hanya 0,5% dari nilai transaksi. '
                    'Tidak ada biaya bulanan atau biaya tersembunyi.',
                icon: Icons.percent_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(bool value) async {
    setState(() => _saving = true);
    try {
      if (AppConfig.demoMode) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        ref.read(demoMerchantOpenProvider.notifier).setOpen(value);
      } else {
        final uid = ref.read(authStateProvider).value?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection(FirestorePaths.merchants)
              .doc(uid)
              .update({
                'is_open': value,
                'updated_at': FieldValue.serverTimestamp(),
              });
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value ? 'Toko dibuka.' : 'Toko ditutup.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengubah status toko.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Ce.bg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Ce.emerald500),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Ce.emerald500, size: 20),
              const Spacer(),
              if (badge > 0)
                StatusPill(label: '$badge', color: Ce.warning, compact: true),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Ce.text,
            ),
          ),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9.5, color: Ce.textMuted),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.go('/orders/${order.id}'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  style: const TextStyle(fontSize: 10, color: Ce.textMuted),
                ),
                Text(
                  '${order.consumerName} · ${formatRupiah(order.totalPrice)}',
                  style: const TextStyle(fontSize: 10, color: Ce.textMuted),
                ),
              ],
            ),
          ),
          StatusPill(
            label: order.status.label,
            color: order.status == OrderStatus.COMPLETED
                ? Ce.emerald500
                : Ce.warning,
            compact: true,
          ),
        ],
      ),
    );
  }
}
