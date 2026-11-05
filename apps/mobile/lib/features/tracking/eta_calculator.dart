import 'dart:math' as math;

class Edge {
  const Edge(this.to, this.meters);

  final String to;
  final double meters;
}

class PathResult {
  const PathResult(this.nodes, this.meters);

  final List<String> nodes;
  final double meters;
}

/// Graf landmark kampus + Dijkstra (docs/tech.md §5.4).
class LandmarkGraph {
  LandmarkGraph(this.adj);

  final Map<String, List<Edge>> adj;
  final Map<String, PathResult> _cache = {};

  factory LandmarkGraph.fromConfig(Map<String, dynamic> json) {
    final adj = <String, List<Edge>>{};
    for (final raw in (json['edges'] as List).cast<Map<String, dynamic>>()) {
      final a = raw['a'] as String;
      final b = raw['b'] as String;
      final meters = (raw['meters'] as num).toDouble();
      (adj[a] ??= []).add(Edge(b, meters));
      (adj[b] ??= []).add(Edge(a, meters));
    }
    return LandmarkGraph(adj);
  }

  factory LandmarkGraph.fromEdges(Iterable<EdgeSpec> edges) {
    final adj = <String, List<Edge>>{};
    for (final edge in edges) {
      (adj[edge.a] ??= []).add(Edge(edge.b, edge.meters));
      (adj[edge.b] ??= []).add(Edge(edge.a, edge.meters));
    }
    return LandmarkGraph(adj);
  }

  PathResult shortest(String from, String to) {
    if (from == to) return PathResult([from], 0);

    final cacheKey = '$from>$to';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final dist = <String, double>{
      for (final node in adj.keys) node: double.infinity,
    };
    final previous = <String, String>{};
    final open = adj.keys.toSet();
    dist[from] = 0;

    while (open.isNotEmpty) {
      String? current;
      for (final node in open) {
        if (current == null || dist[node]! < dist[current]!) current = node;
      }
      if (current == null || dist[current]!.isInfinite) break;
      if (current == to) break;
      open.remove(current);
      for (final edge in adj[current] ?? const <Edge>[]) {
        final alternative = dist[current]! + edge.meters;
        if (alternative < (dist[edge.to] ?? double.infinity)) {
          dist[edge.to] = alternative;
          previous[edge.to] = current;
        }
      }
    }

    if ((dist[to] ?? double.infinity).isInfinite) {
      throw StateError('NO_PATH:$from->$to');
    }

    final nodes = <String>[to];
    while (nodes.first != from) {
      final parent = previous[nodes.first];
      if (parent == null) throw StateError('NO_PATH:$from->$to');
      nodes.insert(0, parent);
    }

    final result = PathResult(nodes, dist[to]!);
    _cache[cacheKey] = result;
    return result;
  }
}

class EdgeSpec {
  const EdgeSpec(this.a, this.b, this.meters);

  final String a;
  final String b;
  final double meters;
}

const minMps = 10 / 3.6;
const maxMps = 30 / 3.6;

/// Kecepatan terkoreksi: v ← clamp(0,7·v + 0,3·v_obs, 2,78, 8,33).
class SpeedEstimator {
  SpeedEstimator(double kmh) : mps = kmh / 3.6;

  double mps;

  void observe(double meters, double seconds) {
    if (seconds <= 0 || meters <= 0) return;
    final observed = (meters / seconds).clamp(minMps, maxMps).toDouble();
    mps = (0.7 * mps + 0.3 * observed).clamp(minMps, maxMps).toDouble();
  }
}

class EtaInput {
  const EtaInput({
    required this.current,
    required this.pickup,
    required this.dropoff,
    required this.pickedUp,
    required this.now,
    required this.speedMps,
    this.prepReadyAt,
    this.waitBufferSec = 0,
  });

  final String current;
  final String pickup;
  final String dropoff;
  final bool pickedUp;
  final DateTime now;
  final DateTime? prepReadyAt;
  final double speedMps;
  final int waitBufferSec;
}

class EtaResult {
  const EtaResult({
    required this.eta,
    required this.travelSeconds,
    required this.waitSeconds,
    required this.distanceMeters,
  });

  final DateTime eta;
  final int travelSeconds;
  final int waitSeconds;
  final double distanceMeters;
}

DateTime computeEta(LandmarkGraph graph, EtaInput input) {
  return computeEtaDetailed(graph, input).eta;
}

EtaResult computeEtaDetailed(LandmarkGraph graph, EtaInput input) {
  Duration travel(double meters) =>
      Duration(milliseconds: (meters / input.speedMps * 1000).round());

  if (input.pickedUp) {
    final path = graph.shortest(input.current, input.dropoff);
    final duration = travel(path.meters);
    return EtaResult(
      eta: input.now.add(duration),
      travelSeconds: duration.inSeconds,
      waitSeconds: 0,
      distanceMeters: path.meters,
    );
  }

  final toPickup = graph.shortest(input.current, input.pickup);
  final pickupTravel = travel(toPickup.meters);
  final arrive = input.now.add(pickupTravel);
  final ready =
      input.prepReadyAt ?? arrive.add(Duration(seconds: input.waitBufferSec));
  final depart = ready.isAfter(arrive) ? ready : arrive;
  final toDropoff = graph.shortest(input.pickup, input.dropoff);
  final dropoffTravel = travel(toDropoff.meters);
  final waitSeconds = depart.difference(arrive).inSeconds;

  return EtaResult(
    eta: depart.add(dropoffTravel),
    travelSeconds: pickupTravel.inSeconds + dropoffTravel.inSeconds,
    waitSeconds: waitSeconds < 0 ? 0 : waitSeconds,
    distanceMeters: toPickup.meters + toDropoff.meters,
  );
}

/// Buffer penyiapan default per layanan (PRD §5.2).
int defaultPrepBufferSec(String orderType) {
  switch (orderType) {
    case 'jastip':
      return 480;
    case 'paket':
      return 120;
    case 'numpang':
      return 0;
    default:
      return 0;
  }
}

String formatEta(Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes <= 0) return '< 1 menit';
  if (minutes < 60) return '$minutes menit';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours jam' : '$hours jam $rest menit';
}

double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = _radians(lat2 - lat1);
  final dLon = _radians(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radians(lat1)) *
          math.cos(_radians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double bearingDegrees(double lat1, double lon1, double lat2, double lon2) {
  final phi1 = _radians(lat1);
  final phi2 = _radians(lat2);
  final deltaLambda = _radians(lon2 - lon1);
  final y = math.sin(deltaLambda) * math.cos(phi2);
  final x =
      math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

double _radians(double degrees) => degrees * math.pi / 180;
