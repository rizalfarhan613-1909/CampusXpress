import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class GatewayException implements Exception {
  GatewayException(this.statusCode, this.code, [this.message = '']);

  final int statusCode;
  final String code;
  final String message;

  @override
  String toString() => 'GatewayException($statusCode, $code): $message';
}

class AuthRequiredException implements Exception {
  const AuthRequiredException();
}

/// Klien HTTP Gateway (docs/tech.md §3.5).
///
/// Setiap permintaan membawa ID token Firebase dan header
/// `X-Firebase-AppCheck` sesuai PRD keamanan.
class GatewayClient {
  GatewayClient({FirebaseAuth? auth, String? baseUrl})
    : _auth = auth,
      _baseUrl = baseUrl ?? AppConfig.gatewayBaseUrl;

  final FirebaseAuth? _auth;
  final String _baseUrl;

  Future<Map<String, String>> _headers({bool json = true}) async {
    final user = _auth?.currentUser;
    if (user == null) throw const AuthRequiredException();
    final token = await user.getIdToken();
    String appCheck = '';
    try {
      appCheck = await FirebaseAppCheck.instance.getToken() ?? '';
    } catch (_) {
      // App Check dapat gagal pada debug; token kosong tetap dikirim agar
      // Gateway dapat memutuskan kebijakan.
    }
    return {
      'Authorization': 'Bearer $token',
      'X-Firebase-AppCheck': appCheck,
      if (json) 'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http
        .get(Uri.parse('$_baseUrl$path'), headers: await _headers(json: false))
        .timeout(const Duration(seconds: 20));
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: await _headers(),
          body: jsonEncode(body ?? const <String, dynamic>{}),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(response);
  }

  Future<String> uploadWebp(Uint8List bytes, {String kind = 'chat'}) async {
    final response = await http
        .put(
          Uri.parse('$_baseUrl/upload/$kind'),
          headers: await _headers(json: false)
            ..['Content-Type'] = 'image/webp',
          body: bytes,
        )
        .timeout(const Duration(seconds: 30));
    final json = _decode(response);
    return (json['key'] as String?) ?? '';
  }

  Future<Map<String, dynamic>> claimOrder(String orderId) =>
      post('/orders/$orderId/claim');

  Future<Map<String, dynamic>> completeOrder(String orderId, String inputPin) =>
      post('/orders/$orderId/complete', {'inputPin': inputPin});

  Future<Map<String, dynamic>> cancelOrder(String orderId) =>
      post('/orders/$orderId/cancel');

  /// Fase 5 — driver mengirim penawaran harga (Reverse Auction).
  Future<Map<String, dynamic>> submitBid({
    required String orderId,
    required int offeredPrice,
    required int estimatedArrivalMinutes,
    String? platNumber,
    String? vehicleModel,
    String? driverName,
    double? rating,
  }) => post('/orders/$orderId/bids', {
    'offeredPrice': offeredPrice,
    'estimatedArrivalMinutes': estimatedArrivalMinutes,
    'platNumber': ?platNumber,
    'vehicleModel': ?vehicleModel,
    'driverName': ?driverName,
    'rating': ?rating,
  });

  /// Fase 5 — konsumen menerima satu penawaran secara atomik.
  Future<Map<String, dynamic>> acceptBid({
    required String orderId,
    required String bidId,
  }) => post('/orders/$orderId/bids/$bidId/accept');

  Future<Map<String, dynamic>> topUp({
    required int amount,
    required String proofKey,
    String? idempotencyKey,
  }) => post('/wallet/topup', {
    'amount': amount,
    'proofKey': proofKey,
    'idempotencyKey': ?idempotencyKey,
  });

  Future<Map<String, dynamic>> bootstrapProfile({
    required String displayName,
    required String nim,
    required String phone,
    String? referralCode,
  }) => post('/me/bootstrap', {
    'displayName': displayName,
    'nim': nim,
    'phone': phone,
    'referralCode': ?referralCode,
  });

  Future<Map<String, dynamic>> reportMessage({
    required String orderId,
    required String messageId,
    required String reason,
  }) => post('/chat/report', {
    'orderId': orderId,
    'messageId': messageId,
    'reason': reason,
  });

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.trim();
    Map<String, dynamic> json;
    try {
      json = body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      json = <String, dynamic>{'raw': body};
    }
    if (response.statusCode >= 400) {
      throw GatewayException(
        response.statusCode,
        (json['code'] as String?) ?? 'ERROR',
        (json['message'] as String?) ?? 'Permintaan gagal.',
      );
    }
    return json;
  }
}
