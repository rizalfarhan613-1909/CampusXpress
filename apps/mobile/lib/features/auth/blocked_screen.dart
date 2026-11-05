import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/bento_card.dart';

class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gpp_bad_rounded, size: 64, color: Ce.danger),
              const SizedBox(height: 16),
              const Text(
                'Akun dibekukan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Ce.text,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sesi kamu dicabut oleh admin. Kamu tetap dapat membuka Help Desk '
                'untuk menanyakan status akun.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Ce.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              BentoCard(
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.support_agent_rounded, color: Ce.emerald500),
                        SizedBox(width: 8),
                        Text(
                          'Help Desk Kampus',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Ce.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Senin–Jumat, 08.00–16.00 WIB\nhelpdesk@campus-express.id',
                      style: TextStyle(fontSize: 12, color: Ce.textMuted),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/support'),
                      child: const Text('Buka Help Desk'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () async {
                  if (ref.read(firebaseReadyProvider)) {
                    await ref.read(authRepositoryProvider).signOut();
                  }
                  ref.read(demoSessionProvider.notifier).signOut();
                  if (context.mounted) context.go('/auth');
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
