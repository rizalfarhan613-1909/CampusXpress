import 'package:flutter/foundation.dart';

@immutable
class ProductOption {
  const ProductOption({required this.name, this.priceDelta = 0});

  final String name;
  final int priceDelta;
}

@immutable
class ProductOptionGroup {
  const ProductOptionGroup({
    required this.name,
    required this.options,
    this.required = false,
    this.maxSelections = 1,
  });

  final String name;
  final List<ProductOption> options;
  final bool required;
  final int maxSelections;
}

@immutable
class Product {
  const Product({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.price,
    required this.category,
    this.description = '',
    this.isAvailable = true,
    this.optionGroups = const [],
    this.imageSeed = 0,
  });

  final String id;
  final String merchantId;
  final String name;
  final int price;
  final String category;
  final String description;
  final bool isAvailable;
  final List<ProductOptionGroup> optionGroups;
  final int imageSeed;

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      merchantId: (data['merchant_id'] as String?) ?? '',
      name: (data['name'] as String?) ?? 'Produk',
      price: (data['price'] as num?)?.round() ?? 0,
      category: (data['category'] as String?) ?? 'Lainnya',
      description: (data['description'] as String?) ?? '',
      isAvailable: data['is_available'] != false && data['available'] != false,
      imageSeed: (data['image_seed'] as num?)?.round() ?? 0,
    );
  }
}

@immutable
class Merchant {
  const Merchant({
    required this.id,
    required this.name,
    required this.landmarkId,
    required this.landmarkName,
    this.description = '',
    this.isOpen = true,
    this.prepTimeMin = 15,
    this.rating = 4.7,
    this.category = 'Makanan',
    this.products = const [],
  });

  final String id;
  final String name;
  final String landmarkId;
  final String landmarkName;
  final String description;
  final bool isOpen;
  final int prepTimeMin;
  final double rating;
  final String category;
  final List<Product> products;

  factory Merchant.fromMap(String id, Map<String, dynamic> data) {
    return Merchant(
      id: id,
      name:
          (data['store_name'] as String?) ??
          (data['name'] as String?) ??
          'Merchant',
      landmarkId: (data['landmark_id'] as String?) ?? '',
      landmarkName: (data['landmark_name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      isOpen: data['is_open'] != false && data['isOpen'] != false,
      prepTimeMin:
          (data['prep_time_min'] as num?)?.round() ??
          (data['prepTimeMin'] as num?)?.round() ??
          15,
      rating: (data['rating'] as num?)?.toDouble() ?? 4.7,
      category: (data['category'] as String?) ?? 'Makanan',
    );
  }

  Merchant copyWith({bool? isOpen, int? prepTimeMin, List<Product>? products}) {
    return Merchant(
      id: id,
      name: name,
      landmarkId: landmarkId,
      landmarkName: landmarkName,
      description: description,
      isOpen: isOpen ?? this.isOpen,
      prepTimeMin: prepTimeMin ?? this.prepTimeMin,
      rating: rating,
      category: category,
      products: products ?? this.products,
    );
  }
}
