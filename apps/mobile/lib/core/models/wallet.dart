import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum WalletTxType {
  topup('Top-up', true),
  commission('Komisi order', false),
  adjustment('Penyesuaian', true),
  refund('Refund', true),
  COMMISSION_TOPUP('Top-up komisi', true),
  COMMISSION_DEDUCTION('Potongan komisi', false);

  const WalletTxType(this.label, this.positive);
  final String label;
  final bool positive;

  static WalletTxType fromCode(String? code) {
    return WalletTxType.values.firstWhere(
      (type) => type.name == code,
      orElse: () => WalletTxType.adjustment,
    );
  }
}

@immutable
class WalletTx {
  const WalletTx({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    this.createdAt,
    this.balanceAfter,
    this.orderId,
  });

  final String id;
  final int amount;
  final WalletTxType type;
  final String description;
  final DateTime? createdAt;
  final int? balanceAfter;
  final String? orderId;

  bool get isCredit => amount >= 0;

  factory WalletTx.fromMap(String id, Map<String, dynamic> data) {
    final createdAt = data['created_at'] ?? data['createdAt'];
    return WalletTx(
      id: id,
      amount: (data['amount'] as num?)?.round() ?? 0,
      type: WalletTxType.fromCode(
        (data['type'] as String?) ?? (data['kind'] as String?),
      ),
      description: (data['description'] as String?) ?? 'Transaksi dompet',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : createdAt is DateTime
          ? createdAt
          : null,
      balanceAfter:
          (data['balance_after'] as num?)?.round() ??
          (data['balanceAfter'] as num?)?.round(),
      orderId: (data['order_id'] as String?) ?? (data['orderId'] as String?),
    );
  }

  factory WalletTx.demo({
    required String id,
    required int amount,
    required WalletTxType type,
    required String description,
    required DateTime createdAt,
  }) {
    return WalletTx(
      id: id,
      amount: amount,
      type: type,
      description: description,
      createdAt: createdAt,
    );
  }
}
