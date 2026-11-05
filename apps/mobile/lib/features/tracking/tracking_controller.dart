import 'dart:math' as math;

import '../../core/config/app_config.dart';
import 'eta_calculator.dart';

class Pose {
  const Pose(this.position, this.bearing);

  final LatLng position;
  final double bearing;
}

class SegmentAnimator {
  SegmentAnimator({
    required this.polyline,
    required this.start,
    required this.durationSec,
  }) : _cumulative = _cumulativeDistances(polyline);

  final List<LatLng> polyline;
  final DateTime start;
  final double durationSec;
  final List<double> _cumulative;

  Pose at(DateTime now) {
    if (polyline.isEmpty) {
      return const Pose(LatLng(0, 0), 0);
    }
    if (polyline.length == 1 || durationSec <= 0) {
      return Pose(polyline.first, 0);
    }
    final progress = (now.difference(start).inMilliseconds / 1000 / durationSec)
        .clamp(0.0, 0.95);
    final target = _cumulative.last * progress;
    var index = 1;
    while (index < _cumulative.length - 1 && _cumulative[index] < target) {
      index++;
    }
    final segment = _cumulative[index] - _cumulative[index - 1];
    final t = segment == 0 ? 0.0 : (target - _cumulative[index - 1]) / segment;
    final a = polyline[index - 1];
    final b = polyline[index];
    return Pose(
      LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      ),
      bearingDegrees(a.latitude, a.longitude, b.latitude, b.longitude),
    );
  }

  static List<double> _cumulativeDistances(List<LatLng> points) {
    final out = <double>[0];
    for (var i = 1; i < points.length; i++) {
      out.add(
        out.last +
            haversineMeters(
              points[i - 1].latitude,
              points[i - 1].longitude,
              points[i].latitude,
              points[i].longitude,
            ),
      );
    }
    return out;
  }
}

/// Pengontrol animasi posisi driver di sepanjang segmen jalur.
class TrackingController {
  TrackingController(this.graph, this.speed);

  final LandmarkGraph graph;
  final SpeedEstimator speed;
  SegmentAnimator? _animation;
  String? _lastNode;
  DateTime? _lastAt;

  SegmentAnimator? get animation => _animation;

  void onCheckpoint({
    required String from,
    required String to,
    required DateTime at,
    required Map<String, LatLng> coords,
  }) {
    if (_lastNode != null && _lastAt != null) {
      final meters = graph.shortest(_lastNode!, from).meters;
      final seconds = at.difference(_lastAt!).inSeconds.toDouble();
      speed.observe(meters, seconds);
    }

    final path = graph.shortest(from, to);
    final polyline = <LatLng>[
      for (final node in path.nodes)
        if (coords[node] != null) coords[node]!,
    ];
    if (polyline.isEmpty) return;

    _animation = SegmentAnimator(
      polyline: polyline,
      start: at,
      durationSec: math.max(1, path.meters / speed.mps),
    );
    _lastNode = to;
    _lastAt = at;
  }

  void onTracking(Map<String, dynamic> tracking, Map<String, LatLng> coords) {
    final from =
        (tracking['segmentFrom'] as String?) ??
        (tracking['segment_from'] as String?);
    final to =
        (tracking['segmentTo'] as String?) ??
        (tracking['segment_to'] as String?);
    final checkpoint = tracking['checkpointAt'] ?? tracking['checkpoint_at'];
    final at = checkpoint is DateTime ? checkpoint : DateTime.now();
    if (from == null || to == null) return;
    onCheckpoint(from: from, to: to, at: at, coords: coords);
  }

  Pose? pose(DateTime now) => _animation?.at(now);

  void reset() {
    _animation = null;
    _lastNode = null;
    _lastAt = null;
  }
}
