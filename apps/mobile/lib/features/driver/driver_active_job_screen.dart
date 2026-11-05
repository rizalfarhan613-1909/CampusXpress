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
import '../../core/gateway/gateway_client.dart';
import '../../core/models/order.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/bento_card.dart';
import '../tracking/campus_map_data.dart';
import '../tracking/eta_calculator.dart';
import '../tracking/iso_map_view.dart';
import '../tracking/tracking_controller.dart';

final _jobProvider = StreamProvider.family<Order?, String>((ref, id) {
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

/// Screen 10 — Driver Active Job & Navigation (M09).
class DriverActiveJobScreen extends ConsumerStatefulWidget {
  const DriverActiveJobScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<DriverActiveJobScreen> createState() =>
      _DriverActiveJobScreenState();
}

class _DriverActiveJobScreenState extends ConsumerState<DriverActiveJobScreen> {
  final _pinController = TextEditingController();
  final _controller = TrackingController(
    LandmarkGraph.fromEdges([
      for (final edge in CampusMapData.edges)
        EdgeSpec(edge.a, edge.b, edge.meters),
    ]),
    SpeedEstimator(AppConfig.avgSpeedKmh),
  );

  int _attempts = 0;
  DateTime? _lockedUntil;
  bool _submitting = false;
  bool _checkpointLoading = false;
  bool _batterySaver = false;
  String? _error;
  String? _preparedFor;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demo = AppConfig.demoMode;
    Order? order;
    if (demo) {
      for (final item in ref.watch(demoOrdersProvider)) {
        if (item.id == widget.orderId) order = item;
      }
      order ??= Order.demo(
        id: widget.orderId,
        status: OrderStatus.CLAIMED,
        driverId: 'demo-driver',
      );
    } else {
      order = ref.watch(_jobProvider(widget.orderId)).value;
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pekerjaan Aktif')),
        body: ErrorState(
          message: 'Order tidak ditemukan atau bukan tugasmu.',
          onRetry: () => ref.invalidate(_jobProvider(widget.orderId)),
        ),
      );
    }

    _prepareController(order);
    final commission = order.commissionFee > 0
        ? order.commissionFee
        : (order.totalPrice * 0.005).round().clamp(50, 1 << 31).toInt();
    final nextAction = _nextAction(order.status);
    final locked = _lockedUntil?.isAfter(DateTime.now()) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pekerjaan Aktif'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _batterySaver = !_batterySaver),
            icon: Icon(
              _batterySaver
                  ? Icons.battery_saver_rounded
                  : Icons.battery_full_rounded,
            ),
            tooltip: 'Hemat baterai',
          ),
          IconButton(
            onPressed: () => context.go('/driver/wallet'),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Dompet',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            Row(
              children: [
                StatusPill(label: order.status.label, icon: Icons.work_rounded),
                const Spacer(),
                StatusPill(
                  label: order.type.shortLabel,
                  color: Ce.info,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 10),
            IsoMapView(
              controller: _controller,
              batterySaver: _batterySaver,
              height: 210,
              pickupId: order.pickupLandmarkId,
              dropoffId: order.dropoffLandmarkId,
            ),
            const SizedBox(height: 12),
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RouteRow(
                    label: 'Jemput',
                    name: order.pickupName.isEmpty
                        ? order.pickupLandmarkId
                        : order.pickupName,
                    color: const Color(0xFF60A5FA),
                    icon: Icons.trip_origin_rounded,
                  ),
                  const SizedBox(height: 8),
                  _RouteRow(
                    label: 'Antar',
                    name: order.dropoffName.isEmpty
                        ? order.dropoffLandmarkId
                        : order.dropoffName,
                    color: Ce.warning,
                    icon: Icons.place_rounded,
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${order.consumerName} · ${order.paymentMethod.label}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Ce.textMuted,
                          ),
                        ),
                      ),
                      Text(
                        formatRupiah(order.totalPrice),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Ce.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Komisi ${formatRupiah(commission)} dipotong otomatis saat selesai.',
                    style: const TextStyle(fontSize: 9.5, color: Ce.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const SectionTitle(
              title: 'Checkpoint perjalanan',
              subtitle:
                  'Konfirmasi setiap titik agar konsumen melihat progres.',
            ),
            _CheckpointStepper(status: order.status),
            const SizedBox(height: 14),
            if (nextAction != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _checkpointLoading
                      ? null
                      : () => _advance(order!, nextAction),
                  icon: _checkpointLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Ce.text,
                          ),
                        )
                      : Icon(nextAction.icon),
                  label: Text(nextAction.label),
                ),
              ),
            if (order.status == OrderStatus.ARRIVED ||
                order.status == OrderStatus.COMPLETED) ...[
              const SizedBox(height: 14),
              BentoCard(
                borderColor: locked ? Ce.danger : Ce.warning,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.pin_rounded,
                          color: Ce.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'Verifikasi PIN serah-terima',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Ce.text,
                          ),
                        ),
                        const Spacer(),
                        StatusPill(
                          label: '${5 - _attempts} percobaan',
                          color: _attempts >= 3 ? Ce.danger : Ce.textMuted,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Minta konsumen menunjukkan PIN 4 digit. Jangan pernah '
                      'meminta PIN lewat chat.',
                      style: TextStyle(fontSize: 10, color: Ce.textMuted),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      enabled: !locked && order.status != OrderStatus.COMPLETED,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 18,
                        color: Ce.text,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••',
                        hintStyle: const TextStyle(
                          fontSize: 30,
                          letterSpacing: 18,
                          color: Ce.textMuted,
                        ),
                        errorText: _error,
                        fillColor: Ce.bg,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            locked ||
                                _submitting ||
                                order.status == OrderStatus.COMPLETED
                            ? null
                            : () => _complete(order!, commission),
                        child: Text(
                          locked
                              ? 'Terkunci 10 menit'
                              : order.status == OrderStatus.COMPLETED
                              ? 'Order selesai'
                              : _submitting
                              ? 'Memverifikasi…'
                              : 'Selesaikan order',
                        ),
                      ),
                    ),
                    if (locked) ...[
                      const SizedBox(height: 8),
                      Text(
                        'PIN salah 5 kali. Coba lagi setelah '
                        '${formatTime(_lockedUntil)} atau hubungi Help Desk.',
                        style: const TextStyle(fontSize: 10, color: Ce.danger),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/chat/${order!.id}'),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 17,
                    ),
                    label: const Text('Chat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEmergency(order!),
                    icon: const Icon(Icons.emergency_share_rounded, size: 17),
                    label: const Text('WA Darurat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const InfoBanner(
              message:
                  'Pintasan WhatsApp hanya untuk darurat: chat in-app tidak '
                  'direspons ≥ 3 menit atau fitur chat error.',
              icon: Icons.warning_amber_rounded,
              color: Ce.warning,
            ),
          ],
        ),
      ),
    );
  }

  void _prepareController(Order order) {
    final key = '${order.id}-${order.status.name}';
    if (_preparedFor == key) return;
    _preparedFor = key;
    _controller.reset();
    try {
      _controller.onCheckpoint(
        from: order.pickupLandmarkId,
        to: order.dropoffLandmarkId,
        at: order.status == OrderStatus.ARRIVED
            ? DateTime.now().subtract(const Duration(hours: 2))
            : DateTime.now().subtract(const Duration(minutes: 1)),
        coords: CampusMapData.coords,
      );
    } catch (_) {
      // Landmark di luar graf preset.
    }
  }

  _NextAction? _nextAction(OrderStatus status) {
    return switch (status) {
      OrderStatus.CLAIMED => const _NextAction(
        'Saya tiba di titik jemput',
        Icons.location_on_rounded,
        OrderStatus.AT_PICKUP,
      ),
      OrderStatus.AT_PICKUP => const _NextAction(
        'Mulai antar pesanan',
        Icons.delivery_dining_rounded,
        OrderStatus.ON_DELIVERY,
      ),
      OrderStatus.ON_DELIVERY => const _NextAction(
        'Saya tiba di tujuan',
        Icons.flag_rounded,
        OrderStatus.ARRIVED,
      ),
      _ => null,
    };
  }

  Future<void> _advance(Order order, _NextAction action) async {
    setState(() => _checkpointLoading = true);
    try {
      if (AppConfig.demoMode) {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        ref.read(demoOrdersProvider.notifier).setStatus(order.id, action.next);
      } else {
        await FirebaseFirestore.instance
            .collection(FirestorePaths.orders)
            .doc(order.id)
            .update({
              'status': action.next.name,
              'tracking': {
                'segmentFrom': order.pickupLandmarkId,
                'segmentTo': order.dropoffLandmarkId,
                'checkpointAt': FieldValue.serverTimestamp(),
              },
              'updated_at': FieldValue.serverTimestamp(),
            });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkpoint: ${action.next.label}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan checkpoint. Coba lagi.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkpointLoading = false);
    }
  }

  Future<void> _complete(Order order, int commission) async {
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      setState(() => _error = 'PIN harus 4 digit.');
      return;
    }
    if (_lockedUntil?.isAfter(DateTime.now()) ?? false) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      if (AppConfig.demoMode) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (pin != (order.pin ?? '4821')) {
          _registerWrongPin();
          return;
        }
        ref
            .read(demoOrdersProvider.notifier)
            .setStatus(order.id, OrderStatus.COMPLETED);
        ref.read(demoWalletBalanceProvider.notifier).deduct(commission);
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Order selesai'),
            content: Text(
              'PIN benar. Komisi ${formatRupiah(commission)} dipotong dari '
              'saldo deposit. E-receipt tersedia di riwayat order.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Selesai'),
              ),
            ],
          ),
        );
        if (mounted) context.go('/driver/radar');
      } else {
        final result = await ref
            .read(gatewayClientProvider)
            .completeOrder(order.id, pin);
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Order selesai'),
            content: Text(
              'Komisi ${formatRupiah((result['commission'] as num?)?.round() ?? commission)} '
              'dipotong. Saldo akhir: '
              '${formatRupiah((result['balanceAfter'] as num?)?.round() ?? 0)}.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Selesai'),
              ),
            ],
          ),
        );
        if (mounted) context.go('/driver/radar');
      }
    } on GatewayException catch (error) {
      if (error.code == 'PIN_LOCKED') {
        setState(() {
          _attempts = 5;
          _lockedUntil = DateTime.now().add(const Duration(minutes: 10));
          _error = error.message.isEmpty
              ? 'PIN terkunci 10 menit.'
              : error.message;
        });
      } else if (error.code == 'PIN_WRONG') {
        _registerWrongPin();
      } else {
        setState(
          () => _error = error.message.isEmpty
              ? 'Gagal menyelesaikan order.'
              : error.message,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Gagal menyelesaikan order. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _registerWrongPin() {
    setState(() {
      _attempts++;
      if (_attempts >= 5) {
        _lockedUntil = DateTime.now().add(const Duration(minutes: 10));
        _error = 'PIN salah 5 kali. Input terkunci 10 menit.';
      } else {
        _error = 'PIN salah. Sisa percobaan: ${5 - _attempts}.';
      }
    });
  }

  void _showEmergency(Order order) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('WhatsApp Darurat'),
        content: Text(
          'Gunakan hanya bila chat in-app tidak direspons ≥ 3 menit. '
          'Nomor konsumen: 0812-3456-7890.\n\n'
          'Order: ${order.id}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(
                const ClipboardData(text: '081234567890'),
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nomor darurat disalin.')),
                );
              }
            },
            child: const Text('Salin nomor'),
          ),
        ],
      ),
    );
  }
}

