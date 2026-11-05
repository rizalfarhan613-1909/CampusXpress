import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/firebase/firestore_paths.dart';
import '../../core/models/app_user.dart';
import '../../core/models/order.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/bento_card.dart';
import 'chat_models.dart';
import 'chat_repository.dart';

final _chatOrderProvider = StreamProvider.family<Order?, String>((ref, id) {
  if (!FirebaseBootstrap.ready) return Stream<Order?>.value(null);
  return FirebaseFirestore.instance
      .collection(FirestorePaths.orders)
      .doc(id)
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? Order.fromMap(snapshot.id, snapshot.data()!)
            : null,
      );
});

/// Screen 16 — In-App Live Chat (M12).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final Stream<List<ChatMessage>> _messages;
  final _marked = <String>{};
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _messages = ref.read(chatRepositoryProvider).watch(widget.orderId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'demo-consumer';

  @override
  Widget build(BuildContext context) {
    final demo = AppConfig.demoMode;
    final user = ref.watch(authStateProvider).value;
    final order = demo
        ? _demoOrder()
        : ref.watch(_chatOrderProvider(widget.orderId)).value;
    final readOnly = order?.status.isFinished ?? false;
    final chips = user?.isDriver == true && user?.role == UserRole.driver
        ? driverQuickChips
        : consumerQuickChips;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat Order', style: TextStyle(fontSize: 16)),
            Text(
              '#${widget.orderId} · ${order?.status.label ?? 'Aktif'}',
              style: const TextStyle(fontSize: 10, color: Ce.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _confirmWhatsApp,
            icon: const Icon(Icons.phone_in_talk_outlined),
            tooltip: 'WhatsApp darurat',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'support') context.go('/support');
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'support', child: Text('Buka Help Desk')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (readOnly)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: InfoBanner(
                  message:
                      'Order sudah selesai. Ruang chat menjadi read-only, '
                      'riwayat tetap dapat dibaca.',
                  icon: Icons.lock_outline_rounded,
                  color: Ce.warning,
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: InfoBanner(
                  message: _error!,
                  icon: Icons.error_outline_rounded,
                  color: Ce.danger,
                ),
              ),
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _messages,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ErrorState(
                      message: 'Chat gagal dimuat. Periksa koneksi.',
                      onRetry: () => setState(() {}),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: SkeletonList(count: 5, height: 54),
                    );
                  }
                  final messages = snapshot.data!;
                  _markRead(messages);
                  if (messages.isEmpty) {
                    return const EmptyState(
                      title: 'Belum ada pesan',
                      message:
                          'Mulai dengan sapaan atau gunakan Quick Chips di bawah.',
                      icon: Icons.chat_bubble_outline_rounded,
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _MessageBubble(
                        message: message,
                        mine: message.isMine(_uid),
                        onLongPress: () => _report(message),
                      );
                    },
                  );
                },
              ),
            ),
            if (!readOnly) ...[
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: chips.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final chip = chips[index];
                    return ActionChip(
                      label: Text(chip, style: const TextStyle(fontSize: 10.5)),
                      onPressed: _sending ? null : () => _sendChip(chip),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: const BoxDecoration(
                  color: Ce.surface,
                  border: Border(top: BorderSide(color: Ce.emerald900)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _sending ? null : _sendImage,
                      icon: const Icon(Icons.image_outlined),
                      tooltip: 'Kirim gambar',
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLength: 500,
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan…',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      onPressed: _sending ? null : _sendText,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Ce.text,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 19),
                      tooltip: 'Kirim',
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Maks. 20 pesan/menit · jangan bagikan PIN atau data sensitif',
                  style: TextStyle(fontSize: 8.5, color: Ce.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Order? _demoOrder() {
    for (final order in ref.watch(demoOrdersProvider)) {
      if (order.id == widget.orderId) return order;
    }
    return null;
  }

  void _markRead(List<ChatMessage> messages) {
    final unread = messages
        .where(
          (message) =>
              !message.isMine(_uid) &&
              !message.readBy.contains(_uid) &&
              !_marked.contains(message.id),
        )
        .map((message) => message.id)
        .take(20)
        .toList();
    if (unread.isEmpty) return;
    _marked.addAll(unread);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRepositoryProvider).markRead(widget.orderId, unread);
    });
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await _send(type: MessageType.text, text: text);
    if (mounted) _controller.clear();
  }

  Future<void> _sendChip(String text) async {
    await _send(type: MessageType.chip, text: text);
  }

  Future<void> _sendImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim gambar'),
        content: const Text(
          'Gambar akan dikompres ke WebP ≤ 80 KB sebelum diunggah. '
          'Jangan kirim foto berisi PIN atau data pribadi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Pilih & kirim'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _send(
      type: MessageType.image,
      text: 'Foto bukti (WebP 68 KB)',
      imageKey: 'demo/chat-${DateTime.now().millisecondsSinceEpoch}.webp',
    );
  }

  Future<void> _send({
    required MessageType type,
    String? text,
    String? imageKey,
  }) async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(chatRepositoryProvider)
          .send(
            widget.orderId,
            type: type,
            text: text,
            imageKey: imageKey,
            clientId: const Uuid().v4(),
          );
    } on ChatRateLimitException catch (error) {
      setState(() => _error = error.toString());
    } on ChatReadOnlyException catch (error) {
      setState(() => _error = error.toString());
    } on ArgumentError catch (error) {
      setState(
        () => _error = error.message?.toString() ?? 'Pesan tidak valid.',
      );
    } catch (_) {
      setState(() => _error = 'Pesan gagal dikirim. Coba lagi.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _report(ChatMessage message) async {
    if (message.isMine(_uid) || message.type == MessageType.system) return;
    final reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Laporkan pesan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Ce.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.text ?? 'Pesan gambar',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Ce.textMuted),
            ),
            const SizedBox(height: 10),
            for (final reason in const [
              'Spam atau promosi',
              'Kata kasar / pelecehan',
              'Meminta PIN atau data pribadi',
              'Penipuan',
            ])
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.flag_outlined,
                  size: 18,
                  color: Ce.danger,
                ),
                title: Text(reason),
                onTap: () => Navigator.of(context).pop(reason),
              ),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;
    try {
      await ref
          .read(chatRepositoryProvider)
          .report(widget.orderId, message.id, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan dikirim. Admin akan meninjau pesan.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim laporan.')),
        );
      }
    }
  }

  Future<void> _confirmWhatsApp() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bagikan nomor WhatsApp?'),
        content: const Text(
          'Pintasan WhatsApp hanya untuk darurat: chat in-app tidak direspons '
          '≥ 3 menit atau fitur chat error. Nomor akan disalin ke clipboard '
          'dan hanya dibagikan ke lawan transaksi pada order aktif.\n\n'
          'Nomor: 0812-****-7890',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, salin nomor'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await Clipboard.setData(const ClipboardData(text: '+6281234567890'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor darurat disalin. Gunakan hanya jika mendesak.'),
        ),
      );
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.onLongPress,
  });

  final ChatMessage message;
  final bool mine;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        child: Text(
          message.text ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9.5,
            color: Ce.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: mine ? Ce.emerald600 : Ce.surfaceHigh,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(mine ? 14 : 4),
              bottomRight: Radius.circular(mine ? 4 : 14),
            ),
            border: Border.all(color: mine ? Ce.emerald500 : Ce.emerald900),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mine && message.senderName.isNotEmpty)
                Text(
                  message.senderName,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Ce.emerald500,
                  ),
                ),
              if (message.type == MessageType.image)
                Row(
                  children: [
                    const Icon(Icons.image_rounded, size: 16, color: Ce.text),
                    const SizedBox(width: 5),
                    Text(
                      message.text ?? 'Gambar',
                      style: const TextStyle(fontSize: 11, color: Ce.text),
                    ),
                  ],
                )
              else
                Text(
                  message.text ?? '',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Ce.text,
                    height: 1.35,
                  ),
                ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.flagged)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.flag_rounded,
                        size: 10,
                        color: Ce.warning,
                      ),
                    ),
                  Text(
                    formatTime(message.createdAt),
                    style: const TextStyle(fontSize: 8, color: Ce.textMuted),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 3),
                    Icon(
                      message.pending
                          ? Icons.schedule_rounded
                          : Icons.done_all_rounded,
                      size: 11,
                      color: message.pending ? Ce.textMuted : Ce.text,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
