import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum MessageType { text, chip, image, system }

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderUid,
    required this.type,
    this.senderName = '',
    this.text,
    this.imageKey,
    this.createdAt,
    this.readBy = const [],
    this.flagged = false,
    this.pending = false,
  });

  final String id;
  final String senderUid;
  final String senderName;
  final MessageType type;
  final String? text;
  final String? imageKey;
  final DateTime? createdAt;
  final List<String> readBy;
  final bool flagged;
  final bool pending;

  bool isMine(String uid) => senderUid == uid;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    final rawCreatedAt = data['createdAt'] ?? data['created_at'];
    return ChatMessage(
      id: id,
      senderUid:
          (data['senderUid'] as String?) ??
          (data['sender_id'] as String?) ??
          '',
      senderName: (data['senderName'] as String?) ?? '',
      type: MessageType.values.firstWhere(
        (type) => type.name == (data['type'] as String?),
        orElse: () => MessageType.text,
      ),
      text: (data['text'] as String?) ?? (data['body'] as String?),
      imageKey: (data['imageKey'] as String?) ?? (data['image_url'] as String?),
      createdAt: rawCreatedAt is Timestamp
          ? rawCreatedAt.toDate()
          : rawCreatedAt is DateTime
          ? rawCreatedAt
          : null,
      readBy: data['readBy'] is List
          ? (data['readBy'] as List).whereType<String>().toList()
          : const [],
      flagged: data['flagged'] == true,
      pending: data['pending'] == true,
    );
  }

  ChatMessage copyWith({
    DateTime? createdAt,
    List<String>? readBy,
    bool? pending,
  }) {
    return ChatMessage(
      id: id,
      senderUid: senderUid,
      senderName: senderName,
      type: type,
      text: text,
      imageKey: imageKey,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
      flagged: flagged,
      pending: pending ?? this.pending,
    );
  }

  factory ChatMessage.demo({
    required String id,
    required String senderUid,
    required MessageType type,
    required String text,
    required DateTime createdAt,
    String senderName = '',
    List<String> readBy = const [],
  }) {
    return ChatMessage(
      id: id,
      senderUid: senderUid,
      senderName: senderName,
      type: type,
      text: text,
      createdAt: createdAt,
      readBy: readBy,
    );
  }
}

const consumerQuickChips = [
  'Saya sudah di titik',
  'Tolong tunggu 2 menit',
  'Pesanan sudah benar?',
];

const driverQuickChips = [
  'Saya sudah tiba',
  'Sedang antre di kedai',
  'Titik ini sulit, boleh pindah?',
];
