import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../core/gateway/gateway_client.dart';
import 'chat_models.dart';

class ChatRateLimitException implements Exception {
  const ChatRateLimitException();

  @override
  String toString() =>
      'Terlalu banyak pesan. Tunggu sebentar (maks. 20/menit).';
}

class ChatReadOnlyException implements Exception {
  const ChatReadOnlyException();

  @override
  String toString() => 'Ruang chat sudah read-only.';
}

/// Repository chat realtime (docs/tech.md §4).
///
/// ID dokumen pesan = `clientId` (UUID v4) sehingga pengiriman ulang pada
/// koneksi buruk tidak menggandakan pesan.
class ChatRepository {
  ChatRepository({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db,
      _auth = auth;

  final FirebaseFirestore? _db;
  final FirebaseAuth? _auth;
  final List<DateTime> _sent = [];
  final Set<String> _sentIds = {};
  final Map<String, List<ChatMessage>> _demoMessages = {};
  final Map<String, StreamController<List<ChatMessage>>> _demoControllers = {};
  final Uuid _uuid = const Uuid();

  bool get isDemo => _db == null;

  CollectionReference<Map<String, dynamic>> _messages(String orderId) {
    return _db!.collection('chats').doc(orderId).collection('messages');
  }

  Stream<List<ChatMessage>> watch(String orderId, {int limit = 30}) {
    if (isDemo) {
      final controller = _demoControllers.putIfAbsent(
        orderId,
        () => StreamController<List<ChatMessage>>.broadcast(),
      );
      _seedDemo(orderId);
      scheduleMicrotask(() {
        if (!controller.isClosed) {
          controller.add(_demoMessages[orderId] ?? const []);
        }
      });
      return controller.stream;
    }

    return _messages(orderId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ChatMessage.fromMap(doc.id, {
                  ...doc.data(),
                  'pending': doc.metadata.hasPendingWrites,
                }),
              )
              .toList(),
        );
  }

  Future<ChatMessage?> send(
    String orderId, {
    required MessageType type,
    String? text,
    String? imageKey,
    String? clientId,
  }) async {
    _throttle();
    final trimmed = text?.trim();
    if (trimmed != null && trimmed.length > 500) {
      throw ArgumentError('Pesan maksimal 500 karakter.');
    }

    final id = clientId ?? _uuid.v4();
    final now = DateTime.now();
    final message = ChatMessage(
      id: id,
      senderUid: _auth?.currentUser?.uid ?? 'demo-consumer',
      senderName: _auth?.currentUser?.displayName ?? 'Rani Mahasiswa',
      type: type,
      text: trimmed,
      imageKey: imageKey,
      createdAt: now,
      pending: true,
    );

    if (isDemo) {
      _seedDemo(orderId);
      final list = _demoMessages[orderId]!;
      if (_sentIds.add(id)) {
        list.insert(0, message.copyWith(pending: false));
        _demoControllers[orderId]?.add(List.unmodifiable(list));
      }
      return message.copyWith(pending: false);
    }

    final uid = _auth!.currentUser!.uid;
    final data = <String, dynamic>{
      'senderUid': uid,
      'type': type.name,
      'clientId': id,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [uid],
      'flagged': false,
      'expireAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      ),
      'text': ?trimmed,
      'imageKey': ?imageKey,
    };

    try {
      await _messages(orderId).doc(id).set(data);
      _sentIds.add(id);
      return message.copyWith(pending: false);
    } on FirebaseException catch (error) {
      // Percobaan ulang dengan clientId yang sama: rules menolak update,
      // tetapi pesan pertama sudah tersimpan sehingga dianggap berhasil.
      if (error.code == 'permission-denied' && _sentIds.contains(id)) {
        return message.copyWith(pending: false);
      }
      rethrow;
    }
  }

  Future<void> markRead(String orderId, List<String> messageIds) async {
    if (isDemo || messageIds.isEmpty) return;
    final uid = _auth!.currentUser!.uid;
    final batch = _db!.batch();
    for (final id in messageIds.take(20)) {
      batch.update(_messages(orderId).doc(id), {
        'readBy': FieldValue.arrayUnion([uid]),
      });
    }
    try {
      await batch.commit();
    } catch (_) {
      // Mark-read bersifat best-effort; jangan blokir UI chat.
    }
  }

  Future<void> report(String orderId, String messageId, String reason) async {
    final client = GatewayClient(auth: _auth);
    await client.reportMessage(
      orderId: orderId,
      messageId: messageId,
      reason: reason,
    );
  }

  void _throttle() {
    final now = DateTime.now();
    _sent.removeWhere(
      (timestamp) => now.difference(timestamp) > const Duration(minutes: 1),
    );
    if (_sent.length >= 20) throw const ChatRateLimitException();
    _sent.add(now);
  }

  void _seedDemo(String orderId) {
    if (_demoMessages.containsKey(orderId)) return;
    final now = DateTime.now();
    _demoMessages[orderId] = [
      ChatMessage.demo(
        id: 'demo-msg-3',
        senderUid: 'demo-driver',
        senderName: 'Dimas Driver',
        type: MessageType.chip,
        text: 'Saya sudah tiba di titik jemput.',
        createdAt: now.subtract(const Duration(minutes: 2)),
        readBy: const ['demo-consumer'],
      ),
      ChatMessage.demo(
        id: 'demo-msg-2',
        senderUid: 'demo-consumer',
        senderName: 'Rani Mahasiswa',
        type: MessageType.text,
        text:
            'Oke, saya turun sebentar lagi. Tolong tunggu di depan gedung ya.',
        createdAt: now.subtract(const Duration(minutes: 4)),
        readBy: const ['demo-driver', 'demo-consumer'],
      ),
      ChatMessage.demo(
        id: 'demo-msg-1',
        senderUid: 'demo-driver',
        senderName: 'Dimas Driver',
        type: MessageType.system,
        text: 'Driver sudah mengklaim order. Chat aktif sampai order selesai.',
        createdAt: now.subtract(const Duration(minutes: 12)),
      ),
    ];
  }

  void dispose() {
    for (final controller in _demoControllers.values) {
      controller.close();
    }
    _demoControllers.clear();
  }
}
