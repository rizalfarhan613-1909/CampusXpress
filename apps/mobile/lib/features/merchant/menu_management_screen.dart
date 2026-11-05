import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/models/merchant.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/bento_card.dart';

/// Screen 17 — UMKM Menu Management & Add/Edit Product (M15).
class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
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
    final menu = ref.watch(demoMenuProvider);
    final filtered = menu.where((product) {
      final matchQuery =
          _query.trim().isEmpty ||
          product.name.toLowerCase().contains(_query.toLowerCase());
      final matchCategory =
          _category == 'Semua' || product.category == _category;
      return matchQuery && matchCategory;
    }).toList();
    final categories = <String>{
      'Semua',
      for (final product in menu) product.category,
    }.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Menu'),
        actions: [
          IconButton(
            onPressed: () => context.go('/merchant'),
            icon: const Icon(Icons.dashboard_outlined),
            tooltip: 'Dashboard',
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: const InputDecoration(
                            hintText: 'Cari produk…',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed:
                            menu.length >= AppConfig.maxProductsPerMerchant
                            ? null
                            : () => _editProduct(null),
                        child: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final category in categories)
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  StatusPill(
                    label:
                        '${menu.length} / '
                        '${AppConfig.maxProductsPerMerchant} produk',
                    color: menu.length >= AppConfig.maxProductsPerMerchant
                        ? Ce.danger
                        : Ce.emerald500,
                    compact: true,
                  ),
                  const Spacer(),
                  Text(
                    '${menu.where((product) => product.isAvailable).length} aktif',
                    style: const TextStyle(fontSize: 10, color: Ce.textMuted),
                  ),
                ],
              ),
            ),
            if (menu.length >= AppConfig.maxProductsPerMerchant)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: InfoBanner(
                  message:
                      'Batas 150 produk tercapai. Hapus produk lama untuk '
                      'menambah menu baru.',
                  icon: Icons.inventory_2_outlined,
                  color: Ce.warning,
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(
                      title: 'Menu tidak ditemukan',
                      message: 'Ubah kata kunci atau tambah produk baru.',
                      icon: Icons.restaurant_menu_outlined,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return _ProductRow(
                          product: product,
                          onEdit: () => _editProduct(product),
                          onToggle: () => ref
                              .read(demoMenuProvider.notifier)
                              .toggleAvailability(product.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProduct(Product? product) async {
    final saved = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ProductForm(initial: product),
    );
    if (saved == null) return;
    ref.read(demoMenuProvider.notifier).save(saved);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            product == null
                ? '${saved.name} ditambahkan ke menu.'
                : '${saved.name} diperbarui.',
          ),
        ),
      );
    }
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.onEdit,
    required this.onToggle,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(12),
      onTap: onEdit,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: product.isAvailable
                    ? [Ce.emerald600, Ce.emerald900]
                    : [Ce.surfaceHigh, Ce.surface],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              product.name.isEmpty ? '?' : product.name.substring(0, 1),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Ce.text,
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
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Ce.text,
                        ),
                      ),
                    ),
                    StatusPill(
                      label: product.isAvailable ? 'Tersedia' : 'Habis',
                      color: product.isAvailable ? Ce.emerald500 : Ce.danger,
                      compact: true,
                    ),
                  ],
                ),
                Text(
                  '${product.category} · ${formatRupiah(product.price)}',
                  style: const TextStyle(fontSize: 10.5, color: Ce.textMuted),
                ),
                if (product.optionGroups.isNotEmpty)
                  Text(
                    '${product.optionGroups.length} grup opsi',
                    style: const TextStyle(fontSize: 9.5, color: Ce.textMuted),
                  ),
              ],
            ),
          ),
          Switch(
            value: product.isAvailable,
            activeThumbColor: Ce.emerald500,
            onChanged: (_) => onToggle(),
          ),
        ],
      ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  const _ProductForm({this.initial});

  final Product? initial;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late String _category;
  late bool _available;
  bool _photoAttached = false;

  static const _categories = [
    'Makanan',
    'Minuman',
    'Camilan',
    'Kebutuhan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? '');
    _price = TextEditingController(text: '${initial?.price ?? ''}');
    _description = TextEditingController(text: initial?.description ?? '');
    _category = initial?.category ?? 'Makanan';
    _available = initial?.isAvailable ?? true;
    _photoAttached = initial?.imageSeed != null && initial!.imageSeed > 0;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initial == null ? 'Tambah Produk' : 'Edit Produk',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Ce.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Foto dikompres WebP ≤ 80 KB. Perubahan langsung tampil di '
                'katalog konsumen.',
                style: TextStyle(fontSize: 11, color: Ce.textMuted),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                maxLength: 60,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama produk',
                  hintText: 'Contoh: Nasi Goreng Spesial',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 2) return 'Nama minimal 2 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  prefixText: 'Rp ',
                  hintText: '18000',
                ),
                validator: (value) {
                  final price = int.tryParse(value ?? '');
                  if (price == null || price < 1000) {
                    return 'Harga minimal Rp 1.000';
                  }
                  if (price > 500000) return 'Harga maksimal Rp 500.000';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  for (final category in _categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLength: 140,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Bahan, porsi, atau catatan lain',
                ),
              ),
              const SizedBox(height: 4),
              BentoCard(
                borderColor: _photoAttached ? Ce.emerald500 : Ce.emerald900,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _photoAttached
                          ? Icons.image_rounded
                          : Icons.add_photo_alternate_outlined,
                      color: _photoAttached ? Ce.emerald500 : Ce.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _photoAttached
                            ? 'Foto produk terpasang (WebP)'
                            : 'Belum ada foto produk',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Ce.textMuted,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _photoAttached = !_photoAttached),
                      child: Text(_photoAttached ? 'Hapus' : 'Unggah'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _available,
                activeThumbColor: Ce.emerald500,
                title: const Text(
                  'Tersedia untuk dipesan',
                  style: TextStyle(fontSize: 13, color: Ce.text),
                ),
                subtitle: const Text(
                  'Matikan saat bahan habis; produk tetap tampil di katalog.',
                  style: TextStyle(fontSize: 10, color: Ce.textMuted),
                ),
                onChanged: (value) => setState(() => _available = value),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    widget.initial == null
                        ? 'Tambah produk'
                        : 'Simpan perubahan',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final price = int.parse(_price.text.trim());
    final initial = widget.initial;
    final product = Product(
      id: initial?.id ?? 'product-${DateTime.now().millisecondsSinceEpoch}',
      merchantId: initial?.merchantId ?? 'merchant-kantin',
      name: _name.text.trim(),
      price: price,
      category: _category,
      description: _description.text.trim(),
      isAvailable: _available,
      optionGroups: initial?.optionGroups ?? const [],
      imageSeed: _photoAttached ? 1 : (initial?.imageSeed ?? 0),
    );
    Navigator.of(context).pop(product);
  }
}
