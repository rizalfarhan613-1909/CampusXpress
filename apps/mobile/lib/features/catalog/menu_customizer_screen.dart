import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models/merchant.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/bento_card.dart';
import '../checkout/cart_provider.dart';
import 'catalog_data.dart';

/// Screen 06 — Menu Customizer (M05).
class MenuCustomizerScreen extends ConsumerStatefulWidget {
  const MenuCustomizerScreen({
    super.key,
    required this.merchantId,
    required this.productId,
  });

  final String merchantId;
  final String productId;

  @override
  ConsumerState<MenuCustomizerScreen> createState() =>
      _MenuCustomizerScreenState();
}

class _MenuCustomizerScreenState extends ConsumerState<MenuCustomizerScreen> {
  final Map<String, Set<String>> _selected = {};
  final _notesController = TextEditingController();
  int _quantity = 1;
  String? _error;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final merchant = CatalogData.byId(widget.merchantId);
    final product = _resolveProduct(merchant, widget.productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Menu')),
        body: const EmptyState(
          title: 'Produk tidak ditemukan',
          message: 'Menu mungkin sudah dihapus oleh merchant.',
          icon: Icons.no_food_outlined,
        ),
      );
    }

    final unitPrice = product.price + _optionDelta(product);
    final total = unitPrice * _quantity;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            onPressed: () => context.go('/catalog'),
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'Katalog',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
          children: [
            BentoCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Ce.emerald600, Ce.emerald900],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      product.name.substring(0, 1),
                      style: const TextStyle(
                        fontSize: 26,
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
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Ce.text,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          product.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Ce.textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          formatRupiah(product.price),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Ce.emerald500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (product.optionGroups.isEmpty)
              const InfoBanner(
                message: 'Menu ini tidak memiliki opsi kustom.',
                icon: Icons.tune_rounded,
              ),
            for (final group in product.optionGroups) ...[
              _OptionGroupCard(
                group: group,
                selected: _selected[group.name] ?? const {},
                onToggle: (option) => _toggleOption(group, option),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            const SectionTitle(title: 'Catatan untuk merchant'),
            TextField(
              controller: _notesController,
              maxLength: 140,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Contoh: sambal dipisah, jangan pakai kerupuk…',
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Expanded(child: SectionTitle(title: 'Jumlah')),
                _QuantityStepper(
                  quantity: _quantity,
                  onChanged: (value) => setState(() => _quantity = value),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const SectionTitle(
              title: 'Bandingkan biaya',
              subtitle: 'Ilustrasi komisi aplikasi besar vs Campus Express.',
            ),
            const _PriceRoll(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              InfoBanner(
                message: _error!,
                icon: Icons.error_outline_rounded,
                color: Ce.danger,
              ),
            ],
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
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 10, color: Ce.textMuted),
                  ),
                  Text(
                    formatRupiah(total),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Ce.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addToCart(merchant, product),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('Tambah ke keranjang'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Product? _resolveProduct(Merchant merchant, String productId) {
    if (merchant.id == 'merchant-kantin') {
      final menu = ref.watch(demoMenuProvider);
      for (final product in menu) {
        if (product.id == productId) return product;
      }
    }
    return CatalogData.productById(merchant.id, productId);
  }

  int _optionDelta(Product product) {
    var delta = 0;
    for (final group in product.optionGroups) {
      final selected = _selected[group.name] ?? const <String>{};
      for (final option in group.options) {
        if (selected.contains(option.name)) delta += option.priceDelta;
      }
    }
    return delta;
  }

  void _toggleOption(ProductOptionGroup group, ProductOption option) {
    final current = {...(_selected[group.name] ?? const <String>{})};
    if (current.contains(option.name)) {
      current.remove(option.name);
    } else if (group.maxSelections <= 1) {
      current
        ..clear()
        ..add(option.name);
    } else if (current.length < group.maxSelections) {
      current.add(option.name);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${group.name}: maksimal ${group.maxSelections} pilihan.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _selected[group.name] = current;
      _error = null;
    });
  }

  Future<void> _addToCart(Merchant merchant, Product product) async {
    for (final group in product.optionGroups) {
      if (group.required && (_selected[group.name]?.isEmpty ?? true)) {
        setState(() => _error = 'Pilih ${group.name} terlebih dahulu.');
        return;
      }
    }
    if (!product.isAvailable) {
      setState(() => _error = 'Menu sedang habis.');
      return;
    }

    final cart = ref.read(cartProvider.notifier);
    if (cart.isDifferentMerchant(merchant.id)) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kosongkan keranjang?'),
          content: const Text(
            'Keranjang hanya boleh berisi item dari satu merchant. '
            'Item dari merchant lain akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Kosongkan'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }

    final options = <ProductOption>[];
    for (final group in product.optionGroups) {
      final selected = _selected[group.name] ?? const <String>{};
      for (final option in group.options) {
        if (selected.contains(option.name)) options.add(option);
      }
    }

    cart.add(
      merchant: merchant,
      deliveryFee: 6000,
      item: CartItem(
        product: product,
        quantity: _quantity,
        options: options,
        notes: _notesController.text.trim(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} ditambahkan ke keranjang.')),
    );
    context.go('/checkout');
  }
}

class _OptionGroupCard extends StatelessWidget {
  const _OptionGroupCard({
    required this.group,
    required this.selected,
    required this.onToggle,
  });

  final ProductOptionGroup group;
  final Set<String> selected;
  final ValueChanged<ProductOption> onToggle;

  @override
  Widget build(BuildContext context) {
    final invalid = group.required && selected.isEmpty;
    return BentoCard(
      borderColor: invalid ? Ce.danger.withValues(alpha: 0.6) : Ce.emerald900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Ce.text,
                ),
              ),
              const SizedBox(width: 6),
              StatusPill(
                label: group.required ? 'Wajib' : 'Opsional',
                color: group.required ? Ce.warning : Ce.textMuted,
                compact: true,
              ),
              const Spacer(),
              Text(
                'Maks. ${group.maxSelections}',
                style: const TextStyle(fontSize: 10, color: Ce.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final option in group.options)
            InkWell(
              onTap: () => onToggle(option),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      selected.contains(option.name)
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 19,
                      color: selected.contains(option.name)
                          ? Ce.emerald500
                          : Ce.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option.name,
                        style: const TextStyle(fontSize: 12, color: Ce.text),
                      ),
                    ),
                    if (option.priceDelta > 0)
                      Text(
                        '+${formatRupiah(option.priceDelta)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Ce.emerald500,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Ce.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Ce.emerald900),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity <= 1 ? null : () => onChanged(quantity - 1),
            icon: const Icon(Icons.remove_rounded, size: 18),
            visualDensity: VisualDensity.compact,
          ),
          Text(
            '$quantity',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Ce.text,
            ),
          ),
          IconButton(
            onPressed: quantity >= 20 ? null : () => onChanged(quantity + 1),
            icon: const Icon(Icons.add_rounded, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _PriceRoll extends StatefulWidget {
  const _PriceRoll();

  @override
  State<_PriceRoll> createState() => _PriceRollState();
}

class _PriceRollState extends State<_PriceRoll> {
  double _total = 30000;

  @override
  Widget build(BuildContext context) {
    final bigRate = 0.2;
    final ours = 0.005;
    final saving = _total * (bigRate - ours);

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Nilai pesanan: ',
                style: const TextStyle(fontSize: 11, color: Ce.textMuted),
              ),
              Text(
                formatRupiah(_total.round()),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Ce.text,
                ),
              ),
            ],
          ),
          Slider(
            value: _total,
            min: 10000,
            max: 200000,
            divisions: 38,
            activeColor: Ce.emerald500,
            onChanged: (value) => setState(() => _total = value),
          ),
          Row(
            children: [
              Expanded(
                child: _CostColumn(
                  label: 'Komisi 20% (asumsi)',
                  value: formatRupiah((_total * bigRate).round()),
                  color: Ce.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CostColumn(
                  label: 'Campus Express 0,5%',
                  value: formatRupiah((_total * ours).round()),
                  color: Ce.emerald500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selisih untuk driver/UMKM: ${formatRupiah(saving.round())}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Ce.emerald500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Angka 20% adalah asumsi ilustrasi, bukan data resmi platform lain.',
            style: TextStyle(fontSize: 9.5, color: Ce.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CostColumn extends StatelessWidget {
  const _CostColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9.5, color: Ce.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
