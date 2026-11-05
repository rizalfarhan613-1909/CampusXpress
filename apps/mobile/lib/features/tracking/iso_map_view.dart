import 'dart:io';
import 'dart:math' as math;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../landmarks/landmark_data.dart';
import 'campus_map_data.dart';
import 'tracking_controller.dart';

enum RenderMode { iso3d, flat2d }

/// Memilih mode render sesuai PRD §5.4 / tech.md §5.9.
class RenderModeController extends ChangeNotifier {
  RenderMode mode = RenderMode.iso3d;
  bool forced = false;
  int _slowFrames = 0;

  Future<void> init({required bool userBatterySaver}) async {
    if (userBatterySaver) {
      _set(RenderMode.flat2d, forced: true);
      return;
    }
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        if (info.isLowRamDevice) {
          _set(RenderMode.flat2d);
          return;
        }
      } catch (_) {
        // Perangkat tidak mendukung info; lanjut ke pemantauan FPS.
      }
    }
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void applyBatterySaver(bool enabled) {
    if (enabled) {
      _set(RenderMode.flat2d, forced: true);
    } else if (forced) {
      _set(RenderMode.iso3d);
    }
  }

  void toggleManual() {
    _set(mode == RenderMode.iso3d ? RenderMode.flat2d : RenderMode.iso3d);
  }

  void _onTimings(List<FrameTiming> timings) {
    if (forced || mode == RenderMode.flat2d || timings.isEmpty) return;
    final slow = timings
        .where((frame) => frame.totalSpan.inMilliseconds > 42)
        .length;
    _slowFrames = slow > timings.length / 2 ? _slowFrames + 1 : 0;
    if (_slowFrames >= 3) _set(RenderMode.flat2d);
  }

  void _set(RenderMode next, {bool forced = false}) {
    if (mode == next && this.forced == forced) return;
    mode = next;
    this.forced = forced;
    notifyListeners();
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }
}

/// Peta kampus isometrik 3D berbasis Canvas, dengan fallback 2D otomatis.
///
/// Tidak memanggil tile server berbayar: seluruh geometri berasal dari
/// `CampusMapData` dan dapat diganti dengan GeoJSON R2 pada produksi.
class IsoMapView extends StatefulWidget {
  const IsoMapView({
    super.key,
    required this.controller,
    this.batterySaver = false,
    this.height = 320,
    this.pickupId,
    this.dropoffId,
    this.showModeToggle = true,
  });

  final TrackingController controller;
  final bool batterySaver;
  final double height;
  final String? pickupId;
  final String? dropoffId;
  final bool showModeToggle;

  @override
  State<IsoMapView> createState() => _IsoMapViewState();
}

