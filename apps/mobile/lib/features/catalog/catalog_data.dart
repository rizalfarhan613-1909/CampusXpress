import '../../core/models/merchant.dart';

/// Katalog demo untuk mode tanpa backend. Pada produksi data dibaca dari
/// koleksi `merchants` + `merchantMenus` (di-cache untuk mode offline).
class CatalogData {
  CatalogData._();

  static const merchants = <Merchant>[
    Merchant(
      id: 'merchant-kantin',
      name: 'Kantin Bu Siti',
      landmarkId: 'kantin-pusat-b',
      landmarkName: 'Kantin Pusat B',
      description: 'Masakan rumahan, siap dalam 15 menit.',
      prepTimeMin: 15,
      rating: 4.9,
      category: 'Makanan',
      products: [
        Product(
          id: 'nasi-goreng',
          merchantId: 'merchant-kantin',
          name: 'Nasi Goreng Spesial',
          price: 18000,
          category: 'Makanan',
          description: 'Nasi goreng kampung dengan telur, ayam, dan kerupuk.',
          imageSeed: 1,
          optionGroups: [
            ProductOptionGroup(
              name: 'Level pedas',
              required: true,
              options: [
                ProductOption(name: 'Tidak pedas'),
                ProductOption(name: 'Sedang'),
                ProductOption(name: 'Pedas'),
                ProductOption(name: 'Extra pedas', priceDelta: 1000),
              ],
            ),
            ProductOptionGroup(
              name: 'Tambahan',
              maxSelections: 2,
              options: [
                ProductOption(name: 'Telur mata sapi', priceDelta: 3000),
                ProductOption(name: 'Ayam suwir', priceDelta: 7000),
                ProductOption(name: 'Kerupuk', priceDelta: 1000),
              ],
            ),
          ],
        ),
        Product(
          id: 'mie-ayam',
          merchantId: 'merchant-kantin',
          name: 'Mie Ayam Bakso',
          price: 15000,
          category: 'Makanan',
          description: 'Mie ayam dengan bakso sapi dan pangsit.',
          imageSeed: 2,
          optionGroups: [
            ProductOptionGroup(
              name: 'Pilihan mie',
              required: true,
              options: [
                ProductOption(name: 'Mie kuning'),
                ProductOption(name: 'Mie keriting'),
                ProductOption(name: 'Bihun'),
              ],
            ),
          ],
        ),
        Product(
          id: 'es-teh',
          merchantId: 'merchant-kantin',
          name: 'Es Teh Manis',
          price: 5000,
          category: 'Minuman',
          description: 'Teh manis dingin, segar.',
          imageSeed: 3,
        ),
        Product(
          id: 'ayam-geprek',
          merchantId: 'merchant-kantin',
          name: 'Ayam Geprek Sambal Ijo',
          price: 20000,
          category: 'Makanan',
          description: 'Ayam crispy dengan sambal ijo khas.',
          imageSeed: 4,
          optionGroups: [
            ProductOptionGroup(
              name: 'Level sambal',
              required: true,
              options: [
                ProductOption(name: 'Level 1'),
                ProductOption(name: 'Level 2'),
                ProductOption(name: 'Level 3'),
              ],
            ),
          ],
        ),
      ],
    ),
    Merchant(
      id: 'merchant-kopi',
      name: 'Kedai Kopi Santri',
      landmarkId: 'perpustakaan-pusat',
      landmarkName: 'Perpustakaan Pusat',
      description: 'Kopi manual brew dan camilan ringan.',
      prepTimeMin: 8,
      rating: 4.7,
      category: 'Minuman',
      products: [
        Product(
          id: 'kopi-susu',
          merchantId: 'merchant-kopi',
          name: 'Kopi Susu Gula Aren',
          price: 12000,
          category: 'Minuman',
          description: 'Espresso, susu segar, gula aren.',
          imageSeed: 5,
          optionGroups: [
            ProductOptionGroup(
              name: 'Suhu',
              required: true,
              options: [
                ProductOption(name: 'Iced'),
                ProductOption(name: 'Hot'),
              ],
            ),
          ],
        ),
        Product(
          id: 'croissant',
          merchantId: 'merchant-kopi',
          name: 'Croissant Butter',
          price: 15000,
          category: 'Camilan',
          description: 'Croissant panggang mentega.',
          imageSeed: 6,
        ),
      ],
    ),
    Merchant(
      id: 'merchant-martabak',
      name: 'Martabak Bangka 88',
      landmarkId: 'gate-utama',
      landmarkName: 'Gate Utama',
      description: 'Martabak manis dan telur, buka malam.',
      isOpen: false,
      prepTimeMin: 25,
      rating: 4.6,
      category: 'Camilan',
      products: [
        Product(
          id: 'martabak-coklat',
          merchantId: 'merchant-martabak',
          name: 'Martabak Coklat Keju',
          price: 35000,
          category: 'Camilan',
          description: 'Martabak manis coklat keju.',
          imageSeed: 7,
        ),
      ],
    ),
    Merchant(
      id: 'merchant-sate',
      name: 'Warung Sate Madura',
      landmarkId: 'kost-gang-melati',
      landmarkName: 'Area Kost Gang Melati',
      description: 'Sate ayam dan kambing, bumbu kacang.',
      prepTimeMin: 20,
      rating: 4.8,
      category: 'Makanan',
      products: [
        Product(
          id: 'sate-ayam',
          merchantId: 'merchant-sate',
          name: 'Sate Ayam 10 Tusuk',
          price: 22000,
          category: 'Makanan',
          description: 'Sate ayam dengan bumbu kacang dan lontong.',
          imageSeed: 8,
        ),
      ],
    ),
    Merchant(
      id: 'merchant-kelontong',
      name: 'Toko Kelontong Bu Ani',
      landmarkId: 'kost-gang-mawar',
      landmarkName: 'Area Kost Gang Mawar',
      description: 'Kebutuhan harian mahasiswa.',
      prepTimeMin: 5,
      rating: 4.5,
      category: 'Kebutuhan',
      products: [
        Product(
          id: 'galon',
          merchantId: 'merchant-kelontong',
          name: 'Air Galon Isi Ulang',
          price: 7000,
          category: 'Kebutuhan',
          description: 'Galon 19 liter isi ulang.',
          imageSeed: 9,
        ),
      ],
    ),
  ];

  static Merchant byId(String id) => merchants.firstWhere(
    (merchant) => merchant.id == id,
    orElse: () => merchants.first,
  );

  static Product? productById(String merchantId, String productId) {
    final merchant = byId(merchantId);
    for (final product in merchant.products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  static List<Merchant> search(String query, {String? category}) {
    final q = query.trim().toLowerCase();
    return merchants.where((merchant) {
      final matchQuery =
          q.isEmpty ||
          merchant.name.toLowerCase().contains(q) ||
          merchant.products.any(
            (product) => product.name.toLowerCase().contains(q),
          );
      final matchCategory =
          category == null ||
          category == 'Semua' ||
          merchant.category == category;
      return matchQuery && matchCategory;
    }).toList();
  }

  static const categories = [
    'Semua',
    'Makanan',
    'Minuman',
    'Camilan',
    'Kebutuhan',
  ];
}
