import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/firebase/firestore_paths.dart';
import '../../core/models/order.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/bento_card.dart';

/// Screen 19 — Post-Order Rating & Review (M16).
class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _rating = 0;
  final Set<String> _tags = {};
  final _comment = TextEditingController();
  bool _submitted = false;
  bool _sending = false;

  static const _quickTags = [
    'Tepat waktu',
    'Ramah',
    'Pesanan sesuai',
    'Kemasan rapi',
    'Komunikasi baik',
  ];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Order? order;
    if (AppConfig.demoMode) {
      for (final item in ref.watch(demoOrdersProvider)) {
        if (item.id == widget.orderId) order = item;
      }
    }
    if (_submitted) return _buildSuccess(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beri Rating'),
        actions: [
          TextButton(
            onPressed: () => context.go('/orders'),
            child: const Text('Lewati'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
          children: [
            BentoCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.emoji_emotions_rounded,
                    size: 38,
                    color: Ce.emerald500,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bagaimana pengalamanmu?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Ce.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order == null
                        ? 'Order #${widget.orderId}'
                        : '${order.pickupName} → ${order.dropoffName}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Ce.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                          onPressed: () => setState(() => _rating = i),
                          icon: Icon(
                            i <= _rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 38,
                            color: i <= _rating ? Ce.warning : Ce.textMuted,
                          ),
                          tooltip: '$i bintang',
                        ),
                    ],
                  ),
                  Text(
                    switch (_rating) {
                      0 => 'Pilih bintang',
                      1 => 'Sangat buruk',
                      2 => 'Buruk',
                      3 => 'Cukup',
                      4 => 'Baik',
                      _ => 'Sangat baik',
                    },
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Ce.emerald500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const SectionTitle(
              title: 'Tag cepat',
              subtitle: 'Pilih maksimal 3 yang paling mewakili.',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in _quickTags)
                  FilterChip(
                    label: Text(tag),
                    selected: _tags.contains(tag),
                    onSelected: (selected) {
                      if (selected && _tags.length >= 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Maksimal 3 tag cepat.'),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        if (selected) {
                          _tags.add(tag);
                        } else {
                          _tags.remove(tag);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const SectionTitle(title: 'Komentar (opsional)'),
            TextField(
              controller: _comment,
              maxLength: 280,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Ceritakan pengalamanmu. Jangan cantumkan data pribadi.',
              ),
            ),
            const SizedBox(height: 6),
            const InfoBanner(
              message:
                  'Ulasan ditampilkan secara anonim di Review Shuffle. '
                  'Ulasan dengan kata kasar dapat disaring otomatis.',
              icon: Icons.shield_outlined,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _rating == 0 || _sending ? null : _submit,
                icon: _sending
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Ce.text,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(_sending ? 'Mengirim…' : 'Kirim ulasan'),
              ),
            ),
            if (_rating == 0)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Pilih bintang terlebih dahulu untuk mengirim.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Ce.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Ce.emerald500,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Terima kasih!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Ce.text,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ulasanmu membantu driver, merchant, dan mahasiswa lain '
                  'mendapat layanan yang lebih baik.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Ce.textMuted),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => context.go('/orders'),
                  child: const Text('Kembali ke riwayat'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    try {
      if (!AppConfig.demoMode && FirebaseBootstrap.ready) {
        final uid = ref.read(authStateProvider).value?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance
              .collection(FirestorePaths.reviews)
              .doc('${widget.orderId}-$uid')
              .set({
                'order_id': widget.orderId,
                'reviewer_id': uid,
                'rating': _rating,
                'tags': _tags.toList(),
                'comment': _comment.text.trim(),
                'created_at': FieldValue.serverTimestamp(),
              });
        }
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim ulasan. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
