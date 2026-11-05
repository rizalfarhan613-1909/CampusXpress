import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/bento_card.dart';
import '../landmarks/landmark_data.dart';
import '../tracking/campus_map_data.dart';
import '../tracking/iso_map_view.dart';

/// Screen 04 — Landmark & Zone Picker Modal (M03).
class LandmarkPickerScreen extends StatefulWidget {
  const LandmarkPickerScreen({super.key, this.service = 'numpang'});

  final String service;

  @override
  State<LandmarkPickerScreen> createState() => _LandmarkPickerScreenState();
}

class _LandmarkPickerScreenState extends State<LandmarkPickerScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _zone;
  String? _pickup;
  String? _dropoff;
  bool _pickingPickup = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = LandmarkData.search(_query, zone: _zone);
    final fare = _pickup != null && _dropoff != null
        ? LandmarkData.fareFor(_pickup!, _dropoff!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.service == 'paket' ? 'Kirim Paket' : 'Numpang Kampus',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Column(
                children: [
                  _SelectionBar(
                    pickup: _pickup,
                    dropoff: _dropoff,
                    pickingPickup: _pickingPickup,
                    onPickPickup: () => setState(() => _pickingPickup = true),
                    onPickDropoff: () => setState(() => _pickingPickup = false),
                    onSwap: () {
                      setState(() {
                        final temp = _pickup;
                        _pickup = _dropoff;
                        _dropoff = temp;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 168,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Ce.radiusBento),
                      child: CustomPaint(
                        painter: FlatMapPainter(
                          paths: CampusMapData.paths,
                          landmarks: LandmarkData.all,
                          vehicle: null,
                          bearing: 0,
                          bounds: CampusMapData.bounds,
                          pickupId: _pickup,
                          dropoffId: _dropoff,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Cari landmark kampus…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final zone in const [
                          null,
                          LandmarkData.zone1,
                          LandmarkData.zone2,
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(zone ?? 'Semua zona'),
                              selected: _zone == zone,
                              onSelected: (_) => setState(() => _zone = zone),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: results.isEmpty
                  ? const EmptyState(
                      title: 'Landmark tidak ditemukan',
                      message:
                          'Coba kata kunci lain atau pilih zona yang berbeda.',
                      icon: Icons.location_off_outlined,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final landmark = results[index];
                        final selected =
                            landmark.id == _pickup || landmark.id == _dropoff;
                        return BentoCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          borderColor: selected ? Ce.emerald500 : Ce.emerald900,
                          onTap: () => _select(landmark.id),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Ce.emerald500.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  _iconFor(landmark.type),
                                  size: 18,
                                  color: Ce.emerald500,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      landmark.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Ce.text,
                                      ),
                                    ),
                                    Text(
                                      landmark.zone,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Ce.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (landmark.id == _pickup)
                                const StatusPill(
                                  label: 'Jemput',
                                  color: Color(0xFF60A5FA),
                                  compact: true,
                                ),
                              if (landmark.id == _dropoff)
                                const StatusPill(
                                  label: 'Antar',
                                  color: Ce.warning,
                                  compact: true,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (fare != null)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: const BoxDecoration(
                  color: Ce.surface,
                  border: Border(top: BorderSide(color: Ce.emerald900)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          size: 18,
                          color: Ce.emerald500,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Tarif zona',
                          style: TextStyle(fontSize: 12, color: Ce.textMuted),
                        ),
                        const Spacer(),
                        Text(
                          'Rp ${fare.toString()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Ce.emerald500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tarif ditentukan matriks zona dan tidak bisa diubah klien.',
                        style: TextStyle(fontSize: 10, color: Ce.textMuted),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => context.go(
                          '/checkout',
                          extra: {
                            'type': widget.service,
                            'pickup': _pickup,
                            'dropoff': _dropoff,
                            'deliveryFee': fare,
                          },
                        ),
                        child: const Text('Lanjut ke checkout'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _select(String id) {
    setState(() {
      if (_pickingPickup) {
        if (id == _dropoff) return;
        _pickup = id;
        if (_dropoff != null) _pickingPickup = false;
      } else {
        if (id == _pickup) return;
        _dropoff = id;
      }
    });
  }

  static IconData _iconFor(String type) {
    return switch (type) {
      'kantin' => Icons.restaurant_rounded,
      'gerbang' => Icons.door_front_door_rounded,
      'kost' => Icons.home_rounded,
      'ibadah' => Icons.mosque_rounded,
      'lapangan' => Icons.sports_soccer_rounded,
      _ => Icons.apartment_rounded,
    };
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.pickup,
    required this.dropoff,
    required this.pickingPickup,
    required this.onPickPickup,
    required this.onPickDropoff,
    required this.onSwap,
  });

  final String? pickup;
  final String? dropoff;
  final bool pickingPickup;
  final VoidCallback onPickPickup;
  final VoidCallback onPickDropoff;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Field(
            label: 'Titik jemput',
            value: pickup == null
                ? 'Pilih landmark'
                : LandmarkData.byId(pickup!).name,
            color: const Color(0xFF60A5FA),
            active: pickingPickup,
            onTap: onPickPickup,
          ),
        ),
        IconButton(
          onPressed: onSwap,
          icon: const Icon(Icons.swap_vert_rounded),
          tooltip: 'Tukar titik',
        ),
        Expanded(
          child: _Field(
            label: 'Titik antar',
            value: dropoff == null
                ? 'Pilih landmark'
                : LandmarkData.byId(dropoff!).name,
            color: Ce.warning,
            active: !pickingPickup,
            onTap: onPickDropoff,
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Ce.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? color : Ce.emerald900,
            width: active ? 1.4 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: active ? color : Ce.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Ce.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