class _IsoMapViewState extends State<IsoMapView>
    with SingleTickerProviderStateMixin {
  late final RenderModeController _mode;
  late final Ticker _ticker;
  Duration _lastFrame = Duration.zero;

  @override
  void initState() {
    super.initState();
    _mode = RenderModeController()..init(userBatterySaver: widget.batterySaver);
    _mode.addListener(_onModeChanged);
    _ticker = createTicker((elapsed) {
      if (elapsed - _lastFrame < const Duration(milliseconds: 33)) return;
      _lastFrame = elapsed;
      if (mounted) setState(() {});
    })..start();
  }

  void _onModeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant IsoMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.batterySaver != widget.batterySaver) {
      _mode.applyBatterySaver(widget.batterySaver);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _mode
      ..removeListener(_onModeChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pose = widget.controller.pose(DateTime.now());
    final vehicle = pose?.position;

    return ClipRRect(
      borderRadius: BorderRadius.circular(Ce.radiusBento),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _mode.mode == RenderMode.iso3d
                    ? CustomPaint(
                        key: const ValueKey('iso'),
                        painter: IsoMapPainter(
                          paths: CampusMapData.paths,
                          landmarks: LandmarkData.all,
                          vehicle: vehicle,
                          bearing: pose?.bearing ?? 0,
                          pickupId: widget.pickupId,
                          dropoffId: widget.dropoffId,
                        ),
                      )
                    : CustomPaint(
                        key: const ValueKey('flat'),
                        painter: FlatMapPainter(
                          paths: CampusMapData.paths,
                          landmarks: LandmarkData.all,
                          vehicle: vehicle,
                          bearing: pose?.bearing ?? 0,
                          bounds: CampusMapData.bounds,
                          pickupId: widget.pickupId,
                          dropoffId: widget.dropoffId,
                        ),
                      ),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: _MapBadge(
                icon: _mode.mode == RenderMode.iso3d
                    ? Icons.view_in_ar_rounded
                    : Icons.map_outlined,
                label: _mode.mode == RenderMode.iso3d
                    ? 'Peta 3D Isometrik'
                    : 'Mode 2D Hemat',
                onTap: widget.showModeToggle ? _mode.toggleManual : null,
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Ce.bg.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Ce.emerald900),
                ),
                child: const Text(
                  'Tanpa tile berbayar',
                  style: TextStyle(fontSize: 10, color: Ce.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Ce.bg.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Ce.emerald500),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Ce.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Offset _normalize(LatLng coordinate, CampusBounds bounds) {
  final width = bounds.northeast.longitude - bounds.southwest.longitude;
  final height = bounds.northeast.latitude - bounds.southwest.latitude;
  return Offset(
    (coordinate.longitude - bounds.southwest.longitude) / width,
    1 - (coordinate.latitude - bounds.southwest.latitude) / height,
  );
}

Offset _isoPoint(Offset normalized, Size size, {double height = 0}) {
  final scale = math.min(size.width, size.height) * 0.78;
  final x = (normalized.dx - 0.5) * scale;
  final y = (normalized.dy - 0.5) * scale;
  final center = Offset(size.width / 2, size.height * 0.56);
  return Offset(
    center.dx + (x - y) * 0.866,
    center.dy + (x + y) * 0.5 - height * scale * 0.55,
  );
}

class IsoMapPainter extends CustomPainter {
  IsoMapPainter({
    required this.paths,
    required this.landmarks,
    required this.vehicle,
    required this.bearing,
    this.pickupId,
    this.dropoffId,
  });

  final List<List<LatLng>> paths;
  final List<Landmark> landmarks;
  final LatLng? vehicle;
  final double bearing;
  final String? pickupId;
  final String? dropoffId;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF071B13), Color(0xFF04130E)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);

    _drawGrid(canvas, size);

    final pathPaint = Paint()
      ..color = const Color(0xFF0B3B2C)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final path in paths) {
      final projected = path
          .map(
            (coordinate) =>
                _isoPoint(_normalize(coordinate, CampusMapData.bounds), size),
          )
          .toList();
      if (projected.length < 2) continue;
      final route = Path()..moveTo(projected.first.dx, projected.first.dy);
      for (final point in projected.skip(1)) {
        route.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(route, pathPaint);
    }

    _drawRoute(canvas, size);

    final sortedBuildings = [...CampusMapData.buildings]
      ..sort(
        (a, b) => (a.footprint.center.dx + a.footprint.center.dy).compareTo(
          b.footprint.center.dx + b.footprint.center.dy,
        ),
      );

    for (final building in sortedBuildings) {
      _drawBuilding(canvas, size, building);
    }

    for (final landmark in landmarks) {
      final normalized = _normalize(landmark.coordinate, CampusMapData.bounds);
      final point = _isoPoint(normalized, size);
      final isPickup = landmark.id == pickupId;
      final isDropoff = landmark.id == dropoffId;
      final color = isPickup
          ? const Color(0xFF60A5FA)
          : isDropoff
          ? Ce.warning
          : Ce.emerald500;

      canvas.drawCircle(
        point + const Offset(0, 2),
        isPickup || isDropoff ? 7 : 4,
        Paint()..color = Colors.black.withValues(alpha: 0.35),
      );
      canvas.drawCircle(
        point,
        isPickup || isDropoff ? 6 : 3.5,
        Paint()..color = color,
      );
      if (isPickup || isDropoff || _isMajor(landmark.id)) {
        _drawLabel(
          canvas,
          isPickup
              ? 'Jemput · ${landmark.name}'
              : isDropoff
              ? 'Antar · ${landmark.name}'
              : landmark.name,
          point + const Offset(8, -10),
          color: isPickup || isDropoff ? color : Ce.textMuted,
          bold: isPickup || isDropoff,
        );
      }
    }

    if (vehicle != null) {
      final point = _isoPoint(_normalize(vehicle!, CampusMapData.bounds), size);
      _drawVehicle(canvas, point, bearing);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Ce.emerald900.withValues(alpha: 0.28)
      ..strokeWidth = 0.6;
    for (var i = 1; i < 8; i++) {
      final t = i / 8;
      final start = _isoPoint(Offset(t, 0), size);
      final end = _isoPoint(Offset(t, 1), size);
      canvas.drawLine(start, end, grid);
      final start2 = _isoPoint(Offset(0, t), size);
      final end2 = _isoPoint(Offset(1, t), size);
      canvas.drawLine(start2, end2, grid);
    }
  }

  void _drawRoute(Canvas canvas, Size size) {
    final from = pickupId == null ? null : CampusMapData.coords[pickupId];
    final to = dropoffId == null ? null : CampusMapData.coords[dropoffId];
    if (from == null || to == null) return;
    final a = _isoPoint(_normalize(from, CampusMapData.bounds), size);
    final b = _isoPoint(_normalize(to, CampusMapData.bounds), size);
    final routePaint = Paint()
      ..color = Ce.emerald500
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final route = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(
        (a.dx + b.dx) / 2 + 20,
        (a.dy + b.dy) / 2 - 24,
        b.dx,
        b.dy,
      );
    canvas.drawPath(route, routePaint);
  }

  void _drawBuilding(Canvas canvas, Size size, CampusBuilding building) {
    final rect = building.footprint;
    final corners = <Offset>[
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.bottom),
      Offset(rect.left, rect.bottom),
    ];
    final ground = corners.map((corner) => _isoPoint(corner, size)).toList();
    final height = building.heightM / 55;
    final top = corners
        .map((corner) => _isoPoint(corner, size, height: height))
        .toList();

    // Sisi bangunan (dua sisi yang menghadap kamera).
    final sidePaint = Paint()..color = const Color(0xFF072A1E);
    final sidePaintLight = Paint()..color = const Color(0xFF0A3527);
    final faces = <List<Offset>>[
      [ground[1], ground[2], top[2], top[1]],
      [ground[2], ground[3], top[3], top[2]],
    ];
    for (var i = 0; i < faces.length; i++) {
      final face = Path()..moveTo(faces[i][0].dx, faces[i][0].dy);
      for (final point in faces[i].skip(1)) {
        face.lineTo(point.dx, point.dy);
      }
      face.close();
      canvas.drawPath(face, i == 0 ? sidePaintLight : sidePaint);
    }

    final roof = Path()..moveTo(top[0].dx, top[0].dy);
    for (final point in top.skip(1)) {
      roof.lineTo(point.dx, point.dy);
    }
    roof.close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF0C4632));
    canvas.drawPath(
      roof,
      Paint()
        ..color = Ce.emerald500.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawVehicle(Canvas canvas, Offset point, double bearing) {
    canvas.drawCircle(
      point + const Offset(0, 3),
      13,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      point,
      11,
      Paint()..color = Ce.emerald500.withValues(alpha: 0.22),
    );
    canvas.drawCircle(point, 7, Paint()..color = Ce.text);

    final angle = (bearing - 45) * math.pi / 180;
    final tip = point + Offset(math.cos(angle), math.sin(angle)) * 14;
    final left =
        point + Offset(math.cos(angle + 2.5), math.sin(angle + 2.5)) * 9;
    final right =
        point + Offset(math.cos(angle - 2.5), math.sin(angle - 2.5)) * 9;
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(arrow, Paint()..color = Ce.emerald500);
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset offset, {
    required Color color,
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: bold ? 10 : 8.5,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 150);
    painter.paint(canvas, offset);
  }

  bool _isMajor(String id) => const {
    'gedung-kuliah-terpadu',
    'masjid-kampus',
    'gate-utama',
    'kantin-pusat-b',
    'lapangan-utama',
  }.contains(id);

  @override
  bool shouldRepaint(covariant IsoMapPainter oldDelegate) {
    return oldDelegate.vehicle != vehicle ||
        oldDelegate.bearing != bearing ||
        oldDelegate.pickupId != pickupId ||
        oldDelegate.dropoffId != dropoffId;
  }
}

