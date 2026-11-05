import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum OrderStatus {
  PLACED('Dibuat', 'Pesanan dibuat'),
  ACCEPTED('Diterima', 'Merchant menerima pesanan'),
  READY('Siap', 'Pesanan siap diambil'),
  AWAITING_DRIVER('Cari driver', 'Menunggu driver klaim'),
  SEARCHING_BIDS('Cari penawaran', 'Menunggu penawaran driver'),
  CLAIMED('Diklaim', 'Driver menuju titik jemput'),
  AT_PICKUP('Di titik jemput', 'Driver tiba di titik jemput'),
  ON_DELIVERY('Diantar', 'Pesanan dalam perjalanan'),
  ARRIVED('Tiba', 'Driver tiba di tujuan'),
  COMPLETED('Selesai', 'Serah-terima selesai'),
  CANCELLED('Dibatalkan', 'Pesanan dibatalkan'),
  EXPIRED('Kedaluwarsa', 'Pesanan kedaluwarsa'),
  DISPUTED('Sengketa', 'Pesanan dalam sengketa');

  const OrderStatus(this.label, this.description);
  final String label;
  final String description;

  static OrderStatus fromCode(String? code) {
    return OrderStatus.values.firstWhere(
      (status) => status.name == code,
      orElse: () => OrderStatus.PLACED,
    );
  }

  bool get isActive => ![
    OrderStatus.COMPLETED,
    OrderStatus.CANCELLED,
    OrderStatus.EXPIRED,
  ].contains(this);

  bool get isFinished => [
    OrderStatus.COMPLETED,
    OrderStatus.CANCELLED,
    OrderStatus.EXPIRED,
  ].contains(this);

  int get stepIndex {
    const flow = [
      OrderStatus.PLACED,
      OrderStatus.ACCEPTED,
      OrderStatus.READY,
      OrderStatus.AWAITING_DRIVER,
      OrderStatus.SEARCHING_BIDS,
      OrderStatus.CLAIMED,
      OrderStatus.AT_PICKUP,
      OrderStatus.ON_DELIVERY,
      OrderStatus.ARRIVED,
      OrderStatus.COMPLETED,
    ];
    final index = flow.indexOf(this);
    return index < 0 ? 0 : index;
  }

  bool get isBidding => this == OrderStatus.SEARCHING_BIDS;
}

enum OrderType {
  numpang('Numpang Kampus', 'Numpang'),
  jastip('Jastip Makanan', 'Jastip'),
  paket('Kirim Paket', 'Paket'),
  umkm('Katalog UMKM', 'UMKM');

  const OrderType(this.label, this.shortLabel);
  final String label;
  final String shortLabel;

  static OrderType fromCode(String? code) {
    return OrderType.values.firstWhere(
      (type) => type.name == code,
      orElse: () => OrderType.umkm,
    );
  }
}

enum PaymentMethod {
  COD('COD'),
  QRIS_STATIC('QRIS');

  const PaymentMethod(this.label);
  final String label;

  static PaymentMethod fromCode(String? code) {
    return PaymentMethod.values.firstWhere(
      (method) => method.name == code,
      orElse: () => PaymentMethod.COD,
    );
  }
}

@immutable
class OrderItem {
  const OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.notes = '',
  });

  final String name;
  final int quantity;
  final int price;
  final String notes;

  int get subtotal => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: (map['name'] as String?) ?? 'Item',
      quantity: _asInt(map['quantity'] ?? map['qty']) ?? 1,
      price: _asInt(map['price'] ?? map['unit_price']) ?? 0,
      notes: (map['notes'] as String?) ?? '',
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

@immutable
class OrderTracking {
  const OrderTracking({
    required this.segmentFrom,
    required this.segmentTo,
    this.checkpointAt,
  });

  final String segmentFrom;
  final String segmentTo;
  final DateTime? checkpointAt;

