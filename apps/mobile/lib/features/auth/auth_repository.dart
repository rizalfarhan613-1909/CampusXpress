import 'package:firebase_auth/firebase_auth.dart';

import '../../core/gateway/gateway_client.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Autentikasi Google SSO khusus domain kampus (PRD M01).
class AuthRepository {
  AuthRepository(this._auth, this._gateway);

  final FirebaseAuth _auth;
  final GatewayClient _gateway;

  static const campusDomain = '@mhs.uin.ac.id';

  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'hd': 'mhs.uin.ac.id'});
    final credential = await _auth.signInWithProvider(provider);
    final user = credential.user;
    if (user == null) {
      throw const AuthException('Login dibatalkan. Silakan coba lagi.');
    }
    final email = (user.email ?? '').toLowerCase();
    if (!email.endsWith(campusDomain) || user.emailVerified == false) {
      await _auth.signOut();
      throw const AuthException('Gunakan akun @mhs.uin.ac.id');
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> saveProfile({
    required String displayName,
    required String nim,
    required String phone,
    String? referralCode,
  }) async {
    try {
      await _gateway.bootstrapProfile(
        displayName: displayName,
        nim: nim,
        phone: phone,
        referralCode: referralCode,
      );
    } on GatewayException catch (error) {
      if (error.statusCode == 409 || error.code == 'NIM_TAKEN') {
        throw const AuthException('NIM sudah terdaftar');
      }
      if (error.statusCode == 401 || error.statusCode == 403) {
        throw const AuthException(
          'Sesi tidak valid. Silakan masuk ulang dengan akun kampus.',
        );
      }
      throw AuthException(
        error.message.isEmpty
            ? 'Gagal menyimpan profil. Coba lagi.'
            : error.message,
      );
    }
  }
}
