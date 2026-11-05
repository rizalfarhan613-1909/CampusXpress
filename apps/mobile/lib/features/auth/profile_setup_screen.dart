import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/role_nav.dart';
import '../../core/widgets/bento_card.dart';
import 'auth_repository.dart';

/// Screen 02 (lanjutan) — form NIM & WhatsApp setelah Google SSO.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  static String normalizePhone(String input) {
    var value = input.replaceAll(RegExp(r'[\s-]'), '');
    if (value.startsWith('0')) value = '+62${value.substring(1)}';
    if (value.startsWith('62')) value = '+$value';
    return value;
  }

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    _nameController.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final name = _nameController.text.trim();
    final nim = _nimController.text.trim();
    final phone = ProfileSetupScreen.normalizePhone(
      _phoneController.text.trim(),
    );

    try {
      if (AppConfig.demoMode) {
        ref
            .read(demoSessionProvider.notifier)
            .update(
              (user) =>
                  user.copyWith(displayName: name, nim: nim, phone: phone),
            );
        if (!mounted) return;
        final role = ref.read(activeRoleProvider);
        context.go(homePathForRole(role));
      } else {
        await ref
            .read(authRepositoryProvider)
            .saveProfile(displayName: name, nim: nim, phone: phone);
        if (!mounted) return;
        final user = ref.read(authStateProvider).value;
        context.go(homePathForRole(user?.role ?? ref.read(activeRoleProvider)));
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Gagal menyimpan profil. Periksa koneksi lalu coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lengkapi Profil'),
        leading: IconButton(
          onPressed: () => context.go('/onboarding'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Satu langkah lagi',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Ce.text,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'NIM dan nomor WhatsApp dipakai untuk verifikasi identitas '
                  'serta koordinasi order. Nomor disimpan dalam format E.164.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Ce.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                BentoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nama tampilan',
                          hintText: 'Contoh: Rani Mahasiswa',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.length < 2 || name.length > 40) {
                            return 'Nama 2–40 karakter';
                          }
                          if (!RegExp(r"^[A-Za-z .'\-]+$").hasMatch(name)) {
                            return 'Nama hanya huruf, spasi, titik, apostrof';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nimController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'NIM',
                          hintText: '10–12 digit angka',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (value) {
                          final nim = value?.trim() ?? '';
                          if (!RegExp(AppConfig.nimPattern).hasMatch(nim)) {
                            return 'NIM tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Nomor WhatsApp',
                          hintText: '0812xxxxxxx',
                          prefixIcon: Icon(Icons.chat_outlined),
                        ),
                        validator: (value) {
                          final phone = (value ?? '').replaceAll(
                            RegExp(r'[\s-]'),
                            '',
                          );
                          if (!RegExp(AppConfig.phonePattern).hasMatch(phone)) {
                            return 'Nomor WhatsApp tidak valid';
                          }
                          return null;
                        },
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
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Ce.text,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(_loading ? 'Menyimpan…' : 'Simpan & Lanjut'),
                  ),
                ),
                const SizedBox(height: 12),
                const InfoBanner(
                  message:
                      'NIM hanya bisa dipakai satu akun. Jika sudah terdaftar, '
                      'gunakan akun Google kampus yang benar.',
                  icon: Icons.lock_outline_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
