import 'package:flutter/foundation.dart';

enum UserRole {
  consumer('consumer', 'Konsumen'),
  driver('driver', 'Driver'),
  merchant('merchant', 'Merchant'),
  admin('admin', 'Admin');

  const UserRole(this.code, this.label);
  final String code;
  final String label;

  static UserRole fromCode(String? code) {
    return UserRole.values.firstWhere(
      (role) => role.code == code,
      orElse: () => UserRole.consumer,
    );
  }
}

/// Representasi sesi pengguna. Mendukung dokumen `users/{uid}` Fase 2
/// (snake_case) sekaligus skema camelCase pada docs/tech.md.
@immutable
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phone,
    required this.nim,
    required this.roles,
    required this.activeRole,
    required this.driverStatus,
    this.photoUrl = '',
    this.walletBalance = 0,
    this.activeJobs = 0,
    this.suspended = false,
    this.rating = 0,
  });

  final String uid;
  final String email;
  final String displayName;
  final String phone;
  final String nim;
  final List<String> roles;
  final String activeRole;
  final String driverStatus;
  final String photoUrl;
  final int walletBalance;
  final int activeJobs;
  final bool suspended;
  final double rating;

  bool get profileComplete => nim.trim().isNotEmpty && phone.trim().isNotEmpty;

  bool get isConsumer => roles.contains(UserRole.consumer.code);

  bool get isDriver => roles.contains(UserRole.driver.code);

  bool get isDriverApproved => isDriver && driverStatus == 'approved';

  bool get isMerchant => roles.contains(UserRole.merchant.code);

  bool get isAdmin => roles.contains(UserRole.admin.code);

  bool get isLowBalance => walletBalance < 10000;

  UserRole get role => UserRole.fromCode(activeRole);

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'CE';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  AppUser copyWith({
    String? displayName,
    String? phone,
    String? nim,
    List<String>? roles,
    String? activeRole,
    String? driverStatus,
    String? photoUrl,
    int? walletBalance,
    int? activeJobs,
    bool? suspended,
    double? rating,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      nim: nim ?? this.nim,
      roles: roles ?? this.roles,
      activeRole: activeRole ?? this.activeRole,
      driverStatus: driverStatus ?? this.driverStatus,
      photoUrl: photoUrl ?? this.photoUrl,
      walletBalance: walletBalance ?? this.walletBalance,
      activeJobs: activeJobs ?? this.activeJobs,
      suspended: suspended ?? this.suspended,
      rating: rating ?? this.rating,
    );
  }

  factory AppUser.fromMap({
    required String uid,
    required String email,
    required String fallbackName,
    Map<String, dynamic>? map,
    String driverStatus = 'none',
  }) {
    final data = map ?? const <String, dynamic>{};
    final rawRoles = <String>[
      if (data['roles'] is List) ...(data['roles'] as List).whereType<String>(),
      if (data['role'] is String) data['role'] as String,
    ];
    final roles = rawRoles.isEmpty
        ? <String>['consumer']
        : rawRoles.toSet().toList();

    return AppUser(
      uid: uid,
      email: (data['email'] as String?)?.trim().isNotEmpty == true
          ? data['email'] as String
          : email,
      displayName:
          _firstString(data, ['name', 'displayName', 'display_name']) ??
          (fallbackName.trim().isEmpty ? 'Mahasiswa' : fallbackName),
      phone: _firstString(data, ['phone', 'whatsapp', 'wa']) ?? '',
      nim: _firstString(data, ['nim', 'NIM']) ?? '',
      roles: roles,
      activeRole:
          (data['activeRole'] as String?) ??
          (data['active_role'] as String?) ??
          (roles.contains('driver') ? 'driver' : 'consumer'),
      driverStatus: (data['driverStatus'] as String?) ?? driverStatus,
      photoUrl: _firstString(data, ['photoUrl', 'photo_url']) ?? '',
      walletBalance:
          _asInt(data['wallet_balance'] ?? data['walletBalance']) ?? 0,
      activeJobs: _asInt(data['active_jobs'] ?? data['activeJobs']) ?? 0,
      suspended: data['suspended'] == true || data['status'] == 'suspended',
      rating: _asDouble(data['rating']) ?? 0,
    );
  }

  static String? _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
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

  /// Pengguna demo untuk menjalankan aplikasi tanpa Firebase.
  factory AppUser.demo({
    UserRole role = UserRole.consumer,
    bool profileComplete = true,
    bool driverApproved = true,
  }) {
    final roles = <String>{
      'consumer',
      if (role == UserRole.driver) 'driver',
      if (role == UserRole.merchant) 'merchant',
      if (role == UserRole.admin) 'admin',
    }.toList();
    return AppUser(
      uid: 'demo-${role.code}',
      email: 'demo@mhs.uin.ac.id',
      displayName: role == UserRole.driver
          ? 'Dimas Driver'
          : role == UserRole.merchant
          ? 'Bu Siti Kantin'
          : role == UserRole.admin
          ? 'Kak Nadia Admin'
          : 'Rani Mahasiswa',
      phone: profileComplete ? '081234567890' : '',
      nim: profileComplete ? '221234567890' : '',
      roles: roles,
      activeRole: role.code,
      driverStatus: driverApproved ? 'approved' : 'pending_review',
      walletBalance: role == UserRole.driver ? 32500 : 0,
      rating: 4.8,
    );
  }
}
