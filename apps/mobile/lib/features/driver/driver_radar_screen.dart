import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/firebase/firestore_paths.dart';
import '../../core/models/bid.dart';
import '../../core/models/order.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/bento_card.dart';
import '../tracking/campus_map_data.dart';
import '../tracking/eta_calculator.dart';
import '../tracking/fare_recommendation.dart';

final _radarOrdersProvider = StreamProvider<List<Order>>((ref) {
  if (!FirebaseBootstrap.ready) return Stream<List<Order>>.value(const []);
  return FirebaseFirestore.instance
      .collection(FirestorePaths.orders)
      .where('status', whereIn: ['AWAITING_DRIVER', 'SEARCHING_BIDS'])
      .orderBy('created_at', descending: true)
      .limit(20)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Order.fromMap(doc.id, doc.data()))
            .toList(),
      );
});

/// Screen 09 — Driver Order Radar (M08).
class DriverRadarScreen extends ConsumerStatefulWidget {
  const DriverRadarScreen({super.key});

  @override
  ConsumerState<DriverRadarScreen> createState() => _DriverRadarScreenState();
}

class _DriverRadarScreenState extends ConsumerState<DriverRadarScreen> {
  bool _online = true;
  final Set<String> _claiming = {};

  @override
  Widget build(BuildContext context) {
    final demo = AppConfig.demoMode;
    final user = ref.watch(authStateProvider).value;
    final demoOrders = ref.watch(demoOrdersProvider);
    final realOrders = ref.watch(_radarOrdersProvider);
    final orders = demo
        ? demoOrders
              .where(
                (order) =>
                    order.status == OrderStatus.AWAITING_DRIVER ||
                    order.status == OrderStatus.SEARCHING_BIDS,
              )
              .toList()
        : (realOrders.value ?? const <Order>[]);
    final balance = demo
        ? ref.watch(demoWalletBalanceProvider)
        : (user?.walletBalance ?? 0);
    final activeJobs = user?.activeJobs ?? 0;
    final canClaim =
        balance >= AppConfig.driverMinBalance &&
        activeJobs < AppConfig.maxActiveJobsPerDriver;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar Order'),
        actions: [
          IconButton(
            onPressed: () => context.go('/driver/wallet'),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Dompet',
          ),
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
            if (!demo) ref.invalidate(_radarOrdersProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              BentoCard(
                borderColor: balance < AppConfig.driverLowBalanceWarn
                    ? Ce.warning
                    : Ce.emerald900,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Ce.emerald500.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Ce.emerald500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saldo deposit',
                            style: TextStyle(fontSize: 10, color: Ce.textMuted),
                          ),
                          Text(
                            formatRupiah(balance),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: balance < AppConfig.driverMinBalance
                                  ? Ce.danger
                                  : Ce.text,
                            ),
                          ),
                          if (balance < AppConfig.driverLowBalanceWarn)
                            Text(
                              balance < AppConfig.driverMinBalance
                                  ? 'Saldo di bawah batas klaim (Rp 5.000).'
                                  : 'Saldo rendah. Segera top-up.',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Ce.warning,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        StatusPill(
                          label: _online ? 'Online' : 'Offline',
                          color: _online ? Ce.emerald500 : Ce.textMuted,
                          compact: true,
                        ),
                        Switch(
                          value: _online,
                          activeThumbColor: Ce.emerald500,
                          onChanged: (value) => setState(() => _online = value),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.work_outline_rounded,
                      label: 'Pekerjaan aktif',
                      value:
                          '$activeJobs / ${AppConfig.maxActiveJobsPerDriver}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.percent_rounded,
                      label: 'Komisi',
                      value: '0,5%',
                    ),
                  ),
                ],
              ),
              if (!canClaim) ...[
                const SizedBox(height: 10),
                InfoBanner(
                  message: balance < AppConfig.driverMinBalance
                      ? 'Penawaran terkunci: saldo minimal Rp 5.000. Top-up dulu.'
                      : 'Penawaran terkunci: maksimal 2 pekerjaan aktif.',
                  icon: Icons.lock_outline_rounded,
                  color: Ce.warning,
                  action: TextButton(
                    onPressed: () => context.go('/driver/wallet'),
                    child: const Text('Top-Up'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SectionTitle(
                title: 'Order menunggu driver',
                subtitle: _online
                    ? '${orders.length} order realtime · urut terbaru'
                    : 'Kamu offline. Nyalakan online untuk menerima order.',
              ),
              if (!demo && realOrders.isLoading)
                const SkeletonList(count: 3)
              else if (orders.isEmpty)
                const EmptyState(
                  title: 'Radar kosong',
                  message:
                      'Belum ada order AWAITING_DRIVER / SEARCHING_BIDS. '
                      'Tarik ke bawah untuk menyegarkan.',
                  icon: Icons.radar_rounded,
                )
              else
                for (final order in orders) ...[
                  _RadarCard(
                    order: order,
                    claiming: _claiming.contains(order.id),
                    canClaim: canClaim && _online,
                    onClaim: () => _openBidSheet(order, balance),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }

  /// Jarak rute graf kampus untuk rekomendasi harga pada bottom sheet.
  double _bidDistance(Order order) {
    final graph = LandmarkGraph.fromEdges([
      for (final edge in CampusMapData.edges)
        EdgeSpec(edge.a, edge.b, edge.meters),
    ]);
    try {
      return graph
          .shortest(order.pickupLandmarkId, order.dropoffLandmarkId)
          .meters;
    } catch (_) {
      return 1200;
    }
  }

  Future<void> _openBidSheet(Order order, int balance) async {
    final outerContext = context;
    if (balance < AppConfig.driverMinBalance) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Saldo kurang'),
          content: const Text(
            'Saldo deposit minimal Rp 5.000 untuk mengirim penawaran. '
            'Lakukan top-up terlebih dahulu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                outerContext.go('/driver/wallet');
              },
              child: const Text('Top-Up'),
            ),
          ],
        ),
      );
      return;
    }

    final recommendation = recommendFare(_bidDistance(order));
    final draft = await showModalBottomSheet<_BidDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _BidSheet(order: order, recommendation: recommendation),
    );
    if (draft == null || !mounted) return;

