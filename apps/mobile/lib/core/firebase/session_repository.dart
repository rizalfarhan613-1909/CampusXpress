import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

/// Sesi Firebase: menggabungkan `authStateChanges()` dengan dokumen
/// `users/{uid}` dan `driverProfiles/{uid}` secara realtime.
class SessionRepository {
  SessionRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<AppUser?> watchSession() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream<AppUser?>.value(null);
      return _watchUser(user);
    });
  }

  Stream<AppUser?> _watchUser(User user) {
    late StreamController<AppUser?> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? userSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? driverSub;
    Map<String, dynamic>? userData;
    var driverStatus = 'none';
    var driverSubscribed = false;

    void emit() {
      if (controller.isClosed) return;
      controller.add(
        AppUser.fromMap(
          uid: user.uid,
          email: user.email ?? '',
          fallbackName: user.displayName ?? '',
          map: userData,
          driverStatus: driverStatus,
        ),
      );
    }

    void subscribeDriver(bool shouldSubscribe) {
      if (shouldSubscribe && !driverSubscribed) {
        driverSubscribed = true;
        driverSub = _db
            .collection('driverProfiles')
            .doc(user.uid)
            .snapshots()
            .listen(
              (snapshot) {
                driverStatus =
                    (snapshot.data()?['status'] as String?) ?? 'pending_docs';
                emit();
              },
              onError: (Object _) {
                driverStatus = 'none';
                emit();
              },
            );
      } else if (!shouldSubscribe && driverSubscribed) {
        driverSubscribed = false;
        driverSub?.cancel();
        driverSub = null;
        driverStatus = 'none';
      }
    }

    controller = StreamController<AppUser?>(
      onListen: () {
        emit();
        userSub = _db
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen(
              (snapshot) {
                userData = snapshot.data();
                final roles = <String>[
                  if (userData?['roles'] is List)
                    ...(userData!['roles'] as List).whereType<String>(),
                  if (userData?['role'] is String) userData!['role'] as String,
                ];
                subscribeDriver(roles.contains('driver'));
                emit();
              },
              onError: (Object _) {
                emit();
              },
            );
      },
      onCancel: () async {
        await userSub?.cancel();
        await driverSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> saveFcmToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setActiveRole(String role) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update({
      'activeRole': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
