import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_repository.dart';
import '../../features/catalog/catalog_data.dart';
import '../../features/chat/chat_repository.dart';
import '../firebase/firebase_bootstrap.dart';
import '../firebase/session_repository.dart';
import '../gateway/gateway_client.dart';
import '../models/app_user.dart';
import '../models/bid.dart';
import '../models/merchant.dart';
import '../models/order.dart';
import '../models/wallet.dart';

final firebaseReadyProvider = Provider<bool>((ref) => FirebaseBootstrap.ready);

/// Sesi demo lokal saat Firebase belum dikonfigurasi.
class DemoSessionNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  void signIn(AppUser user) => state = user;

  void update(AppUser Function(AppUser current) updater) {
    final current = state;
    if (current != null) state = updater(current);
  }

  void signOut() => state = null;
}

final demoSessionProvider = NotifierProvider<DemoSessionNotifier, AppUser?>(
  DemoSessionNotifier.new,
);

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  if (!FirebaseBootstrap.ready) {
    throw StateError('SessionRepository hanya tersedia saat Firebase aktif.');
  }
  return SessionRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

/// Akses Firestore aman: hanya dipakai saat Firebase siap.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  if (!FirebaseBootstrap.ready) {
    throw StateError('Firestore hanya tersedia saat Firebase aktif.');
  }
  return FirebaseFirestore.instance;
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  if (!FirebaseBootstrap.ready) {
    return Stream<AppUser?>.value(ref.watch(demoSessionProvider));
  }
  return ref.watch(sessionRepositoryProvider).watchSession();
});

class ActiveRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() => UserRole.consumer;

  void setRole(UserRole role) => state = role;
}

final activeRoleProvider = NotifierProvider<ActiveRoleNotifier, UserRole>(
  ActiveRoleNotifier.new,
);