class _NextAction {
  const _NextAction(this.label, this.icon, this.next);

  final String label;
  final IconData icon;
  final OrderStatus next;
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.label,
    required this.name,
    required this.color,
    required this.icon,
  });

  final String label;
  final String name;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 46,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, color: Ce.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Ce.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckpointStepper extends StatelessWidget {
  const _CheckpointStepper({required this.status});

  final OrderStatus status;

  static const _steps = [
    (OrderStatus.CLAIMED, 'Order diklaim'),
    (OrderStatus.AT_PICKUP, 'Tiba di titik jemput'),
    (OrderStatus.ON_DELIVERY, 'Mulai antar'),
    (OrderStatus.ARRIVED, 'Tiba di tujuan'),
    (OrderStatus.COMPLETED, 'PIN terverifikasi'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _steps.indexWhere((step) => step.$1 == status);
    final index = current < 0 ? 0 : current;
    return BentoCard(
      child: Row(
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i <= index ? Ce.emerald500 : Ce.surfaceHigh,
                      shape: BoxShape.circle,
                    ),
                    child: i < index
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
                              color: i == index ? Ce.text : Ce.textMuted,
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _steps[i].$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      color: i <= index ? Ce.text : Ce.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (i < _steps.length - 1)
              Container(
                width: 10,
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                color: i < index ? Ce.emerald500 : Ce.emerald900,
              ),
          ],
        ],
      ),
    );
  }
}
