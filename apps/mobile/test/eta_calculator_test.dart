import 'package:campus_express/features/tracking/eta_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ETA calculator', () {
    test('1.200 m pada 20 km/jam tepat 216 detik', () {
      final graph = LandmarkGraph.fromEdges([
        const EdgeSpec('gate-utama', 'gedung-kuliah-terpadu', 1200),
      ]);
      final now = DateTime(2026, 1, 1, 12);
      final result = computeEtaDetailed(
        graph,
        EtaInput(
          current: 'gate-utama',
          pickup: 'gate-utama',
          dropoff: 'gedung-kuliah-terpadu',
          pickedUp: true,
          now: now,
          speedMps: 20 / 3.6,
        ),
      );

      expect(result.travelSeconds, 216);
      expect(result.eta.difference(now).inSeconds, 216);
      expect(result.distanceMeters, 1200);
      expect(result.waitSeconds, 0);
    });

    test('Dijkstra memilih jalur terpendek, bukan jalur langsung', () {
      final graph = LandmarkGraph.fromEdges([
        const EdgeSpec('a', 'b', 1000),
        const EdgeSpec('a', 'c', 300),
        const EdgeSpec('c', 'b', 300),
      ]);

      final path = graph.shortest('a', 'b');

      expect(path.meters, 600);
      expect(path.nodes, ['a', 'c', 'b']);
    });

    test('buffer persiapan jastip menambah waitSeconds', () {
      final graph = LandmarkGraph.fromEdges([
        const EdgeSpec('a', 'b', 600),
        const EdgeSpec('b', 'c', 600),
      ]);
      final now = DateTime(2026, 1, 1, 12);
      final result = computeEtaDetailed(
        graph,
        EtaInput(
          current: 'a',
          pickup: 'b',
          dropoff: 'c',
          pickedUp: false,
          now: now,
          speedMps: 20 / 3.6,
          waitBufferSec: defaultPrepBufferSec('jastip'),
        ),
      );

      expect(result.waitSeconds, 480);
      expect(result.travelSeconds, 216);
      expect(result.distanceMeters, 1200);
      expect(result.eta.difference(now).inSeconds, 696);
    });
  });
}