final gatewayClientProvider = Provider<GatewayClient>((ref) {
  return GatewayClient(
    auth: FirebaseBootstrap.ready ? FirebaseAuth.instance : null,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    ref.watch(gatewayClientProvider),
  );
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (!FirebaseBootstrap.ready) return ChatRepository();
  return ChatRepository(
    db: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

// ---------------------------------------------------------------------------
// State demo lokal. Semua provider di bawah ini dipakai saat mode demo aktif;
// pada mode Firebase, layar membaca koleksi Firestore secara realtime.
// ---------------------------------------------------------------------------

class DemoOrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() {
    return [
      Order.demo(
        id: 'order-bidding',
        status: OrderStatus.SEARCHING_BIDS,
        type: OrderType.numpang,
        driverId: null,
        pickup: 'fakultas-saintek',
        pickupName: 'Gedung FST UINSU Tuntungan',
        dropoff: 'kost-gang-melati',
        dropoffName: 'Area Kos Jl. Lapangan Golf',
        total: 7000,
        pin: null,
      ),
      Order.demo(
        id: 'order-aktif',
        status: OrderStatus.ON_DELIVERY,
        type: OrderType.jastip,
        pickup: 'kantin-pusat-b',
        pickupName: 'Kantin Pusat B',
        dropoff: 'gedung-kuliah-terpadu',
        dropoffName: 'Gedung Kuliah Terpadu',
        pin: '4821',
      ),
      Order.demo(
        id: 'radar-1',
        status: OrderStatus.AWAITING_DRIVER,
        type: OrderType.jastip,
        driverId: null,
        pickup: 'kantin-pusat-b',
        pickupName: 'Kantin Pusat B',
        dropoff: 'fakultas-saintek',
        dropoffName: 'Fakultas Saintek',
        total: 27000,
        pin: null,
      ),
      Order.demo(
        id: 'radar-2',
        status: OrderStatus.AWAITING_DRIVER,
        type: OrderType.paket,
        driverId: null,
        pickup: 'gate-utama',
        pickupName: 'Gate Utama',
        dropoff: 'perpustakaan-pusat',
        dropoffName: 'Perpustakaan Pusat',
        total: 16000,
        pin: null,
      ),
      Order.demo(
        id: 'radar-3',
        status: OrderStatus.AWAITING_DRIVER,
        type: OrderType.numpang,
        driverId: null,
        pickup: 'masjid-kampus',
        pickupName: 'Masjid Kampus',
        dropoff: 'kost-gang-melati',
        dropoffName: 'Area Kost Gang Melati',
        total: 6000,
        pin: null,
      ),
      Order.demo(
        id: 'merchant-order-1',
        status: OrderStatus.PLACED,
        type: OrderType.umkm,
        pickup: 'kantin-pusat-b',
        pickupName: 'Kantin Pusat B',
        dropoff: 'fakultas-saintek',
        dropoffName: 'Fakultas Saintek',
        total: 32000,
        driverId: null,
        pin: null,
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      Order.demo(
        id: 'merchant-order-2',
        status: OrderStatus.ACCEPTED,
        type: OrderType.jastip,
        pickup: 'kantin-pusat-b',
        pickupName: 'Kantin Pusat B',
        dropoff: 'perpustakaan-pusat',
        dropoffName: 'Perpustakaan Pusat',
        total: 19000,
        driverId: null,
        pin: null,
        createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
      ),
      Order.demo(
        id: 'order-selesai',
        status: OrderStatus.COMPLETED,
        type: OrderType.umkm,
        driverId: 'demo-driver',
        pickup: 'kantin-pusat-b',
        pickupName: 'Kantin Pusat B',
        dropoff: 'gedung-kuliah-terpadu',
        dropoffName: 'Gedung Kuliah Terpadu',
        total: 24000,
        pin: '1234',
      ),
    ];
  }

  Order? byId(String id) {
    for (final order in state) {
      if (order.id == id) return order;
    }
    return null;
  }

  Order? get activeOrder {
    for (final order in state) {
      if (order.status.isActive) return order;
    }
    return null;
  }

  void claim(String orderId, String driverId) {
    state = [
      for (final order in state)
        if (order.id == orderId)
          order.copyWith(
            status: OrderStatus.CLAIMED,
            driverId: driverId,
            driverName: 'Dimas Driver',
          )
        else
          order,
    ];
  }

  void setStatus(String orderId, OrderStatus status) {
    state = [
      for (final order in state)
        if (order.id == orderId) order.copyWith(status: status) else order,
    ];
  }

  void advanceCheckpoint(String orderId) {
    final order = byId(orderId);
    if (order == null) return;
    final next = switch (order.status) {
      OrderStatus.CLAIMED => OrderStatus.AT_PICKUP,
      OrderStatus.AT_PICKUP => OrderStatus.ON_DELIVERY,
      OrderStatus.ON_DELIVERY => OrderStatus.ARRIVED,
      _ => order.status,
    };
    setStatus(orderId, next);
  }

  void add(Order order) => state = [order, ...state];
}

final demoOrdersProvider = NotifierProvider<DemoOrdersNotifier, List<Order>>(
  DemoOrdersNotifier.new,
);

final demoActiveOrderProvider = Provider<Order?>((ref) {
  for (final order in ref.watch(demoOrdersProvider)) {
    if (order.status.isActive) return order;
  }
  return null;
});

/// Penawaran demo untuk Reverse Auction (mode tanpa Firebase).
class DemoBidsNotifier extends Notifier<List<Bid>> {
  @override
  List<Bid> build() {
    return [
      Bid.demo(
        bidId: 'bid_dimas',
        driverName: 'Dimas Pratama',
        offeredPrice: 7000,
        estimatedArrivalMinutes: 6,
        rating: 4.9,
        platNumber: 'BK 1234 AB',
        vehicleModel: 'Honda Beat',
      ),
      Bid.demo(
        bidId: 'bid_sari',
        driverName: 'Sari Lubis',
        offeredPrice: 8500,
        estimatedArrivalMinutes: 4,
        rating: 4.8,
        platNumber: 'BK 5621 QA',
        vehicleModel: 'Yamaha Mio',
      ),
      Bid.demo(
        bidId: 'bid_fajar',
        driverName: 'Fajar Nasution',
        offeredPrice: 6500,
        estimatedArrivalMinutes: 11,
        rating: 4.7,
        platNumber: 'BK 8820 CD',
        vehicleModel: 'Suzuki Nex',
      ),
    ];
  }

  /// Konsumen menerima satu bid: bid terpilih ACCEPTED, sisanya REJECTED.
  void accept(String bidId) {
    state = [
      for (final bid in state)
        bid.bidId == bidId
            ? bid.copyWith(status: BidStatus.ACCEPTED)
            : (bid.status == BidStatus.PENDING
                  ? bid.copyWith(status: BidStatus.REJECTED)
                  : bid),
    ];
  }

  void addBid(Bid bid) => state = [bid, ...state];
}

final demoBidsProvider = NotifierProvider<DemoBidsNotifier, List<Bid>>(
  DemoBidsNotifier.new,
);

class DemoWalletNotifier extends Notifier<int> {
  @override
  int build() => 32500;

  void topUp(int amount) => state += amount;

  void deduct(int amount) => state = (state - amount).clamp(0, 1 << 31).toInt();
}

final demoWalletBalanceProvider = NotifierProvider<DemoWalletNotifier, int>(
  DemoWalletNotifier.new,
);

final demoWalletTxProvider = Provider<List<WalletTx>>((ref) {
  final now = DateTime.now();
  return [
    WalletTx.demo(
      id: 'tx-1',
      amount: -120,
      type: WalletTxType.COMMISSION_DEDUCTION,
      description: 'Komisi 0,5% order #CE-1042',
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    WalletTx.demo(
      id: 'tx-2',
      amount: 20000,
      type: WalletTxType.topup,
      description: 'Top-up QRIS disetujui admin',
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    WalletTx.demo(
      id: 'tx-3',
      amount: -150,
      type: WalletTxType.COMMISSION_DEDUCTION,
      description: 'Komisi 0,5% order #CE-1031',
      createdAt: now.subtract(const Duration(days: 1, hours: 3)),
    ),
    WalletTx.demo(
      id: 'tx-4',
      amount: 50000,
      type: WalletTxType.topup,
      description: 'Top-up QRIS disetujui admin',
      createdAt: now.subtract(const Duration(days: 4)),
    ),
  ];
});

class DemoMerchantOpenNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
  void setOpen(bool value) => state = value;
}

final demoMerchantOpenProvider =
    NotifierProvider<DemoMerchantOpenNotifier, bool>(
      DemoMerchantOpenNotifier.new,
    );

class DemoMenuNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() => CatalogData.byId('merchant-kantin').products;

  void save(Product product) {
    final exists = state.any((item) => item.id == product.id);
    state = exists
        ? [for (final item in state) item.id == product.id ? product : item]
        : [...state, product];
  }

  void toggleAvailability(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          Product(
            id: item.id,
            merchantId: item.merchantId,
            name: item.name,
            price: item.price,
            category: item.category,
            description: item.description,
            isAvailable: !item.isAvailable,
            optionGroups: item.optionGroups,
            imageSeed: item.imageSeed,
          )
        else
          item,
    ];
  }
}

final demoMenuProvider = NotifierProvider<DemoMenuNotifier, List<Product>>(
  DemoMenuNotifier.new,
);