  factory OrderTracking.fromMap(Map<String, dynamic> map) {
    return OrderTracking(
      segmentFrom:
          (map['segmentFrom'] as String?) ??
          (map['segment_from'] as String?) ??
          'gate-utama',
      segmentTo:
          (map['segmentTo'] as String?) ??
          (map['segment_to'] as String?) ??
          'masjid-kampus',
      checkpointAt: _asDate(map['checkpointAt'] ?? map['checkpoint_at']),
    );
  }
}

@immutable
class Order {
  const Order({
    required this.id,
    required this.consumerId,
    required this.type,
    required this.status,
    required this.pickupLandmarkId,
    required this.dropoffLandmarkId,
    required this.totalPrice,
    required this.deliveryFee,
    required this.commissionFee,
    required this.paymentMethod,
    this.finalPrice,
    this.driverId,
    this.merchantId,
    this.pickupName = '',
    this.dropoffName = '',
    this.consumerName = 'Konsumen',
    this.driverName,
    this.merchantName,
    this.items = const [],
    this.tracking,
    this.pin,
    this.createdAt,
    this.etaSeconds = 0,
    this.distanceMeters = 0,
  });

  final String id;
  final String consumerId;
  final String? driverId;
  final String? merchantId;
  final OrderType type;
  final OrderStatus status;
  final String pickupLandmarkId;
  final String dropoffLandmarkId;
  final String pickupName;
  final String dropoffName;
  final String consumerName;
  final String? driverName;
  final String? merchantName;
  final int totalPrice;
  final int deliveryFee;
  final int commissionFee;
  /// Harga final dari bid yang disetujui (`acceptBid`).
  final int? finalPrice;
  final PaymentMethod paymentMethod;
  final List<OrderItem> items;
  final OrderTracking? tracking;
  final String? pin;
  final DateTime? createdAt;
  final int etaSeconds;
  final int distanceMeters;

  int get subtotal => items.fold(0, (total, item) => total + item.subtotal);

  bool get isAwaitingDriver => status == OrderStatus.AWAITING_DRIVER;

