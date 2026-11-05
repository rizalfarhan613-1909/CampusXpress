import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'campus_map_data.dart';
import 'eta_calculator.dart';
import 'iso_map_view.dart';
import 'osm_map_view.dart';
import 'tracking_controller.dart';
import 'tuntungan_hub_data.dart';

final _orderProvider = StreamProvider.family<Order?, String>((ref, id) {
  if (!FirebaseBootstrap.ready) return Stream<Order?>.value(null);
  return FirebaseFirestore.instance
      .collection(FirestorePaths.orders)
      .doc(id)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? Order.fromMap(snapshot.id, snapshot.data()!)
            : null,
      );
});

/// Realtime penawaran `orders/{orderId}/bids` (Reverse Auction).
final _bidsProvider = StreamProvider.family<List<Bid>, String>((ref, orderId) {
  if (!FirebaseBootstrap.ready) return Stream<List<Bid>>.value(const []);
  return FirebaseFirestore.instance
      .collection(FirestorePaths.orders)
      .doc(orderId)
      .collection(FirestorePaths.bids)
      .orderBy('offeredPrice')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Bid.fromMap(doc.id, doc.data()))
            .toList(),
      );
});

/// Screen 08 — Live 3D Map Tracking & ETA (M09–M11).
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  late final LandmarkGraph _graph;
  late final SpeedEstimator _speed;
  late final TrackingController _controller;
  Timer? _timer;
  bool _batterySaver = false;
  bool _osmMap = false;
  String? _preparedFor;

  @override
  void initState() {
    super.initState();
    _graph = LandmarkGraph.fromEdges([
      for (final edge in CampusMapData.edges)
        EdgeSpec(edge.a, edge.b, edge.meters),
    ]);
    _speed = SpeedEstimator(AppConfig.avgSpeedKmh);
    _controller = TrackingController(_graph, _speed);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demoMode = AppConfig.demoMode;
    Order? order;
    if (demoMode) {
      for (final item in ref.watch(demoOrdersProvider)) {
        if (item.id == widget.orderId) order = item;
      }
      order ??= Order.demo(id: widget.orderId);
    } else {
      order = ref.watch(_orderProvider(widget.orderId)).value;
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lacak Order')),
        body: ErrorState(
          message:
              'Order tidak ditemukan atau kamu bukan peserta order ini. '
              'Periksa koneksi lalu coba lagi.',
          onRetry: () => ref.invalidate(_orderProvider(widget.orderId)),
        ),
      );
    }

    _prepareController(order);
    final eta = _eta(order);
    final pin = order.pin ?? '----';
    // Posisi driver realtime untuk marker motor pada peta OSM (`OsmMapView`).
    final vehiclePose = _controller.pose(DateTime.now())?.position;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lacak Order'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'battery') {
                setState(() => _batterySaver = !_batterySaver);
              } else if (value == 'support') {
                context.go('/support');
              }
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'battery',
                checked: _batterySaver,
                child: const Text('Hemat baterai (2D)'),
              ),
              const PopupMenuItem(
                value: 'support',
                child: Text('Buka Help Desk'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            Row(
              children: [
                StatusPill(
                  label: order.status.label,
                  icon: Icons.radio_button_checked_rounded,
                ),
                const Spacer(),
                Text(
                  order.type.label,
                  style: const TextStyle(fontSize: 11, color: Ce.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('3D Iso'),
                  selected: !_osmMap,
                  onSelected: (_) => setState(() => _osmMap = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('OSM'),
                  selected: _osmMap,
                  onSelected: (_) => setState(() => _osmMap = true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_osmMap)
              OsmMapView(
                height: 300,
                highlightId: _hubHighlight(order),
                driverLatitude: vehiclePose?.latitude,
                driverLongitude: vehiclePose?.longitude,
              )
            else
              IsoMapView(
                controller: _controller,
                batterySaver: _batterySaver,
                height: 300,
                pickupId: order.pickupLandmarkId,
                dropoffId: order.dropoffLandmarkId,
              ),
            const SizedBox(height: 12),
            BentoCard(
              borderColor: Ce.emerald500.withValues(alpha: 0.45),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimasi tiba',
                          style: TextStyle(fontSize: 10, color: Ce.textMuted),
                        ),
                        Text(
                          formatEta(eta.difference(DateTime.now())),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Ce.emerald500,
                          ),
                        ),
                        Text(
                          '${formatDistance(1200)} · rata-rata '
                          '${_speed.mps.toStringAsFixed(1)} m/s',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Ce.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatRupiah(order.totalPrice),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Ce.text,
                        ),
                      ),
                      Text(
                        order.paymentMethod.label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Ce.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      StatusPill(
                        label: _batterySaver ? 'Mode 2D' : 'Mode 3D',
                        color: _batterySaver ? Ce.warning : Ce.emerald500,
                        compact: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _RouteSummary(order: order),
            if (order.status.isBidding) ...[
              const SizedBox(height: 14),
              _BiddingPanel(orderId: order.id),
            ],
            const SizedBox(height: 14),
            _PinCard(
              pin: pin,
              finished: order.status.isFinished,
              onShare: () async {
                await Clipboard.setData(
                  ClipboardData(text: 'PIN serah-terima: $pin'),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN disalin. Bagikan hanya ke driver.'),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 14),
            const SectionTitle(
              title: 'Progres order',
              subtitle: 'Setiap transisi dicatat sebagai event audit.',
            ),
            _ProcessTimeline(status: order.status),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/chat/${order!.id}'),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('Chat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/support'),
                    icon: const Icon(Icons.support_agent_rounded, size: 18),
                    label: const Text('Bantuan'),
                  ),
                ),
              ],
            ),
            if (order.status == OrderStatus.COMPLETED) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => context.go('/orders/${order!.id}/rating'),
                icon: const Icon(Icons.star_outline_rounded),
                label: const Text('Beri rating driver & merchant'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _hubHighlight(Order order) {
    for (final id in [order.dropoffLandmarkId, order.pickupLandmarkId]) {
      if (TuntunganHubData.byId(id) != null) return id;
    }
    return null;
  }

  void _prepareController(Order order) {
    final key = '${order.id}-${order.status.name}';
    if (_preparedFor == key) return;
    _preparedFor = key;
    _controller.reset();
    final now = DateTime.now();
    final checkpointAt = switch (order.status) {
      OrderStatus.ARRIVED ||
      OrderStatus.COMPLETED => now.subtract(const Duration(hours: 2)),
      OrderStatus.ON_DELIVERY => now.subtract(const Duration(minutes: 2)),
      _ => now.subtract(const Duration(seconds: 20)),
    };
    try {
      _controller.onCheckpoint(
        from: order.tracking?.segmentFrom ?? order.pickupLandmarkId,
        to: order.tracking?.segmentTo ?? order.dropoffLandmarkId,
        at: checkpointAt,
        coords: CampusMapData.coords,
      );
    } catch (_) {
      // Landmark di luar graf preset; peta tetap tampil tanpa animasi.
    }
  }

  DateTime _eta(Order order) {
    final pickedUp =
        order.status.stepIndex >= OrderStatus.ON_DELIVERY.stepIndex;
    try {
      return computeEta(
        _graph,
        EtaInput(
          current: order.tracking?.segmentFrom ?? order.pickupLandmarkId,
          pickup: order.pickupLandmarkId,
          dropoff: order.dropoffLandmarkId,
          pickedUp: pickedUp,
          now: DateTime.now(),
          speedMps: _speed.mps,
          waitBufferSec: pickedUp ? 0 : defaultPrepBufferSec(order.type.name),
        ),
      );
    } catch (_) {
      return DateTime.now().add(const Duration(minutes: 12));
    }
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jemput',
                  style: TextStyle(fontSize: 9.5, color: Ce.textMuted),
                ),
                Text(
                  order.pickupName.isEmpty
                      ? order.pickupLandmarkId
                      : order.pickupName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Ce.text,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: Ce.emerald500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Antar',
                  style: TextStyle(fontSize: 9.5, color: Ce.textMuted),
                ),
                Text(
                  order.dropoffName.isEmpty
                      ? order.dropoffLandmarkId
                      : order.dropoffName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Ce.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              const CircleAvatar(
                radius: 15,
                backgroundColor: Ce.surfaceHigh,
                child: Icon(
                  Icons.two_wheeler_rounded,
                  size: 16,
                  color: Ce.emerald500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                order.driverName ?? 'Menunggu',
                style: const TextStyle(fontSize: 8.5, color: Ce.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  const _PinCard({
    required this.pin,
    required this.finished,
    required this.onShare,
  });

  final String pin;
  final bool finished;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      borderColor: finished ? Ce.emerald500 : Ce.warning,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                finished ? Icons.verified_rounded : Icons.pin_rounded,
                color: finished ? Ce.emerald500 : Ce.warning,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  finished ? 'Serah-terima selesai' : 'PIN serah-terima',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Ce.text,
                  ),
                ),
              ),
              if (!finished)
                TextButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_rounded, size: 15),
                  label: const Text('Bagikan'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final digit in pin.split('')) ...[
                Container(
                  width: 48,
                  height: 58,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Ce.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: finished
                          ? Ce.emerald500
                          : Ce.warning.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    digit,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: finished ? Ce.emerald500 : Ce.text,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tunjukkan PIN hanya saat barang diterima. Driver mengetik PIN '
            'di layar pekerjaan; jangan pernah mengirim PIN lewat chat.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Ce.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ProcessTimeline extends StatelessWidget {
  const _ProcessTimeline({required this.status});

  final OrderStatus status;

  static const _steps = [
    (OrderStatus.PLACED, 'Pesanan dibuat'),
    (OrderStatus.ACCEPTED, 'Merchant menerima'),
    (OrderStatus.READY, 'Pesanan siap'),
    (OrderStatus.AWAITING_DRIVER, 'Driver klaim'),
    (OrderStatus.SEARCHING_BIDS, 'Penawaran driver'),
    (OrderStatus.CLAIMED, 'Menuju titik jemput'),
    (OrderStatus.AT_PICKUP, 'Tiba di titik jemput'),
    (OrderStatus.ON_DELIVERY, 'Dalam perjalanan'),
    (OrderStatus.ARRIVED, 'Tiba di tujuan'),
    (OrderStatus.COMPLETED, 'Selesai'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = status.stepIndex;
    return BentoCard(
      child: Column(
        children: [
          for (var i = 0; i < _steps.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i <= current ? Ce.emerald500 : Ce.surfaceHigh,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i <= current ? Ce.emerald500 : Ce.emerald900,
                        ),
                      ),
                      child: i < current
                          ? const Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Ce.text,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: i == current ? Ce.text : Ce.textMuted,
                              ),
                            ),
                    ),
                    if (i < _steps.length - 1)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 2,
                        height: 24,
                        color: i < current ? Ce.emerald500 : Ce.emerald900,
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      _steps[i].$2,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: i == current
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: i <= current ? Ce.text : Ce.textMuted,
                      ),
                    ),
                  ),
                ),
                if (i == current)
                  const StatusPill(
                    label: 'Sekarang',
                    color: Ce.emerald500,
                    compact: true,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Panel penawaran driver realtime (Reverse Auction) pada layar tracking.
class _BiddingPanel extends ConsumerStatefulWidget {
  const _BiddingPanel({required this.orderId});

  final String orderId;

  @override
  ConsumerState<_BiddingPanel> createState() => _BiddingPanelState();
}

class _BiddingPanelState extends ConsumerState<_BiddingPanel> {
  String? _accepting;

  Future<void> _accept(Bid bid) async {
    setState(() => _accepting = bid.bidId);
    try {
      if (AppConfig.demoMode) {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        ref.read(demoBidsProvider.notifier).accept(bid.bidId);
        ref
            .read(demoOrdersProvider.notifier)
            .setStatus(widget.orderId, OrderStatus.ACCEPTED);
      } else {
        await ref
            .read(gatewayClientProvider)
            .acceptBid(orderId: widget.orderId, bidId: bid.bidId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Penawaran ${formatRupiah(bid.offeredPrice)} diterima. '
            'Harga final terkunci.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menerima penawaran. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _accepting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final demo = AppConfig.demoMode;
    final bids = demo
        ? ref.watch(demoBidsProvider)
        : (ref.watch(_bidsProvider(widget.orderId)).value ?? const <Bid>[]);
    final accepted = bids
        .where((bid) => bid.status == BidStatus.ACCEPTED)
        .toList();
    final pending = bids.where((bid) => bid.status == BidStatus.PENDING).toList();
    final visible = accepted.isNotEmpty ? accepted : pending;
    final locked = accepted.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Penawaran driver',
          subtitle: locked
              ? 'Harga final terkunci. Penawaran lain otomatis ditolak.'
              : '${pending.length} penawaran aktif · pilih harga, ETA, dan rating',
        ),
        if (visible.isEmpty)
          const BentoCard(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.hourglass_empty_rounded, color: Ce.emerald500),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Menunggu penawaran driver masuk...',
                    style: TextStyle(fontSize: 12, color: Ce.textMuted),
                  ),
                ),
              ],
            ),
          )
        else
          for (final bid in visible) ...[
            _BidCardMobile(
              bid: bid,
              locked: locked,
              busy: _accepting == bid.bidId,
              onAccept: () => _accept(bid),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2);
  return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
}

/// Kartu penawaran driver pada layar tracking konsumen.
class _BidCardMobile extends StatelessWidget {
  const _BidCardMobile({
    required this.bid,
    required this.locked,
    required this.busy,
    required this.onAccept,
  });

  final Bid bid;
  final bool locked;
  final bool busy;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final isAccepted = bid.status == BidStatus.ACCEPTED;
    return BentoCard(
      padding: const EdgeInsets.all(13),
      borderColor: isAccepted ? Ce.emerald500 : Ce.emerald900,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: Ce.surfaceHigh,
                child: Text(
                  _initials(bid.driverName),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Ce.emerald500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            bid.driverName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Ce.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          bid.platNumber,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Ce.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: Ce.warning,
                        ),
                        Text(
                          ' ${bid.rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Ce.textMuted,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            ' · ${bid.vehicleModel} · '
                            'ETA ${bid.estimatedArrivalMinutes} mnt',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Ce.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRupiah(bid.offeredPrice),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Ce.emerald500,
                    ),
                  ),
                  Text(
                    'Komisi ${formatRupiah(bid.commission)}',
                    style: const TextStyle(fontSize: 9, color: Ce.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: locked || busy ? null : onAccept,
              icon: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Ce.text,
                      ),
                    )
                  : Icon(
                      isAccepted
                          ? Icons.verified_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
              label: Text(
                isAccepted ? 'PENAWARAN DITERIMA' : 'TERIMA PENAWARAN',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
