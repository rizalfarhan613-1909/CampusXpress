import 'package:flutter/foundation.dart';

/// Landmark hub UINSU Tuntungan. Sumber tunggal: `scripts/seed-tuntungan-hub.ts`.
@immutable
class HubLandmark {
  const HubLandmark({
    required this.id,
    required this.name,
    required this.zone,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  final String id;
  final String name;
  final String zone;
  final double latitude;
  final double longitude;
  final String type;
}

class TuntunganHubData {
  TuntunganHubData._();

  static const centerLatitude = 3.5479;
  static const centerLongitude = 98.6469;

  static const all = <HubLandmark>[
    HubLandmark(
      id: 'gedung-fst-uinsu',
      name: 'Gedung FST UINSU Tuntungan',
      zone: 'Zona 1',
      latitude: 3.5479,
      longitude: 98.6469,
      type: 'gedung',
    ),
    HubLandmark(
      id: 'gedung-rektorat-dekanat',
      name: 'Gedung Rektorat & Dekanat',
      zone: 'Zona 1',
      latitude: 3.5473,
      longitude: 98.6462,
      type: 'gedung',
    ),
    HubLandmark(
      id: 'pujasera-kantin-kampus',
      name: 'Pujasera Kantin Kampus',
      zone: 'Zona 1',
      latitude: 3.5484,
      longitude: 98.6476,
      type: 'kantin',
    ),
    HubLandmark(
      id: 'kos-jl-lapangan-golf',
      name: 'Area Kos Jl. Lapangan Golf',
      zone: 'Zona 2',
      latitude: 3.5495,
      longitude: 98.6488,
      type: 'kost',
    ),
    HubLandmark(
      id: 'tugu-simpang-tuntungan',
      name: 'Tugu / Simpang Tuntungan',
      zone: 'Zona 3',
      latitude: 3.5469,
      longitude: 98.6505,
      type: 'gerbang',
    ),
    HubLandmark(
      id: 'pasar-induk-lau-cih',
      name: 'Pasar Induk Lau Cih',
      zone: 'Zona 3',
      latitude: 3.5523,
      longitude: 98.6542,
      type: 'pasar',
    ),
  ];

  static HubLandmark? byId(String id) {
    for (final landmark in all) {
      if (landmark.id == id) return landmark;
    }
    return null;
  }
}