  Order copyWith({
    OrderStatus? status,
    String? driverId,
    String? driverName,
    OrderTracking? tracking,
    String? pin,
    int? finalPrice,
    int? etaSeconds,
    int? distanceMeters,
  }) {
    return Order(
      id: id,
      consumerId: consumerId,
      driverId: driverId ?? this.driverId,
      merchantId: merchantId,
      type: type,
      status: status ?? this.status,
      pickupLandmarkId: pickupLandmarkId,
      dropoffLandmarkId: dropoffLandmarkId,
      pickupName: pickupName,
      dropoffName: dropoffName,
      consumerName: consumerName,
      driverName: driverName ?? this.driverName,
      merchantName: merchantName,
      totalPrice: totalPrice,
      deliveryFee: deliveryFee,
      commissionFee: commissionFee,
      finalPrice: finalPrice ?? this.finalPrice,
      paymentMethod: paymentMethod,
      items: items,
      tracking: tracking ?? this.tracking,
      pin: pin ?? this.pin,
      createdAt: createdAt,
      etaSeconds: etaSeconds ?? this.etaSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }

  factory Order.fromMap(String id, Map<String, dynamic> data) {
    final pricing = data['pricing'] is Map<String, dynamic>
        ? data['pricing'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final pickup = data['pickup'];
    final dropoff = data['dropoff'];
    final itemsRaw = data['items'];
    final trackingRaw = data['tracking'];

    return Order(
      id: id,
      consumerId:
          (data['consumer_id'] as String?) ??
          (data['consumerUid'] as String?) ??
          '',
      driverId:
          (data['driver_id'] as String?) ?? (data['driverUid'] as String?),
      merchantId:
          (data['merchant_id'] as String?) ?? (data['merchantId'] as String?),
      type: OrderType.fromCode(
        (data['order_type'] as String?) ?? (data['type'] as String?),
      ),
      status: OrderStatus.fromCode(data['status'] as String?),
      pickupLandmarkId: _landmarkId(pickup, data['pickup_landmark_id']),
      dropoffLandmarkId: _landmarkId(
        dropoff,
        data['destination_landmark_id'] ?? data['dropoff_landmark_id'],
      ),
      pickupName: _landmarkName(pickup, data['pickup_name']),
      dropoffName: _landmarkName(
        dropoff,
        data['destination_name'] ?? data['dropoff_name'],
      ),
      consumerName: (data['consumer_name'] as String?) ?? 'Konsumen',
      driverName: data['driver_name'] as String?,
      merchantName:
          (data['merchant_name'] as String?) ?? (data['store_name'] as String?),
      totalPrice: _asInt(data['total_price'] ?? pricing['total']) ?? 0,
      deliveryFee: _asInt(data['delivery_fee'] ?? pricing['deliveryFee']) ?? 0,
      commissionFee:
          _asInt(data['commission_fee'] ?? pricing['commission']) ?? 0,
      finalPrice: _asInt(data['final_price'] ?? data['finalPrice']),
      paymentMethod: PaymentMethod.fromCode(
        (data['payment_method'] as String?) ??
            (data['payment'] is Map
                ? (data['payment'] as Map)['method'] as String?
                : null),
      ),
      items: itemsRaw is List
          ? itemsRaw
                .whereType<Map>()
                .map(
                  (item) => OrderItem.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      tracking: trackingRaw is Map<String, dynamic>
          ? OrderTracking.fromMap(trackingRaw)
          : null,
      pin: (data['dropoff_pin'] as String?) ?? (data['pin'] as String?),
      createdAt: _asDate(data['created_at'] ?? data['createdAt']),
      etaSeconds: _asInt(data['eta_seconds'] ?? data['etaSeconds']) ?? 0,
      distanceMeters:
          _asInt(data['distance_meters'] ?? data['distanceMeters']) ?? 0,
    );
  }

  static String _landmarkId(Object? value, Object? fallback) {
    if (value is String) return value;
    if (value is Map) {
      final id = value['id'] ?? value['landmarkId'] ?? value['landmark_id'];
      if (id is String) return id;
    }
    return fallback is String ? fallback : '';
  }

  static String _landmarkName(Object? value, Object? fallback) {
    if (value is Map) {
      final name = value['name'] ?? value['label'];
      if (name is String) return name;
    }
    return fallback is String ? fallback : '';
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Order demo untuk mode tanpa Firebase.
  factory Order.demo({
    String id = 'demo-order',
    OrderStatus status = OrderStatus.ON_DELIVERY,
    OrderType type = OrderType.jastip,
    String pickup = 'kantin-pusat-b',
    String dropoff = 'gedung-kuliah-terpadu',
    String pickupName = 'Kantin Pusat B',
    String dropoffName = 'Gedung Kuliah Terpadu',
    int total = 24000,
    String? driverId = 'demo-driver',
    String? pin = '4821',
    DateTime? createdAt,
  }) {
    return Order(
      id: id,
      consumerId: 'demo-consumer',
      driverId: driverId,
      merchantId: 'merchant-kantin',
      type: type,
      status: status,
      pickupLandmarkId: pickup,
      dropoffLandmarkId: dropoff,
      pickupName: pickupName,
      dropoffName: dropoffName,
      consumerName: 'Rani Mahasiswa',
      driverName: driverId == null ? null : 'Dimas Driver',
      merchantName: 'Kantin Bu Siti',
      totalPrice: total,
      deliveryFee: 6000,
      commissionFee: 120,
      paymentMethod: PaymentMethod.COD,
      items: const [
        OrderItem(name: 'Nasi Goreng Spesial', quantity: 1, price: 18000),
      ],
      tracking: OrderTracking(
        segmentFrom: pickup,
        segmentTo: dropoff,
        checkpointAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      pin: pin,
      createdAt:
          createdAt ?? DateTime.now().subtract(const Duration(minutes: 18)),
      etaSeconds: 216,
      distanceMeters: 1200,
    );
  }
}

DateTime? _asDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is Timestamp) return value.toDate();
  return null;
}
