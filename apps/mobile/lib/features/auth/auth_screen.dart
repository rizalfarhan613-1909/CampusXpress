import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/models/app_user.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/role_nav.dart';
import '../../core/widgets/bento_card.dart';
import '../home/widgets/word_rotator.dart';
import 'auth_repository.dart';

/// Screen 02 — Auth Google SSO & Validasi NIM (M01).
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (!mounted) return;
      context.go('/home');
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          _error = switch (error.code) {
            'web-context-cancelled' => 'Login dibatalkan.',
            'network-request-failed' =>
              'Tidak ada koneksi. Periksa jaringan lalu coba lagi.',
            _ => 'Gagal masuk (${error.code}). Coba lagi.',
          };
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Gagal masuk. Pastikan Google Sign-In sudah dikonfigurasi.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _demoSignIn(UserRole role) {
    final user = AppUser.demo(role: role);
    ref.read(demoSessionProvider.notifier).signIn(user);
    ref.read(activeRoleProvider.notifier).setRole(role);
    context.go(homePathForRole(role));
  }

  @override
  Widget build(BuildContext context) {
    final demoMode = AppConfig.demoMode;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.go('/onboarding'),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Kembali',
              ),
              const SizedBox(height: 8),
              const Text(
                'Masuk ke',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Ce.text,
                  height: 1.1,
                ),
              ),
              const WordRotator(
                words: ['Campus Express', 'Numpang', 'Jastip', 'Jajan'],
                style: TextStyle(
                  color: Ce.emerald500,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Gunakan akun Google kampus. Email di luar @mhs.uin.ac.id '
                'akan ditolak dan sesi otomatis dihapus.',
                style: TextStyle(
                  fontSize: 13,
                  color: Ce.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          color: Ce.emerald500,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Verifikasi identitas kampus',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Ce.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _Step(number: '1', text: 'Masuk dengan Google SSO'),
                    const _Step(
                      number: '2',
                      text: 'Isi NIM dan nomor WhatsApp',
                    ),
                    const _Step(
                      number: '3',
                      text: 'NIM divalidasi unik oleh Gateway',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _signInGoogle,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Ce.text,
                                ),
                              )
                            : const Icon(Icons.g_mobiledata_rounded, size: 28),
                        label: Text(
                          _loading ? 'Menghubungkan…' : 'Masuk dengan Google',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'Domain wajib: @mhs.uin.ac.id',
                        style: TextStyle(fontSize: 11, color: Ce.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                InfoBanner(
                  message: _error!,
                  icon: Icons.error_outline_rounded,
                  color: Ce.danger,
                ),
              ],
              if (demoMode) ...[
                const SizedBox(height: 22),
                const SectionTitle(
                  title: 'Mode demo lokal',
                  subtitle:
                      'Firebase belum dikonfigurasi. Pilih peran untuk mencoba UI tanpa backend.',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final role in UserRole.values)
                      ActionChip(
                        avatar: Icon(
                          switch (role) {
                            UserRole.consumer => Icons.shopping_bag_rounded,
                            UserRole.driver => Icons.two_wheeler_rounded,
                            UserRole.merchant => Icons.storefront_rounded,
                            UserRole.admin =>
                              Icons.admin_panel_settings_rounded,
                          },
                          size: 16,
                          color: Ce.emerald500,
                        ),
                        label: Text('Demo ${role.label}'),
                        onPressed: () => _demoSignIn(role),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const InfoBanner(
                  message:
                      'Untuk mengaktifkan Firebase: jalankan `flutterfire configure` '
                      'atau isi FIREBASE_* lewat --dart-define.',
                  icon: Icons.tips_and_updates_outlined,
                ),
              ],
              const SizedBox(height: 26),
              const Text(
                'Butuh bantuan? Hubungi Help Desk kampus melalui layar '
                'Dispute & Safety setelah masuk.',
                style: TextStyle(
                  fontSize: 11,
                  color: Ce.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Ce.emerald500.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Ce.emerald500,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(text, style: const TextStyle(fontSize: 12, color: Ce.textMuted)),
        ],
      ),
    );
  }
}
