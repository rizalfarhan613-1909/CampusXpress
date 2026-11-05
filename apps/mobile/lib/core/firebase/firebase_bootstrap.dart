import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Inisialisasi Firebase + App Check. Kegagalan konfigurasi tidak
/// menghentikan aplikasi: UI jatuh ke mode demo lokal.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _ready = false;
  static Object? _error;

  static bool get ready => _ready;
  static Object? get error => _error;

  static Future<void> initialize() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      _error = 'Firebase belum dikonfigurasi (mode demo).';
      return;
    }
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      await activateAppCheck();
      _ready = true;
    } catch (error, stack) {
      _error = error;
      debugPrint('Firebase init gagal: $error');
      debugPrintStack(stackTrace: stack);
    }
  }

  static Future<void> activateAppCheck() async {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kReleaseMode
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider(),
      providerApple: kReleaseMode
          ? const AppleAppAttestProvider()
          : const AppleDebugProvider(),
    );
  }
}
