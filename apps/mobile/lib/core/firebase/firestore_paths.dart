/// Nama koleksi Firestore terpusat agar mudah diaudit terhadap
/// backend/firebase/firestore.rules.
class FirestorePaths {
  FirestorePaths._();

  static const users = 'users';
  static const driverProfiles = 'driverProfiles';
  static const wallets = 'wallets';
  static const walletLedger = 'wallet_ledger';
  static const walletTx = 'walletTx';
  static const merchants = 'merchants';
  static const merchantMenus = 'merchantMenus';
  static const landmarks = 'landmarks';
  static const zones = 'zones';
  static const fareMatrix = 'fare_matrix';
  static const orders = 'orders';
  static const bids = 'bids';
  static const chats = 'chats';
  static const messages = 'messages';
  static const reviews = 'reviews';
  static const disputes = 'disputes';
  static const config = 'config';
}
