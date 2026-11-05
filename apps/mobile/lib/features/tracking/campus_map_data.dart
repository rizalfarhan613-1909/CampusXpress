import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../landmarks/landmark_data.dart';

class CampusBounds {
  const CampusBounds({required this.southwest, required this.northeast});

  final LatLng southwest;
  final LatLng northeast;
}

class CampusBuilding {
  const CampusBuilding({
    required this.name,
    required this.footprint,
    this.heightM = 18,
  });

  final String name;

  /// Koordinat lokal ternormalisasi 0..1 untuk render isometrik.
  final Rect footprint;
  final double heightM;
}

class CampusEdge {
  const CampusEdge(this.a, this.b, this.meters);

  final String a;
  final String b;
  final double meters;
}

/// Data peta kampus yang ditanam di aplikasi. Pada produksi data ini berasal
/// dari `campus-map.v3.geojson` di R2 (tech.md §5.1); versi lokal membuat
/// peta tetap tampil tanpa tile server berbayar.
class CampusMapData {
  CampusMapData._();

  static final Map<String, LatLng> coords = {
    for (final landmark in LandmarkData.all) landmark.id: landmark.coordinate,
  };

  static const bounds = CampusBounds(
    southwest: LatLng(3.5555, 98.6580),
    northeast: LatLng(3.5615, 98.6620),
  );

  static const edges = <CampusEdge>[
    CampusEdge('gedung-kuliah-terpadu', 'perpustakaan-pusat', 220),
    CampusEdge('gedung-kuliah-terpadu', 'fakultas-saintek', 180),
    CampusEdge('gedung-kuliah-terpadu', 'masjid-kampus', 260),
    CampusEdge('gedung-kuliah-terpadu', 'lapangan-utama', 240),
    CampusEdge('gedung-kuliah-terpadu', 'kantin-pusat-b', 190),
    CampusEdge('perpustakaan-pusat', 'fakultas-ekonomi', 200),
    CampusEdge('perpustakaan-pusat', 'masjid-kampus', 170),
    CampusEdge('fakultas-saintek', 'gate-utama', 340),
    CampusEdge('fakultas-saintek', 'kantin-pusat-b', 210),
    CampusEdge('fakultas-ekonomi', 'gate-utama', 310),
    CampusEdge('masjid-kampus', 'gate-utama', 360),
    CampusEdge('lapangan-utama', 'gate-2', 280),
    CampusEdge('kantin-pusat-b', 'gate-2', 250),
    CampusEdge('gate-utama', 'gate-2', 520),
    CampusEdge('gate-utama', 'kost-gang-melati', 420),
    CampusEdge('gate-utama', 'kost-gang-mawar', 390),
    CampusEdge('gate-2', 'kost-gang-melati', 260),
    CampusEdge('kost-gang-melati', 'kost-gang-mawar', 480),
    CampusEdge('lapangan-utama', 'masjid-kampus', 190),
  ];

  static final List<List<LatLng>> paths = [
    for (final edge in edges) [coords[edge.a]!, coords[edge.b]!],
  ];

  static const buildings = <CampusBuilding>[
    CampusBuilding(
      name: 'Gedung Kuliah Terpadu',
      footprint: Rect.fromLTWH(0.38, 0.38, 0.17, 0.12),
      heightM: 24,
    ),
    CampusBuilding(
      name: 'Perpustakaan Pusat',
      footprint: Rect.fromLTWH(0.27, 0.33, 0.11, 0.10),
      heightM: 18,
    ),
    CampusBuilding(
      name: 'Fakultas Saintek',
      footprint: Rect.fromLTWH(0.45, 0.57, 0.14, 0.11),
      heightM: 20,
    ),
    CampusBuilding(
      name: 'Fakultas Ekonomi',
      footprint: Rect.fromLTWH(0.20, 0.53, 0.13, 0.10),
      heightM: 16,
    ),
    CampusBuilding(
      name: 'Masjid Kampus',
      footprint: Rect.fromLTWH(0.24, 0.18, 0.12, 0.10),
      heightM: 22,
    ),
    CampusBuilding(
      name: 'Lapangan Utama',
      footprint: Rect.fromLTWH(0.50, 0.16, 0.18, 0.12),
      heightM: 3,
    ),
    CampusBuilding(
      name: 'Kantin Pusat B',
      footprint: Rect.fromLTWH(0.57, 0.38, 0.13, 0.10),
      heightM: 10,
    ),
    CampusBuilding(
      name: 'Gate Utama',
      footprint: Rect.fromLTWH(0.40, 0.78, 0.10, 0.06),
      heightM: 8,
    ),
  ];
}
