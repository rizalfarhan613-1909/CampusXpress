import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class SalesPing {
  const SalesPing(this.id, this.label, this.place);

  final String id;
  final String label;
  final String place;
}

const _pings = [
  SalesPing('p1', 'Nasi Goreng Spesial', 'Gedung Kuliah Terpadu'),
  SalesPing('p2', 'Kopi Susu Gula Aren', 'Perpustakaan Pusat'),
  SalesPing('p3', 'Mie Ayam Bakso', 'Fakultas Saintek'),
  SalesPing('p4', 'Kirim Paket dokumen', 'Gate Utama'),
  SalesPing('p5', 'Es Teh Manis', 'Kantin Pusat B'),
];

/// Toast Sales Pings anonim (PRD §8 komponen 3), maksimal 1 toast / 6 detik.
class SalesPingToast extends StatefulWidget {
  const SalesPingToast({super.key});

  @override
  State<SalesPingToast> createState() => _SalesPingToastState();
}

class _SalesPingToastState extends State<SalesPingToast> {
  Timer? _timer;
  int _index = 0;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      setState(() {
        _visible = true;
        _index = (_index + 1) % _pings.length;
      });
      Future<void>.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _visible = false);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ping = _pings[_index];
    return IgnorePointer(
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _visible ? Offset.zero : const Offset(0, 1.4),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _visible ? 1 : 0,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Ce.surfaceHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Ce.emerald900),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Ce.emerald500, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 11, color: Ce.textMuted),
                      children: [
                        const TextSpan(text: 'Seseorang di '),
                        TextSpan(
                          text: ping.place,
                          style: const TextStyle(
                            color: Ce.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ' memesan '),
                        TextSpan(
                          text: ping.label,
                          style: const TextStyle(
                            color: Ce.emerald500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
