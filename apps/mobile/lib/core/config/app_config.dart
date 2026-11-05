import 'package:flutter/material.dart';

import '../../firebase_options.dart';

/// Konfigurasi aplikasi. Nilai operasional (tarif, batas, dsb.) pada produksi
/// dibaca dari `config/app`; nilai di bawah adalah fallback sesuai Rules.md §1.
class AppConfig {
  AppConfig._();

  /// Endpoint publik Gateway Cloudflare Workers.
  ///
  /// KEAMANAN: berkas ini hanya boleh memuat konfigurasi PUBLIK (endpoint,
  /// tarif, batas, pola validasi). Kunci privat — R2_SECRET_ACCESS_KEY,
  /// FIREBASE_SERVICE_ACCOUNT_JSON, URL_SIGNING_KEY — tidak boleh ada di klien
  /// Flutter; semuanya disimpan sebagai secret Worker (`wrangler secret put`)
  /// atau Firebase Admin Functions. Audit: `npm run security:audit`.
  static const gatewayBaseUrl = String.fromEnvironment(
    'GATEWAY_BASE_URL',
    defaultValue: 'https://gateway.campus-express.example',
  );

  /// Tile OSM publik (tanpa kunci API).
  static const osmTileUrl = String.fromEnvironment(
    'OSM_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  static const avgSpeedKmh = 20.0;
  static const driverMinBalance = 5000;
  static const driverLowBalanceWarn = 10000;
  static const topupMin = 10000;
  static const topupMax = 500000;
  static const codMax = 200000;
  static const orderMax = 500000;
  static const chatRatePerMin = 20;
  static const maxActiveJobsPerDriver = 2;
  static const maxProductsPerMerchant = 150;

  static const nimPattern = r'^[0-9]{10,12}$';
  static const phonePattern = r'^(\+62|62|0)8[1-9][0-9]{7,11}$';
  static const platePattern = r'^[A-Z]{1,2}\s?[0-9]{1,4}\s?[A-Z]{0,3}$';

  static const campusCenter = LatLng(3.5590, 98.6600);

  /// Mode demo aktif saat konfigurasi Firebase belum diisi. Aplikasi tetap
  /// dapat dijalankan di emulator tanpa proyek Firebase.
  static bool get demoMode => !DefaultFirebaseOptions.isConfigured;
}

/// Koordinat sederhana agar lapisan peta tidak bergantung pada paket peta.
@immutable
class LatLng {
  const LatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  LatLng copyWith({double? latitude, double? longitude}) =>
      LatLng(latitude ?? this.latitude, longitude ?? this.longitude);

  @override
  bool operator ==(Object other) =>
      other is LatLng &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}
