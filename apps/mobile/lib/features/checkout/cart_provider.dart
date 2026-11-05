import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/merchant.dart';

@immutable
class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
    this.options = const [],
    this.notes = '',
  });

  final Product product;
  final int quantity;
  final List<ProductOption> options;
  final String notes;

  int get optionDelta =>
      options.fold(0, (sum, option) => sum + option.priceDelta);

  int get unitPrice => product.price + optionDelta;

  int get subtotal => unitPrice * quantity;

  String get optionLabel =>
      options.isEmpty ? '' : options.map((option) => option.name).join(', ');

  CartItem copyWith({int? quantity, String? notes}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      options: options,
      notes: notes ?? this.notes,
    );
  }
}

@immutable
class CartState {
  const CartState({
    this.items = const [],
    this.merchantId,
    this.merchantName,
    this.deliveryFee = 0,
  });

  final List<CartItem> items;
  final String? merchantId;
  final String? merchantName;
  final int deliveryFee;

  bool get isEmpty => items.isEmpty;

  int get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);

  int get total => subtotal + deliveryFee;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<CartItem>? items,
    String? merchantId,
    String? merchantName,
    int? deliveryFee,
  }) {
    return CartState(
      items: items ?? this.items,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  bool isDifferentMerchant(String merchantId) =>
      state.merchantId != null &&
      state.merchantId != merchantId &&
      state.items.isNotEmpty;

  void add({
    required Merchant merchant,
    required CartItem item,
    int deliveryFee = 6000,
  }) {
    if (isDifferentMerchant(merchant.id)) {
      state = const CartState();
    }
    final items = [...state.items];
    final index = items.indexWhere(
      (existing) =>
          existing.product.id == item.product.id &&
          existing.optionLabel == item.optionLabel &&
          existing.notes == item.notes,
    );
    if (index >= 0) {
      items[index] = items[index].copyWith(
        quantity: items[index].quantity + item.quantity,
      );
    } else {
      items.add(item);
    }
    state = CartState(
      items: items,
      merchantId: merchant.id,
      merchantName: merchant.name,
      deliveryFee: deliveryFee,
    );
  }

  void remove(String productId, String optionLabel) {
    final items = state.items
        .where(
          (item) =>
              !(item.product.id == productId &&
                  item.optionLabel == optionLabel),
        )
        .toList();
    state = items.isEmpty ? const CartState() : state.copyWith(items: items);
  }

  void updateQuantity(String productId, String optionLabel, int quantity) {
    if (quantity <= 0) {
      remove(productId, optionLabel);
      return;
    }
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.product.id == productId && item.optionLabel == optionLabel)
            item.copyWith(quantity: quantity.clamp(1, 20).toInt())
          else
            item,
      ],
    );
  }

  void clear() => state = const CartState();

  void setDeliveryFee(int fee) => state = state.copyWith(deliveryFee: fee);
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);