/// Fallback 2D Canvas (tech.md §5.8).
class FlatMapPainter extends CustomPainter {
  FlatMapPainter({
    required this.paths,
    required this.landmarks,
    required this.vehicle,
    required this.bearing,
    required this.bounds,
    this.pickupId,
    this.dropoffId,
  });

  final List<List<LatLng>> paths;
  final List<Landmark> landmarks;
  final LatLng? vehicle;
  final double bearing;
  final CampusBounds bounds;
  final String? pickupId;
  final String? dropoffId;

  Offset _project(LatLng coordinate, Size size) {
    final width = bounds.northeast.longitude - bounds.southwest.longitude;
    final height = bounds.northeast.latitude - bounds.southwest.latitude;
    return Offset(
      (coordinate.longitude - bounds.southwest.longitude) / width * size.width,
      (1 - (coordinate.latitude - bounds.southwest.latitude) / height) *
          size.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF061710),
    );

    final grid = Paint()
      ..color = Ce.emerald900.withValues(alpha: 0.35)
      ..strokeWidth = 0.6;
    for (var i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      final y = size.height * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final line = Paint()
      ..color = const Color(0xFF0B3B2C)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final path in paths) {
      if (path.isEmpty) continue;
      final projected = path.map((point) => _project(point, size)).toList();
      final drawPath = Path()..moveTo(projected.first.dx, projected.first.dy);
      for (final point in projected.skip(1)) {
        drawPath.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(drawPath, line);
    }

    final from = pickupId == null ? null : CampusMapData.coords[pickupId];
    final to = dropoffId == null ? null : CampusMapData.coords[dropoffId];
    if (from != null && to != null) {
      final a = _project(from, size);
      final b = _project(to, size);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = Ce.emerald500
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final landmark in landmarks) {
      final point = _project(landmark.coordinate, size);
      final isPickup = landmark.id == pickupId;
      final isDropoff = landmark.id == dropoffId;
      canvas.drawCircle(
        point,
        isPickup || isDropoff ? 6 : 3.5,
        Paint()
          ..color = isPickup
              ? const Color(0xFF60A5FA)
              : isDropoff
              ? Ce.warning
              : Ce.emerald600,
      );
      if (isPickup || isDropoff || landmark.id == 'gedung-kuliah-terpadu') {
        final painter = TextPainter(
          text: TextSpan(
            text: landmark.name,
            style: const TextStyle(color: Ce.textMuted, fontSize: 8.5),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: 110);
        painter.paint(canvas, point + const Offset(7, -8));
      }
    }

    if (vehicle != null) {
      final point = _project(vehicle!, size);
      canvas.drawCircle(
        point,
        10,
        Paint()..color = Ce.emerald500.withValues(alpha: 0.25),
      );
      canvas.drawCircle(point, 6, Paint()..color = Ce.text);
      final angle = (bearing - 90) * math.pi / 180;
      canvas.drawLine(
        point,
        point + Offset(math.cos(angle), math.sin(angle)) * 14,
        Paint()
          ..color = Ce.emerald500
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FlatMapPainter oldDelegate) {
    return oldDelegate.vehicle != vehicle ||
        oldDelegate.bearing != bearing ||
        oldDelegate.pickupId != pickupId ||
        oldDelegate.dropoffId != dropoffId;
  }
}