    setState(() => _claiming.add(order.id));
    try {
      if (AppConfig.demoMode) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        ref
            .read(demoOrdersProvider.notifier)
            .setStatus(order.id, OrderStatus.SEARCHING_BIDS);
        ref
            .read(demoBidsProvider.notifier)
            .addBid(
              Bid.demo(
                bidId: 'bid_demo_driver',
                driverName: 'Dimas Driver',
                offeredPrice: draft.offeredPrice,
                estimatedArrivalMinutes: draft.etaMinutes,
                platNumber: 'BK 1234 AB',
              ),
            );
      } else {
        await ref
            .read(gatewayClientProvider)
            .submitBid(
              orderId: order.id,
              offeredPrice: draft.offeredPrice,
              estimatedArrivalMinutes: draft.etaMinutes,
              platNumber: 'BK 1234 AB',
              vehicleModel: 'Honda Beat',
            );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Penawaran ${formatRupiah(draft.offeredPrice)} terkirim. '
            'Menunggu konsumen memilih.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().contains('INSUFFICIENT_BALANCE')
          ? 'Saldo deposit minimal Rp 5.000. Top-up dulu.'
          : 'Gagal mengirim penawaran. Coba lagi.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _claiming.remove(order.id));
    }
  }
}

class _BidDraft {
  const _BidDraft(this.offeredPrice, this.etaMinutes);

  final int offeredPrice;
  final int etaMinutes;
}

/// Modal bottom sheet input bid: nominal + ETA + info rekomendasi OSRM.
class _BidSheet extends StatefulWidget {
  const _BidSheet({required this.order, required this.recommendation});

  final Order order;
  final FareRecommendation recommendation;

  @override
  State<_BidSheet> createState() => _BidSheetState();
}

class _BidSheetState extends State<_BidSheet> {
  late final TextEditingController _price = TextEditingController(
    text: widget.recommendation.basePrice.toString(),
  );
  late final TextEditingController _eta = TextEditingController(
    text: widget.recommendation.estimatedArrivalMinutes.toString(),
  );
  String? _error;

