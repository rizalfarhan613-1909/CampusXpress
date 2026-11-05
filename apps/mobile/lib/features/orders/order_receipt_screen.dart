import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

final _receiptProvider = StreamProvider.family<Order?, String>((ref, id) {
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

/// Screen 18 (detail) — Digital E-Receipt.
class OrderReceiptScreen extends ConsumerWidget {
  const OrderReceiptScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = AppConfig.demoMode;
    Order? order;
    if (demo) {
      for (final item in ref.watch(demoOrdersProvider)) {
        if (item.id == orderId) order = item;
      }
    } else {
      order = ref.watch(_receiptProvider(orderId)).value;
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('E-Receipt')),
        body: ErrorState(
          message: 'Struk tidak ditemukan atau kamu bukan peserta order ini.',
          onRetry: () => ref.invalidate(_receiptProvider(orderId)),
        ),
      );
    }

    final completed = order.status == OrderStatus.COMPLETED;
    final commission = order.commissionFee > 0
        ? order.commissionFee
        : (order.totalPrice * 0.005).round().clamp(50, 1 << 31).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Receipt'),
        actions: [
          IconButton(
            onPressed: () => _share(context, order!),
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Bagikan struk',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
          children: [
            BentoCard(
              borderColor: completed ? Ce.emerald500 : Ce.warning,
              child: Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (completed ? Ce.emerald500 : Ce.warning)
                          .withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      completed
                          ? Icons.verified_rounded
                          : Icons.receipt_long_rounded,
                      color: completed ? Ce.emerald500 : Ce.warning,
                      size: 27,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    completed ? 'Transaksi selesai' : order.status.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Ce.text,
                    ),
                  ),
                  Text(
                    'Campus Express · #${order.id}',
                    style: const TextStyle(fontSize: 10, color: Ce.textMuted),
                  ),
                  const Divider(height: 22),
                  _Row(
                    label: 'Tanggal',
                    value: formatDateTime(order.createdAt),
                  ),
                  _Row(label: 'Layanan', value: order.type.label),
                  _Row(label: 'Metode bayar', value: order.paymentMethod.label),
                  _Row(label: 'Konsumen', value: order.consumerName),
                  _Row(
                    label: 'Driver',
                    value: order.driverName ?? 'Belum diklaim',
                  ),
                  if (order.merchantName != null)
                    _Row(label: 'Merchant', value: order.merchantName!),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Rute'),
                  _Route(
                    label: 'Jemput',
                    value: order.pickupName.isEmpty
                        ? order.pickupLandmarkId
                        : order.pickupName,
                    color: const Color(0xFF60A5FA),
                  ),
                  const SizedBox(height: 6),
                  _Route(
                    label: 'Antar',
                    value: order.dropoffName.isEmpty
                        ? order.dropoffLandmarkId
                        : order.dropoffName,
                    color: Ce.warning,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Rincian biaya'),
                  if (order.items.isEmpty)
                    const Text(
                      'Tidak ada item katalog (layanan non-UMKM).',
                      style: TextStyle(fontSize: 11, color: Ce.textMuted),
                    )
                  else
                    for (final item in order.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}× ${item.name}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Ce.text,
                                ),
                              ),
                            ),
                            Text(
                              formatRupiah(item.subtotal),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Ce.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                  const Divider(height: 20),
                  _Row(label: 'Subtotal', value: formatRupiah(order.subtotal)),
                  _Row(label: 'Ongkir', value: formatRupiah(order.deliveryFee)),
                  _Row(
                    label: 'Komisi platform (0,5%)',
                    value: formatRupiah(commission),
                    muted: true,
                  ),
                  const Divider(height: 20),
                  _Row(
                    label: 'Total dibayar',
                    value: formatRupiah(order.totalPrice),
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const InfoBanner(
              message:
                  'Komisi platform tidak dibebankan ke konsumen. Struk ini '
                  'adalah bukti digital sah; simpan sampai transaksi selesai.',
              icon: Icons.verified_outlined,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/orders'),
                    icon: const Icon(Icons.list_alt_rounded, size: 17),
                    label: const Text('Riwayat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/support'),
                    icon: const Icon(Icons.support_agent_rounded, size: 17),
                    label: const Text('Bantuan'),
                  ),
                ),
              ],
            ),
            if (completed) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => context.go('/orders/${order!.id}/rating'),
                icon: const Icon(Icons.star_outline_rounded),
                label: const Text('Beri rating'),
              ),
            ] else ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => context.go('/tracking/${order!.id}'),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Lacak order'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context, Order order) async {
    final text = [
      'Campus Express — E-Receipt #${order.id}',
      '${order.type.label} · ${order.status.label}',
      '${order.pickupName} → ${order.dropoffName}',
      'Total: ${formatRupiah(order.totalPrice)} (${order.paymentMethod.label})',
      'Tanggal: ${formatDateTime(order.createdAt)}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Struk disalin ke clipboard.')),
      );
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({
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
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: muted ? 9.5 : 11, color: Ce.textMuted),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 11.5,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              color: muted ? Ce.textMuted : Ce.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _Route extends StatelessWidget {
  const _Route({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, size: 9, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: const TextStyle(fontSize: 9.5, color: Ce.textMuted),
          ),
        ),
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
    );
  }
}
