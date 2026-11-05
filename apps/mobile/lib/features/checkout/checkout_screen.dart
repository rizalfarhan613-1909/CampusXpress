import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/models/order.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/bento_card.dart';
import '../landmarks/landmark_data.dart';
import '../tracking/campus_map_data.dart';
import '../tracking/eta_calculator.dart';
import 'cart_provider.dart';

/// Screen 07 — Cart & Checkout (M06).
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, this.extra});

  final Map<String, dynamic>? extra;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  PaymentMethod _method = PaymentMethod.COD;
  bool _proofAttached = false;
  bool _loading = false;
  String? _error;

  String get _type => (widget.extra?['type'] as String?) ?? 'umkm';
  String get _pickup =>
      (widget.extra?['pickup'] as String?) ?? 'kantin-pusat-b';
  String get _dropoff =>
      (widget.extra?['dropoff'] as String?) ?? 'gedung-kuliah-terpadu';

  int _deliveryFee(CartState cart) {
    final fromExtra = widget.extra?['deliveryFee'];
    if (fromExtra is int) return fromExtra;
    if (cart.deliveryFee > 0) return cart.deliveryFee;
    return LandmarkData.fareFor(_pickup, _dropoff);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Keranjang')),
        body: EmptyState(
          title: 'Keranjang kosong',
          message: 'Pilih menu atau layanan terlebih dahulu.',
          icon: Icons.shopping_cart_outlined,
          action: FilledButton(
            onPressed: () => context.go('/catalog'),
            child: const Text('Buka katalog'),
          ),
        ),
      );
    }

    final deliveryFee = _deliveryFee(cart);
    final subtotal = cart.subtotal;
    final total = subtotal + deliveryFee;
    final codDisabled = total > AppConfig.codMax;
    final method = codDisabled && _method == PaymentMethod.COD
        ? PaymentMethod.QRIS_STATIC
        : _method;
    final eta = _estimateEta(total);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
          children: [
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        size: 18,
                        color: Ce.emerald500,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cart.merchantName ?? 'Merchant',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Ce.text,
                          ),
                        ),
                      ),
                      StatusPill(
                        label: OrderType.fromCode(_type).shortLabel,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final item in cart.items) ...[
                    _CartLine(
                      item: item,
                      onRemove: () => ref
                          .read(cartProvider.notifier)
                          .remove(item.product.id, item.optionLabel),
                      onQuantity: (quantity) => ref
                          .read(cartProvider.notifier)
                          .updateQuantity(
                            item.product.id,
                            item.optionLabel,
                            quantity,
                          ),
                    ),
                    const Divider(height: 18),
                  ],
                  _SummaryRow(label: 'Subtotal', value: formatRupiah(subtotal)),
                  _SummaryRow(
                    label:
                        'Ongkir (${LandmarkData.byId(_pickup).zone} → '
                        '${LandmarkData.byId(_dropoff).zone})',
                    value: formatRupiah(deliveryFee),
                  ),
                  _SummaryRow(
                    label: 'Komisi (tidak dibebankan ke konsumen)',
                    value: formatRupiah(max(50, (total * 0.005).round())),
                    muted: true,
                  ),
                  const Divider(height: 18),
                  _SummaryRow(
                    label: 'Total',
                    value: formatRupiah(total),
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rute pengantaran',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Ce.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _RouteLine(
                    icon: Icons.trip_origin_rounded,
                    color: const Color(0xFF60A5FA),
                    title: 'Jemput',
                    value: LandmarkData.byId(_pickup).name,
                  ),
                  _RouteLine(
                    icon: Icons.place_rounded,
                    color: Ce.warning,
                    title: 'Antar',
                    value: LandmarkData.byId(_dropoff).name,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 15,
                        color: Ce.emerald500,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Estimasi tiba ${formatEta(Duration(seconds: eta))}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Ce.emerald500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const SectionTitle(
              title: 'Metode pembayaran',
              subtitle: 'Tidak ada pembayaran otomatis di aplikasi (v1).',
            ),
            _PaymentCard(
              selected: method == PaymentMethod.COD,
              icon: Icons.payments_outlined,
              title: 'COD Tunai',
              subtitle: 'Bayar langsung ke driver/merchant saat serah-terima.',
              disabled: codDisabled,
              disabledReason:
                  'COD maksimal ${formatRupiah(AppConfig.codMax)}. Gunakan QRIS.',
              onTap: () => setState(() => _method = PaymentMethod.COD),
            ),
            const SizedBox(height: 8),
            _PaymentCard(
              selected: method == PaymentMethod.QRIS_STATIC,
              icon: Icons.qr_code_2_rounded,
              title: 'QRIS Statis',
              subtitle:
                  'Bayar ke QRIS penerima lalu unggah bukti. Penerima mengonfirmasi.',
              onTap: () => setState(() => _method = PaymentMethod.QRIS_STATIC),
            ),
            if (method == PaymentMethod.QRIS_STATIC) ...[
              const SizedBox(height: 10),
              BentoCard(
                borderColor: _proofAttached ? Ce.emerald500 : Ce.warning,
                child: Row(
                  children: [
                    Icon(
                      _proofAttached
                          ? Icons.check_circle_rounded
                          : Icons.upload_file_rounded,
                      color: _proofAttached ? Ce.emerald500 : Ce.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _proofAttached
                                ? 'Bukti pembayaran terpasang'
                                : 'Bukti pembayaran belum diunggah',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Ce.text,
                            ),
                          ),
                          const Text(
                            'Gambar dikompres WebP ≤ 80 KB sebelum unggah.',
                            style: TextStyle(fontSize: 10, color: Ce.textMuted),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _proofAttached = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bukti demo terpasang (WebP 62 KB).'),
                          ),
                        );
                      },
                      child: Text(_proofAttached ? 'Ganti' : 'Unggah'),
                    ),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              InfoBanner(
                message: _error!,
                icon: Icons.error_outline_rounded,
                color: Ce.danger,
              ),
            ],
            const SizedBox(height: 14),
            const InfoBanner(
              message:
                  'Total dihitung ulang oleh server. Jika berbeda, pesanan '
                  'tidak dibuat dan kamu akan diberi tahu.',
              icon: Icons.verified_outlined,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: Ce.surface,
            border: Border(top: BorderSide(color: Ce.emerald900)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 11, color: Ce.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    formatRupiah(total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Ce.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      _loading ||
                          (method == PaymentMethod.QRIS_STATIC &&
                              !_proofAttached)
                      ? null
                      : () => _placeOrder(cart, total, deliveryFee, method),
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Ce.text,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _loading
                        ? 'Memproses…'
                        : method == PaymentMethod.QRIS_STATIC && !_proofAttached
                        ? 'Unggah bukti QRIS dulu'
                        : 'Pesan sekarang',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _estimateEta(int total) {
    final graph = LandmarkGraph.fromEdges([
      for (final edge in CampusMapData.edges)
        EdgeSpec(edge.a, edge.b, edge.meters),
    ]);
    try {
      final result = computeEtaDetailed(
        graph,
        EtaInput(
          current: _pickup,
          pickup: _pickup,
          dropoff: _dropoff,
          pickedUp: false,
          now: DateTime.now(),
          speedMps: AppConfig.avgSpeedKmh / 3.6,
          waitBufferSec: defaultPrepBufferSec(_type),
        ),
      );
      return result.eta.difference(DateTime.now()).inSeconds;
    } catch (_) {
      return 600;
    }
  }

  Future<void> _placeOrder(
    CartState cart,
    int total,
    int deliveryFee,
    PaymentMethod method,
  ) async {
    if (total > AppConfig.orderMax) {
      setState(() => _error = 'Total order melebihi Rp 500.000.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final now = DateTime.now();
    final random = Random.secure();
    final pin = random.nextInt(10000).toString().padLeft(4, '0');
    final items = [
      for (final item in cart.items)
        OrderItem(
          name: item.product.name,
          quantity: item.quantity,
          price: item.unitPrice,
          notes: [
            item.optionLabel,
            item.notes,
          ].where((value) => value.isNotEmpty).join(' · '),
        ),
    ];
    final id = 'CE-${now.millisecondsSinceEpoch}';

    final order = Order(
      id: id,
      consumerId: 'demo-consumer',
      type: OrderType.fromCode(_type),
      status: OrderStatus.AWAITING_DRIVER,
      pickupLandmarkId: _pickup,
      dropoffLandmarkId: _dropoff,
      pickupName: LandmarkData.byId(_pickup).name,
      dropoffName: LandmarkData.byId(_dropoff).name,
      consumerName: 'Rani Mahasiswa',
      merchantId: cart.merchantId,
      merchantName: cart.merchantName,
      totalPrice: total,
      deliveryFee: deliveryFee,
      commissionFee: max(50, (total * 0.005).round()),
      paymentMethod: method,
      items: items,
      pin: pin,
      createdAt: now,
      etaSeconds: _estimateEta(total),
      distanceMeters: 1200,
    );

    try {
      if (AppConfig.demoMode) {
        ref.read(demoOrdersProvider.notifier).add(order);
      } else {
        final response = await ref.read(gatewayClientProvider).post('/orders', {
          'type': _type,
          'pickupLandmarkId': _pickup,
          'dropoffLandmarkId': _dropoff,
          'paymentMethod': method.name,
          'items': [
            for (final item in items)
              {
                'name': item.name,
                'quantity': item.quantity,
                'price': item.price,
                'notes': item.notes,
              },
          ],
          'idempotencyKey': const Uuid().v4(),
          'proofAttached': _proofAttached,
        });
        final serverId = (response['orderId'] as String?) ?? id;
        ref.read(cartProvider.notifier).clear();
        if (!mounted) return;
        context.go('/tracking/$serverId');
        return;
      }
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      context.go('/tracking/$id');
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Gagal membuat order. Periksa koneksi lalu coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.item,
    required this.onRemove,
    required this.onQuantity,
  });

  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantity;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Ce.text,
                ),
              ),
              if (item.optionLabel.isNotEmpty)
                Text(
                  item.optionLabel,
                  style: const TextStyle(fontSize: 10, color: Ce.textMuted),
                ),
              if (item.notes.isNotEmpty)
                Text(
                  'Catatan: ${item.notes}',
                  style: const TextStyle(fontSize: 10, color: Ce.textMuted),
                ),
              Text(
                formatRupiah(item.subtotal),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Ce.emerald500,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Ce.emerald900),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => onQuantity(item.quantity - 1),
                icon: const Icon(Icons.remove_rounded, size: 16),
              ),
              Text(
                '${item.quantity}',
                style: const TextStyle(fontSize: 12, color: Ce.text),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => onQuantity(item.quantity + 1),
                icon: const Icon(Icons.add_rounded, size: 16),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onRemove,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          color: Ce.danger,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: muted ? 10 : 12, color: Ce.textMuted),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 12,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              color: muted ? Ce.textMuted : Ce.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Ce.textMuted),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Ce.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.disabled = false,
    this.disabledReason,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool disabled;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: BentoCard(
        onTap: disabled ? null : onTap,
        borderColor: selected ? Ce.emerald500 : Ce.emerald900,
        child: Row(
          children: [
            Icon(icon, color: selected ? Ce.emerald500 : Ce.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Ce.text,
                    ),
                  ),
                  Text(
                    disabled ? (disabledReason ?? subtitle) : subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: disabled ? Ce.danger : Ce.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? Ce.emerald500 : Ce.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
