import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/firebase/firestore_paths.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/bento_card.dart';

/// Screen 20 — Driver Registration & Document Upload (M02, M19).
class DriverRegistrationScreen extends ConsumerStatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  ConsumerState<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState
    extends ConsumerState<DriverRegistrationScreen> {
  final _name = TextEditingController();
  final _nim = TextEditingController();
  final _phone = TextEditingController();
  final _plate = TextEditingController();
  final _vehicle = TextEditingController();
  final _emergency = TextEditingController();
  int _step = 0;
  String _vehicleType = 'Motor';
  bool _consent = false;
  bool _ktm = false;
  bool _sim = false;
  bool _vehiclePhoto = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).value;
    _name.text = user?.displayName ?? '';
    _nim.text = user?.nim ?? '';
    _phone.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _nim.dispose();
    _phone.dispose();
    _plate.dispose();
    _vehicle.dispose();
    _emergency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final status = user?.driverStatus ?? 'none';

    if (user?.isDriverApproved == true) {
      return _statusScaffold(
        icon: Icons.verified_rounded,
        color: Ce.emerald500,
        title: 'Kamu sudah driver aktif',
        message:
            'Akun driver sudah disetujui. Buka radar untuk mulai mengklaim '
            'order dan kelola saldo deposit.',
        action: FilledButton.icon(
          onPressed: () => context.go('/driver/radar'),
          icon: const Icon(Icons.radar_rounded),
          label: const Text('Buka radar driver'),
        ),
      );
    }

    if (status == 'pending_review' || status == 'pending_docs') {
      return _statusScaffold(
        icon: Icons.hourglass_top_rounded,
        color: Ce.warning,
        title: 'Pengajuan sedang ditinjau',
        message:
            'Admin kampus memverifikasi KTM, SIM, dan data kendaraan maksimal '
            '2×24 jam. Kamu akan menerima notifikasi setelah disetujui.',
        action: OutlinedButton(
          onPressed: () => context.go('/profile'),
          child: const Text('Kembali ke profil'),
        ),
      );
    }

    if (status == 'rejected') {
      return _statusScaffold(
        icon: Icons.cancel_rounded,
        color: Ce.danger,
        title: 'Pengajuan ditolak',
        message:
            'Dokumen belum memenuhi syarat. Perbaiki data lalu ajukan ulang. '
            'Alasan: foto SIM buram / masa berlaku tidak terbaca.',
        action: FilledButton(
          onPressed: () {
            ref
                .read(demoSessionProvider.notifier)
                .update((current) => current.copyWith(driverStatus: 'none'));
          },
          child: const Text('Ajukan ulang'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Driver'),
        leading: IconButton(
          onPressed: () => context.go('/profile'),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
          children: [
            _Stepper(step: _step),
            const SizedBox(height: 14),
            if (_step == 0)
              _buildIdentity()
            else if (_step == 1)
              _buildVehicle()
            else
              _buildReview(),
            if (_error != null) ...[
              const SizedBox(height: 10),
              InfoBanner(
                message: _error!,
                icon: Icons.error_outline_rounded,
                color: Ce.danger,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _step--;
                        _error = null;
                      }),
                      child: const Text('Kembali'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _next,
                    icon: _submitting
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Ce.text,
                            ),
                          )
                        : Icon(
                            _step == 2
                                ? Icons.send_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                    label: Text(
                      _submitting
                          ? 'Mengirim…'
                          : _step == 2
                          ? 'Kirim pengajuan'
                          : 'Lanjut',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusScaffold({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required Widget action,
  }) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status Driver')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: color),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Ce.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Ce.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                action,
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.go('/support'),
                  child: const Text('Hubungi Help Desk'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentity() {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Identitas & dokumen',
            subtitle: 'Data harus sesuai KTM dan SIM aktif.',
          ),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama lengkap',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nim,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'NIM',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor WhatsApp aktif',
              prefixIcon: Icon(Icons.chat_outlined),
            ),
          ),
          const SizedBox(height: 12),
          _UploadTile(
            title: 'Foto KTM',
            subtitle: 'Kartu tanda mahasiswa aktif',
            attached: _ktm,
            onTap: () => setState(() => _ktm = !_ktm),
          ),
          const SizedBox(height: 8),
          _UploadTile(
            title: 'Foto SIM C / SIM A',
            subtitle: 'Masa berlaku minimal 3 bulan',
            attached: _sim,
            onTap: () => setState(() => _sim = !_sim),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _consent,
            activeColor: Ce.emerald500,
            title: const Text(
              'Saya menyetujui pemrosesan data pribadi',
              style: TextStyle(fontSize: 12, color: Ce.text),
            ),
            subtitle: const Text(
              'Sesuai UU PDP. Data hanya dipakai untuk verifikasi driver dan '
              'tidak dibagikan ke pihak ketiga.',
              style: TextStyle(fontSize: 9.5, color: Ce.textMuted),
            ),
            onChanged: (value) => setState(() => _consent = value ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicle() {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Data kendaraan',
            subtitle: 'Kendaraan harus atas nama sendiri atau keluarga.',
          ),
          DropdownButtonFormField<String>(
            initialValue: _vehicleType,
            decoration: const InputDecoration(
              labelText: 'Jenis kendaraan',
              prefixIcon: Icon(Icons.two_wheeler_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'Motor', child: Text('Motor')),
              DropdownMenuItem(value: 'Mobil', child: Text('Mobil')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _vehicleType = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vehicle,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Merek & model',
              hintText: 'Honda Vario 160',
              prefixIcon: Icon(Icons.directions_bike_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _plate,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Nomor polisi',
              hintText: 'B 1234 XYZ',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emergency,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Kontak darurat',
              hintText: 'Nama & nomor keluarga',
              prefixIcon: Icon(Icons.emergency_outlined),
            ),
          ),
          const SizedBox(height: 12),
          _UploadTile(
            title: 'Foto kendaraan & STNK',
            subtitle: 'Tampak depan, plat terbaca',
            attached: _vehiclePhoto,
            onTap: () => setState(() => _vehiclePhoto = !_vehiclePhoto),
          ),
          const SizedBox(height: 10),
          const InfoBanner(
            message:
                'Semua foto dikompres ke WebP ≤ 80 KB. Pastikan cahaya cukup '
                'dan tidak ada data sensitif lain yang terlihat.',
            icon: Icons.photo_camera_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildReview() {
    return Column(
      children: [
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: 'Ringkasan pengajuan'),
              _ReviewRow(label: 'Nama', value: _name.text.trim()),
              _ReviewRow(label: 'NIM', value: _nim.text.trim()),
              _ReviewRow(label: 'WhatsApp', value: _phone.text.trim()),
              _ReviewRow(label: 'Kendaraan', value: _vehicle.text.trim()),
              _ReviewRow(
                label: 'Jenis',
                value: '$_vehicleType · ${_plate.text.trim()}',
              ),
              _ReviewRow(
                label: 'Kontak darurat',
                value: _emergency.text.trim(),
              ),
              _ReviewRow(
                label: 'Dokumen',
                value: [
                  if (_ktm) 'KTM',
                  if (_sim) 'SIM',
                  if (_vehiclePhoto) 'STNK',
                ].join(', '),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const InfoBanner(
          message:
              'Setelah dikirim, pengajuan tidak dapat diubah sampai admin '
              'memberi keputusan. Kamu akan dihubungi lewat WhatsApp kampus.',
          icon: Icons.info_outline_rounded,
        ),
      ],
    );
  }

  void _next() {
    if (_step == 0) {
      if (_name.text.trim().length < 3) {
        setState(() => _error = 'Nama lengkap minimal 3 karakter.');
        return;
      }
      if (!RegExp(AppConfig.nimPattern).hasMatch(_nim.text.trim())) {
        setState(() => _error = 'NIM tidak valid (10–12 digit).');
        return;
      }
      if (!RegExp(
        AppConfig.phonePattern,
      ).hasMatch(_phone.text.trim().replaceAll(RegExp(r'[\s-]'), ''))) {
        setState(() => _error = 'Nomor WhatsApp tidak valid.');
        return;
      }
      if (!_ktm || !_sim) {
        setState(() => _error = 'Unggah foto KTM dan SIM terlebih dahulu.');
        return;
      }
      if (!_consent) {
        setState(() => _error = 'Persetujuan pemrosesan data wajib dicentang.');
        return;
      }
      setState(() {
        _step = 1;
        _error = null;
      });
      return;
    }
    if (_step == 1) {
      if (_vehicle.text.trim().length < 3) {
        setState(() => _error = 'Merek & model kendaraan wajib diisi.');
        return;
      }
      if (!RegExp(
        AppConfig.platePattern,
      ).hasMatch(_plate.text.trim().toUpperCase())) {
        setState(
          () => _error = 'Nomor polisi tidak valid. Contoh: B 1234 XYZ.',
        );
        return;
      }
      if (_emergency.text.trim().length < 6) {
        setState(() => _error = 'Kontak darurat wajib diisi.');
        return;
      }
      if (!_vehiclePhoto) {
        setState(() => _error = 'Unggah foto kendaraan & STNK.');
        return;
      }
      setState(() {
        _step = 2;
        _error = null;
      });
      return;
    }
    _submit();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (AppConfig.demoMode) {
        await Future<void>.delayed(const Duration(milliseconds: 650));
        ref
            .read(demoSessionProvider.notifier)
            .update(
              (current) => current.copyWith(driverStatus: 'pending_review'),
            );
      } else {
        final uid = ref.read(authStateProvider).value?.uid;
        if (uid != null && FirebaseBootstrap.ready) {
          await FirebaseFirestore.instance
              .collection(FirestorePaths.driverProfiles)
              .doc(uid)
              .set({
                'status': 'pending_review',
                'full_name': _name.text.trim(),
                'nim': _nim.text.trim(),
                'phone': _phone.text.trim(),
                'vehicle_type': _vehicleType,
                'vehicle_model': _vehicle.text.trim(),
                'plate_number': _plate.text.trim().toUpperCase(),
                'emergency_contact': _emergency.text.trim(),
                'ktm_uploaded': _ktm,
                'sim_uploaded': _sim,
                'stnk_uploaded': _vehiclePhoto,
                'submitted_at': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pengajuan terkirim'),
          content: const Text(
            'Admin akan memverifikasi dokumen maksimal 2×24 jam. '
            'Status dapat dicek di halaman ini atau profil.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      if (mounted) context.go('/profile');
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Gagal mengirim pengajuan. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Identitas', 'Kendaraan', 'Review'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step ? Ce.emerald500 : Ce.emerald900,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: i == step ? FontWeight.w800 : FontWeight.w500,
                    color: i <= step ? Ce.text : Ce.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (i < labels.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.title,
    required this.subtitle,
    required this.attached,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool attached;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Ce.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: attached ? Ce.emerald500 : Ce.emerald900),
        ),
        child: Row(
          children: [
            Icon(
              attached ? Icons.check_circle_rounded : Icons.upload_file_rounded,
              color: attached ? Ce.emerald500 : Ce.textMuted,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Ce.text,
                    ),
                  ),
                  Text(
                    attached ? 'Terpasang · WebP ≤ 80 KB' : subtitle,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: attached ? Ce.emerald500 : Ce.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              attached ? 'Ganti' : 'Unggah',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Ce.emerald500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: Ce.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Ce.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