  @override
  void dispose() {
    _price.dispose();
    _eta.dispose();
    super.dispose();
  }

  void _submit() {
    final price = int.tryParse(_price.text.trim());
    final eta =
        int.tryParse(_eta.text.trim()) ??
        widget.recommendation.estimatedArrivalMinutes;
    if (price == null || price < 3000) {
      setState(() => _error = 'Penawaran minimal Rp 3.000.');
      return;
    }
    if (eta < 1 || eta > 120) {
      setState(() => _error = 'ETA harus 1–120 menit.');
      return;
    }
    Navigator.of(context).pop(_BidDraft(price, eta));
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final recommendation = widget.recommendation;
    final pickup = order.pickupName.isEmpty
        ? order.pickupLandmarkId
        : order.pickupName;
    final dropoff = order.dropoffName.isEmpty
        ? order.dropoffLandmarkId
        : order.dropoffName;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer_rounded, color: Ce.emerald500),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tawarkan Harga',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Ce.text,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              '$pickup → $dropoff',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Ce.text,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Ce.emerald500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Ce.emerald500.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.route_rounded,
                    size: 18,
                    color: Ce.emerald500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation.label,
                      style: const TextStyle(fontSize: 12, color: Ce.text),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal penawaran (Rp)',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _eta,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimasi tiba di titik jemput (menit)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: Ce.danger),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: const Text('KIRIM PENAWARAN'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarCard extends StatelessWidget {
  const _RadarCard({
    required this.order,
    required this.claiming,
    required this.canClaim,
    required this.onClaim,
  });

  final Order order;
  final bool claiming;
  final bool canClaim;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final distance = _distance(order);
    final eta = _etaSeconds(order, distance);
    final commission = order.commissionFee > 0
        ? order.commissionFee
        : (order.totalPrice * 0.005).round().clamp(50, 1 << 31).toInt();

    return BentoCard(
      borderColor: Ce.emerald500.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                label: order.type.shortLabel,
                icon: Icons.local_shipping_rounded,
              ),
              const Spacer(),
              Text(
                timeAgo(order.createdAt),
                style: const TextStyle(fontSize: 10, color: Ce.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            '${order.pickupName.isEmpty ? order.pickupLandmarkId : order.pickupName}'
            ' → '
            '${order.dropoffName.isEmpty ? order.dropoffLandmarkId : order.dropoffName}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Ce.text,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _Metric(
                icon: Icons.route_rounded,
                value: formatDistance(distance),
              ),
              const SizedBox(width: 12),
              _Metric(
                icon: Icons.timer_outlined,
                value: formatEta(Duration(seconds: eta)),
              ),
              const SizedBox(width: 12),
              _Metric(
                icon: Icons.payments_outlined,
                value: formatRupiah(order.totalPrice),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Komisi ${formatRupiah(commission)} · '
                  '${order.paymentMethod.label}',
                  style: const TextStyle(fontSize: 10, color: Ce.textMuted),
                ),
              ),
              FilledButton(
                onPressed: canClaim && !claiming ? onClaim : null,
                child: claiming
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Ce.text,
                        ),
                      )
                    : const Text('TAWARKAN HARGA'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _distance(Order order) {
    final graph = _graph();
    try {
      return graph
          .shortest(order.pickupLandmarkId, order.dropoffLandmarkId)
          .meters;
    } catch (_) {
      return 1200;
    }
  }

  int _etaSeconds(Order order, double meters) {
    return (meters / (AppConfig.avgSpeedKmh / 3.6)).round();
  }

  LandmarkGraph _graph() => LandmarkGraph.fromEdges([
    for (final edge in CampusMapData.edges)
      EdgeSpec(edge.a, edge.b, edge.meters),
  ]);
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Ce.emerald500),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 10.5, color: Ce.textMuted),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Ce.emerald500),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 9, color: Ce.textMuted),
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
            ),
          ),
        ],
      ),
    );
  }
}
