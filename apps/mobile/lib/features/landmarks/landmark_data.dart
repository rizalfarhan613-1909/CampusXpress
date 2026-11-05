import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';

@immutable
class Landmark {
  const Landmark({
    required this.id,
    required this.name,
    required this.zone,
    required this.latitude,
    required this.longitude,
    this.type = 'gedung',
  });

  final String id;
  final String name;
  final String zone;
  final double latitude;
  final double longitude;
  final String type;

  LatLng get coordinate => LatLng(latitude, longitude);

  factory Landmark.fromMap(String id, Map<String, dynamic> data) {
    return Landmark(
      id: id,
      name: (data['name'] as String?) ?? id,
      zone:
          (data['zone_group'] as String?) ??
          (data['zone'] as String?) ??
          'Zona 1',
      latitude:
          (data['lat'] as num?)?.toDouble() ??
          (data['latitude'] as num?)?.toDouble() ??
          AppConfig.campusCenter.latitude,
      longitude:
          (data['lng'] as num?)?.toDouble() ??
          (data['longitude'] as num?)?.toDouble() ??
          AppConfig.campusCenter.longitude,
      type: (data['type'] as String?) ?? 'gedung',
    );
  }
}

/// 11 landmark preset sesuai backend/functions/src/core/landmarkSeed.ts.
class LandmarkData {
  LandmarkData._();

  static const zone1 = 'Zona 1';
  static const zone2 = 'Zona 2';

  static const all = <Landmark>[
    Landmark(
      id: 'gedung-kuliah-terpadu',
      name: 'Gedung Kuliah Terpadu',
      zone: zone1,
      latitude: 3.5595,
      longitude: 98.6605,
      type: 'gedung',
    ),
    Landmark(
      id: 'perpustakaan-pusat',
      name: 'Perpustakaan Pusat',
      zone: zone1,
      latitude: 3.5590,
      longitude: 98.6598,
      type: 'gedung',
    ),
    Landmark(
      id: 'fakultas-saintek',
      name: 'Fakultas Saintek',
      zone: zone1,
      latitude: 3.5583,
      longitude: 98.6608,
      type: 'gedung',
    ),
    Landmark(
      id: 'fakultas-ekonomi',
      name: 'Fakultas Ekonomi',
      zone: zone1,
      latitude: 3.5586,
      longitude: 98.6595,
      type: 'gedung',
    ),
    Landmark(
      id: 'masjid-kampus',
      name: 'Masjid Kampus',
      zone: zone1,
      latitude: 3.5598,
      longitude: 98.6593,
      type: 'ibadah',
    ),
    Landmark(
      id: 'lapangan-utama',
      name: 'Lapangan Utama',
      zone: zone1,
      latitude: 3.5603,
      longitude: 98.6602,
      type: 'lapangan',
    ),
    Landmark(
      id: 'gate-utama',
      name: 'Gate Utama',
      zone: zone2,
      latitude: 3.5575,
      longitude: 98.6600,
      type: 'gerbang',
    ),
    Landmark(
      id: 'gate-2',
      name: 'Gate 2',
      zone: zone2,
      latitude: 3.5610,
      longitude: 98.6612,
      type: 'gerbang',
    ),
    Landmark(
      id: 'kost-gang-melati',
      name: 'Area Kost Gang Melati',
      zone: zone2,
      latitude: 3.5565,
      longitude: 98.6615,
      type: 'kost',
    ),
    Landmark(
      id: 'kost-gang-mawar',
      name: 'Area Kost Gang Mawar',
      zone: zone2,
      latitude: 3.5568,
      longitude: 98.6588,
      type: 'kost',
    ),
    Landmark(
      id: 'kantin-pusat-b',
      name: 'Kantin Pusat B',
      zone: zone2,
      latitude: 3.5599,
      longitude: 98.6610,
      type: 'kantin',
    ),
  ];

  static Landmark byId(String id) =>
      all.firstWhere((landmark) => landmark.id == id, orElse: () => all.first);

  static List<Landmark> search(String query, {String? zone}) {
    final q = query.trim().toLowerCase();
    return all.where((landmark) {
      final matchQuery =
          q.isEmpty ||
          landmark.name.toLowerCase().contains(q) ||
          landmark.id.contains(q);
      final matchZone = zone == null || landmark.zone == zone;
      return matchQuery && matchZone;
    }).toList();
  }

  /// Tarif mengikuti matriks zona backend (Zona 1↔1 Rp 4.000,
  /// Zona 1↔2 Rp 6.000, Zona 2↔2 Rp 5.000).
  static int fareFor(String fromId, String toId) {
    final from = byId(fromId).zone;
    final to = byId(toId).zone;
    if (from == to && from == zone1) return 4000;
    if (from == to && from == zone2) return 5000;
    return 6000;
  }
}
