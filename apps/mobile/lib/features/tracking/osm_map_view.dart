import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../app/theme.dart';
import 'tuntungan_hub_data.dart';

/// Peta OpenStreetMap (flutter_map) untuk hub UINSU Tuntungan.
///
/// Penanda memakai ikon kustom, bukan bulatan polos:
/// - **Driver (motor)** — badge emerald `#006C4A` berikon motor putih dengan
///   gelombang denyut (pulse ring) di sekelilingnya.
/// - **UMKM (kantin/pasar)** — badge amber `#D97706` berikon sendok-garpu atau
///   toko pujasera.
/// - **Tujuan (drop-off)** — pin merah `#BA1A1A` berlabel nama gedung.
/// Jalur antar titik digambar sebagai polyline emerald berformat putus-putus.
///
/// Tile server publik: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`.
class OsmMapView extends StatelessWidget {
  const OsmMapView({
    super.key,
    this.height = 300,
    this.highlightId,
    this.driverLatitude,
    this.driverLongitude,
  });

  final double height;
  final String? highlightId;

  /// Posisi driver realtime; bila kosong dipakai titik tengah jalur menuju
  /// tujuan.
  final double? driverLatitude;
  final double? driverLongitude;

  static const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  Widget build(BuildContext context) {
    final destination =
        TuntunganHubData.byId(highlightId ?? '') ?? TuntunganHubData.all.first;

    // Titik awal jalur: pusat hub, kecuali hub sendiri yang menjadi tujuan.
    final origin = destination.id == 'gedung-fst-uinsu'
        ? TuntunganHubData.byId('pasar-induk-lau-cih') ??
              TuntunganHubData.all.first
        : TuntunganHubData.byId('gedung-fst-uinsu') ??
              TuntunganHubData.all.first;

    final driver = driverLatitude != null && driverLongitude != null
        ? latlng.LatLng(driverLatitude!, driverLongitude!)
        : latlng.LatLng(
            (origin.latitude + destination.latitude) / 2,
            (origin.longitude + destination.longitude) / 2,
          );

    final markers = <Marker>[
      for (final landmark in TuntunganHubData.all)
        _landmarkMarker(landmark, destination.id),
      // Driver digambar terakhir agar berada di lapisan paling atas.
      Marker(
        point: driver,
        width: 112,
        height: 112,
        child: const _DriverMarker(),
      ),
    ];

    final route = <latlng.LatLng>[
      latlng.LatLng(origin.latitude, origin.longitude),
      driver,
      latlng.LatLng(destination.latitude, destination.longitude),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(Ce.radiusBento),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: const latlng.LatLng(
                  TuntunganHubData.centerLatitude,
                  TuntunganHubData.centerLongitude,
                ),
                initialZoom: 15.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: _tileUrl,
                  userAgentPackageName: 'id.ac.uin.campus_express',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route,
                      strokeWidth: 5,
                      color: Ce.mapDriver,
                      pattern: StrokePattern.dashed(
                        segments: <double>[12, 10],
                      ),
                    ),
                  ],
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Ce.bg.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '© OpenStreetMap',
                  style: TextStyle(fontSize: 9, color: Ce.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _landmarkMarker(HubLandmark landmark, String destinationId) {
    final point = latlng.LatLng(landmark.latitude, landmark.longitude);

    if (landmark.id == destinationId) {
      return Marker(
        point: point,
        width: 200,
        height: 62,
        alignment: Alignment.topCenter,
        child: _DestinationMarker(label: _shortLabel(landmark)),
      );
    }

    final isMerchant = landmark.type == 'kantin' || landmark.type == 'pasar';
    final badge = _MarkerBadge(
      size: isMerchant ? 34 : 30,
      color: isMerchant ? Ce.mapMerchant : Ce.emerald500,
      icon: isMerchant
          ? (landmark.type == 'pasar' ? Icons.storefront : Icons.restaurant)
          : (landmark.type == 'gedung' ? Icons.school : Icons.place),
    );

    return Marker(
      point: point,
      width: 44,
      height: 44,
      child: Tooltip(
        message: '${landmark.name} · ${landmark.zone}',
        child: Center(child: badge),
      ),
    );
  }
}

/// Label ramah pada pin tujuan (mis. `Gedung FST` → "Lobi Utama FST").
String _shortLabel(HubLandmark landmark) {
  switch (landmark.id) {
    case 'gedung-fst-uinsu':
      return 'Lobi Utama FST';
    case 'gedung-rektorat-dekanat':
      return 'Rektorat & Dekanat';
    case 'pujasera-kantin-kampus':
      return 'Pujasera Kampus';
    case 'kos-jl-lapangan-golf':
      return 'Kos Lapangan Golf';
    case 'tugu-simpang-tuntungan':
      return 'Simpang Tuntungan';
    case 'pasar-induk-lau-cih':
      return 'Pasar Induk Lau Cih';
    default:
      return landmark.name;
  }
}

/// Badge bundar berikon putih (dipakai untuk UMKM & landmark umum).
class _MarkerBadge extends StatelessWidget {
  const _MarkerBadge({
    required this.size,
    required this.color,
    required this.icon,
  });

  final double size;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
  }
}

/// Penanda driver: badge emerald `#006C4A` + gelombang denyut (pulse ring).
class _DriverMarker extends StatefulWidget {
  const _DriverMarker();

  @override
  State<_DriverMarker> createState() => _DriverMarkerState();
}

class _DriverMarkerState extends State<_DriverMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.scale(
              scale: 1 + t,
              child: Opacity(
                opacity: (1 - t) * 0.5,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Ce.mapDriver,
                  ),
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: const _MarkerBadge(
        size: 48,
        color: Ce.mapDriver,
        icon: Icons.two_wheeler,
      ),
    );
  }
}

/// Pin tujuan: label nama gedung di atas ikon `location_on` merah.
class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 184),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Ce.mapDropoff,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Icon(Icons.location_on, color: Ce.mapDropoff, size: 30),
        ],
      ),
    );
  }
}