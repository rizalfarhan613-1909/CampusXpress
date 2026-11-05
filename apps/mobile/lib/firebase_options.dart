import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Konfigurasi Firebase.
///
/// Jalankan `flutterfire configure` untuk mengganti berkas ini dengan opsi
/// proyek nyata, atau isi nilai lewat `--dart-define`:
///
/// ```
/// flutter run \
///   --dart-define=FIREBASE_API_KEY=... \
///   --dart-define=FIREBASE_APP_ID=... \
///   --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
///   --dart-define=FIREBASE_PROJECT_ID=...
/// ```
///
/// Selama nilai masih placeholder, aplikasi berjalan dalam mode demo lokal
/// sehingga seluruh layar dapat diuji di emulator tanpa backend.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const _apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'demo-api-key',
  );
  static const _appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:000000000000:android:demo',
  );
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '000000000000',
  );
  static const _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'campus-express-demo',
  );
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'campus-express-demo.appspot.com',
  );

  static bool get isConfigured =>
      _apiKey != 'demo-api-key' && _projectId != 'campus-express-demo';

  static FirebaseOptions get currentPlatform {
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      storageBucket: _storageBucket,
      iosBundleId: ios ? 'id.ac.uin.campusExpress' : null,
      androidClientId: ios
          ? null
          : '000000000000-demo.apps.googleusercontent.com',
    );
  }
}
