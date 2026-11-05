import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models/merchant.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/bento_card.dart';
import 'catalog_data.dart';

/// Screen 05 — Merchant Catalog & Food List (M04).
class MerchantCatalogScreen extends ConsumerStatefulWidget {
  const MerchantCatalogScreen({super.key});

  @override
  ConsumerState<MerchantCatalogScreen> createState() =>
      _MerchantCatalogScreenState();
}

class _MerchantCatalogScreenState extends ConsumerState<MerchantCatalogScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = CatalogData.search(_query, category: _category);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Kampus'),
        actions: [
          IconButton(
            onPressed: () => context.go('/orders'),
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Riwayat order',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Cari merchant atau menu…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final category in CatalogData.categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: _category == category,
                              onSelected: (_) =>
                                  setState(() => _category = category),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? const EmptyState(
                      title: 'Katalog kosong',
                      message:
                          'Tidak ada merchant pada kategori ini. Coba kata kunci lain.',
                      icon: Icons.storefront_outlined,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final merchant = results[index];
                        return _MerchantCard(merchant: merchant);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({required this.merchant});

  final Merchant merchant;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      onTap: merchant.isOpen
          ? () => _showMerchantSheet(context, merchant)
          : () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${merchant.name} sedang tutup.')),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: merchant.isOpen
                        ? [Ce.emerald600, Ce.emerald900]
                        : [Ce.surfaceHigh, Ce.surface],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  merchant.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Ce.text,
                  ),
                ),
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
                            merchant.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Ce.text,
                            ),
                          ),
                        ),
                        StatusPill(
                          label: merchant.isOpen ? 'Buka' : 'Tutup',
                          color: merchant.isOpen ? Ce.emerald500 : Ce.danger,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${merchant.category} · ${merchant.landmarkName}',
                      style: const TextStyle(fontSize: 11, color: Ce.textMuted),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Ce.warning,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          merchant.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Ce.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: Ce.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${merchant.prepTimeMin} menit',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Ce.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            merchant.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Ce.textMuted),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: merchant.products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final product = merchant.products[index];
                return ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    '${product.name} · Rp ${product.price ~/ 1000}k',
                    style: const TextStyle(fontSize: 10),
                  ),
                  onPressed: merchant.isOpen
                      ? () => context.go('/menu/${merchant.id}/${product.id}')
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMerchantSheet(BuildContext context, Merchant merchant) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              children: [
                Text(
                  merchant.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Ce.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  merchant.description,
                  style: const TextStyle(fontSize: 12, color: Ce.textMuted),
                ),
                const SizedBox(height: 14),
                for (final product in merchant.products)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BentoCard(
                      onTap: product.isAvailable
                          ? () {
                              Navigator.of(context).pop();
                              context.go('/menu/${merchant.id}/${product.id}');
                            }
                          : null,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Ce.text,
                                  ),
                                ),
                                Text(
                                  product.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Ce.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rp ${product.price}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Ce.emerald500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
