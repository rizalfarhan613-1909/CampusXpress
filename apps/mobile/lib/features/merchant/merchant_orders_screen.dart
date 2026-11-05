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

final _incomingOrdersProvider = StreamProvider<List<Order>>((ref) {
  if (!FirebaseBootstrap.ready) return Stream<List<Order>>.value(const []);
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream<List<Order>>.value(const []);
  return FirebaseFirestore.instance
      .collection(FirestorePaths.orders)
      .where('merchant_id', isEqualTo: uid)
      .where('status', whereIn: ['PLACED', 'ACCEPTED', 'READY'])
      .orderBy('created_at', descending: true)
      .limit(30)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Order.fromMap(doc.id, doc.data()))
            .toList(),
      );
});

/// Screen 13 — Merchant Incoming Order & Dispatcher (M14).
class MerchantOrdersScreen extends ConsumerStatefulWidget {
  const MerchantOrdersScreen({super.key});

  @override
  ConsumerState<MerchantOrdersScreen> createState() =>
      _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends ConsumerState<MerchantOrdersScreen> {
  String _filter = 'Baru';
  final Map<String, int> _prepTimes = {};
  final Set<String> _busy = {};

  @override
  Widget build(BuildContext context) {
    final demo = AppConfig.demoMode;
    final user = ref.watch(authStateProvider).value;
    final merchantId = demo ? 'merchant-kantin' : (user?.uid ?? '');
    final realOrders = ref.watch(_incomingOrdersProvider);
    final source = demo
        ? ref
              .watch(demoOrdersProvider)
              .where((order) => order.merchantId == merchantId)
              .toList()
        : (realOrders.value ?? const <Order>[]);

    final orders = source.where((order) {
      return switch (_filter) {
        'Baru' => order.status == OrderStatus.PLACED,
        'Diproses' =>
          order.status == OrderStatus.ACCEPTED ||
              order.status == OrderStatus.READY,
        _ =>
          order.status == OrderStatus.PLACED ||
              order.status == OrderStatus.ACCEPTED ||
              order.status == OrderStatus.READY,
      };
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Masuk'),
        actions: [
          IconButton(
            onPressed: () => context.go('/merchant'),
            icon: const Icon(Icons.dashboard_outlined),
            tooltip: 'Dashboard',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: Ce.emerald500,
          onRefresh: () async {
            if (!demo) ref.invalidate(_incomingOrdersProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
            children: [
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final filter in const [
                            'Baru',
                            'Diproses',
                            'Semua',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(filter),
                                selected: _filter == filter,
                                onSelected: (_) =>
                                    setState(() => _filter = filter),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(
                    label: '${orders.length} order',
                    color: orders.isEmpty ? Ce.textMuted : Ce.emerald500,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const InfoBanner(
                message:
                    'Konfirmasi order maksimal 5 menit. Order yang tidak '
                    'direspons akan dialihkan otomatis ke merchant lain.',
                icon: Icons.timer_outlined,
                color: Ce.warning,
              ),
              const SizedBox(height: 14),
              if (!demo && realOrders.isLoading)
                const SkeletonList(count: 3)
              else if (orders.isEmpty)
                EmptyState(
                  title: _filter == 'Baru'
                      ? 'Tidak ada order baru'
                      : 'Tidak ada order $_filter',
                  message:
                      'Tarik ke bawah untuk menyegarkan. Pastikan toko dalam '
                      'status buka.',
                  icon: Icons.inbox_outlined,
                  action: FilledButton(
                    onPressed: () => context.go('/merchant'),
                    child: const Text('Buka dashboard'),
                  ),
                )
              else
                for (final order in orders) ...[
                  _IncomingCard(
                    order: order,
                    prepTime: _prepTimes[order.id] ?? 15,
                    busy: _busy.contains(order.id),
                    onPrepTime: (value) =>
                        setState(() => _prepTimes[order.id] = value),
                    onAccept: () => _setStatus(order, OrderStatus.ACCEPTED),
                    onReject: () => _reject(order),
                    onReady: () => _setStatus(order, OrderStatus.READY),
                    onDispatch: () =>
                        _setStatus(order, OrderStatus.AWAITING_DRIVER),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setStatus(Order order, OrderStatus status) async {
    setState(() => _busy.add(order.id));
    try {
      if (AppConfig.demoMode) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        ref.read(demoOrdersProvider.notifier).setStatus(order.id, status);
      } else {
        await FirebaseFirestore.instance
            .collection(FirestorePaths.orders)
            .doc(order.id)
            .update({
              'status': status.name,
              if (status == OrderStatus.ACCEPTED)
                'prep_time_min': _prepTimes[order.id] ?? 15,
              'updated_at': FieldValue.serverTimestamp(),
            });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order #${order.id}: ${status.label}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui order.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  Future<void> _reject(Order order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak order?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Konsumen akan diberi tahu dan dana dikembalikan sesuai metode '
              'pembayaran.',
              style: TextStyle(fontSize: 12, color: Ce.textMuted),
            ),
            const SizedBox(height: 12),
            for (final reason in const [
              'Bahan habis',
              'Toko terlalu ramai',
              'Di luar jam operasional',
            ])
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(reason),
                onTap: () => Navigator.of(context).pop(reason),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    await _setStatus(order, OrderStatus.CANCELLED);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Order ditolak: $reason')));
    }
  }
}

class _IncomingCard extends StatelessWidget {
  const _IncomingCard({
    required this.order,
    required this.prepTime,
    required this.busy,
    required this.onPrepTime,
    required this.onAccept,
    required this.onReject,
    required this.onReady,
    required this.onDispatch,
  });

  final Order order;
  final int prepTime;
  final bool busy;
  final ValueChanged<int> onPrepTime;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onReady;
  final VoidCallback onDispatch;

  @override
  Widget build(BuildContext context) {
    final age = order.createdAt == null
        ? Duration.zero
        : DateTime.now().difference(order.createdAt!);
    final timedOut =
        order.status == OrderStatus.PLACED && age > const Duration(minutes: 5);

    return BentoCard(
      borderColor: timedOut
          ? Ce.danger
          : order.status == OrderStatus.PLACED
          ? Ce.warning
          : Ce.emerald500.withValues(alpha: 0.45),
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
                label: timedOut
                    ? 'Timeout ${age.inMinutes} m'
                    : order.status.label,
                color: timedOut
                    ? Ce.danger
                    : order.status == OrderStatus.PLACED
                    ? Ce.warning
                    : Ce.emerald500,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '#${order.id} · ${order.consumerName}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Ce.text,
            ),
          ),
          const SizedBox(height: 4),
          for (final item in order.items)
            Text(
              '${item.quantity}× ${item.name}',
              style: const TextStyle(fontSize: 11, color: Ce.textMuted),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 13, color: Ce.emerald500),
              const SizedBox(width: 4),
              Text(
                timeAgo(order.createdAt),
                style: const TextStyle(fontSize: 10, color: Ce.textMuted),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.payments_outlined,
                size: 13,
                color: Ce.emerald500,
              ),
              const SizedBox(width: 4),
              Text(
                formatRupiah(order.totalPrice),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Ce.text,
                ),
              ),
            ],
          ),
          if (order.status == OrderStatus.ACCEPTED) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Waktu persiapan',
                  style: TextStyle(fontSize: 10, color: Ce.textMuted),
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: prepTime,
                  underline: const SizedBox.shrink(),
                  dropdownColor: Ce.surfaceHigh,
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('5 menit')),
                    DropdownMenuItem(value: 10, child: Text('10 menit')),
                    DropdownMenuItem(value: 15, child: Text('15 menit')),
                    DropdownMenuItem(value: 20, child: Text('20 menit')),
                    DropdownMenuItem(value: 30, child: Text('30 menit')),
                  ],
                  onChanged: (value) {
                    if (value != null) onPrepTime(value);
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (order.status == OrderStatus.PLACED)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onReject,
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: busy ? null : onAccept,
                    icon: busy
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Ce.text,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 17),
                    label: const Text('Terima order'),
                  ),
                ),
              ],
            )
          else if (order.status == OrderStatus.ACCEPTED)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onReady,
                icon: const Icon(Icons.checklist_rounded, size: 17),
                label: const Text('Tandai siap diambil'),
              ),
            )
          else if (order.status == OrderStatus.READY)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onDispatch,
                icon: const Icon(Icons.two_wheeler_rounded, size: 17),
                label: const Text('Serahkan ke radar driver'),
              ),
            ),
        ],
      ),
    );
  }
}
