import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/foundation.dart';

enum BidStatus {
  PENDING('Menunggu'),
  ACCEPTED('Diterima'),
  REJECTED('Ditolak');

  const BidStatus(this.label);
  final String label;

  static BidStatus fromCode(String? code) {
    return BidStatus.values.firstWhere(
      (status) => status.name == code,
      orElse: () => BidStatus.PENDING,
    );
  }
}

/// Penawaran driver pada Reverse Auction (`orders/{orderId}/bids/{bidId}`).
@immutable
class Bid {
  const Bid({
    required this.bidId,
    required this.driverId,
    required this.driverName,
    required this.offeredPrice,
    required this.estimatedArrivalMinutes,
    this.driverPhoto,
    this.rating = 5,
    this.platNumber = '',
    this.vehicleModel = 'Motor',
    this.createdAt,
    this.status = BidStatus.PENDING,
  });

  final String bidId;
  final String driverId;
  final String driverName;
  final String? driverPhoto;
  final double rating;
  final String platNumber;
  final String vehicleModel;
  final int offeredPrice;
  final int estimatedArrivalMinutes;
  final DateTime? createdAt;
  final BidStatus status;

  /// Komisi 0,5% dengan minimum Rp 50 (integer, round-half-up).
  int get commission => math.max(50, (offeredPrice + 100) ~/ 200);

  int get netToDriver => offeredPrice - commission;

  Bid copyWith({BidStatus? status}) {
    return Bid(
      bidId: bidId,
      driverId: driverId,
      driverName: driverName,
      driverPhoto: driverPhoto,
      rating: rating,
      platNumber: platNumber,
      vehicleModel: vehicleModel,
      offeredPrice: offeredPrice,
      estimatedArrivalMinutes: estimatedArrivalMinutes,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }

  factory Bid.fromMap(String id, Map<String, dynamic> data) {
    return Bid(
      bidId: (data['bidId'] as String?) ?? id,
      driverId:
          (data['driverId'] as String?) ?? (data['driver_id'] as String?) ?? '',
      driverName:
          (data['driverName'] as String?) ??
          (data['driver_name'] as String?) ??
          'Driver',
      driverPhoto:
          (data['driverPhoto'] as String?) ?? (data['driver_photo'] as String?),
      rating: _asDouble(data['rating']) ?? 5,
      platNumber:
          (data['platNumber'] as String?) ??
          (data['plat_number'] as String?) ??
          '',
      vehicleModel:
          (data['vehicleModel'] as String?) ??
          (data['vehicle_model'] as String?) ??
          'Motor',
      offeredPrice:
          _asInt(data['offeredPrice'] ?? data['offered_price']) ?? 0,
      estimatedArrivalMinutes:
          _asInt(
            data['estimatedArrivalMinutes'] ??
                data['estimated_arrival_minutes'],
          ) ??
          0,
      createdAt: _asDate(data['created_at'] ?? data['createdAt']),
      status: BidStatus.fromCode(data['status'] as String?),
    );
  }

  factory Bid.demo({
    required String bidId,
    required String driverName,
    required int offeredPrice,
    required int estimatedArrivalMinutes,
    double rating = 4.8,
    String platNumber = 'BK 1234 AB',
    String vehicleModel = 'Honda Beat',
    BidStatus status = BidStatus.PENDING,
  }) {
    return Bid(
      bidId: bidId,
      driverId: bidId.replaceFirst('bid_', ''),
      driverName: driverName,
      offeredPrice: offeredPrice,
      estimatedArrivalMinutes: estimatedArrivalMinutes,
      rating: rating,
      platNumber: platNumber,
      vehicleModel: vehicleModel,
      status: status,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _asDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    if (value is Timestamp) return value.toDate();
    return null;
  }
}