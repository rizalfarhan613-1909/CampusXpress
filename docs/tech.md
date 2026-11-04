# tech.md — Spesifikasi Teknis Campus Express

Dokumen implementasi untuk pengembang. Semua kode adalah titik awal yang dapat dijalankan setelah penyesuaian konfigurasi proyek; versi paket harus diverifikasi terhadap dokumentasi resmi saat setup karena API dapat berubah.

## 1. Prasyarat dan Versi

| Alat | Versi target | Catatan |
|---|---|---|
| Flutter | Stable terbaru | Android minSdk 24 (Android 7) |
| Dart | Sesuai Flutter | Null safety |
| Node.js | LTS terbaru | Untuk Next.js dan Gateway |
| Next.js | 15.x | App Router, static export |
| Tailwind CSS | 3.4 atau 4 | Token warna di §6.1 |
| Firebase CLI | Terbaru | Emulator Firestore dan Auth |
| Wrangler | Terbaru | Deploy Workers |
| TypeScript | 5.x | `strict: true` |

## 2. Struktur Repo (Monorepo)

```
campus-express/
├─ apps/
│  ├─ mobile/                 Flutter
│  └─ web/                    Next.js (landing, merchant, admin)
├─ services/
│  └─ gateway/                Cloudflare Worker (TypeScript)
├─ firebase/
│  ├─ firestore.rules
│  ├─ firestore.indexes.json
│  └─ firebase.json
├─ assets/
│  ├─ map/                    campus-map.geojson, landmarks.json, vehicle sprites
│  └─ design/                 token warna, ekspor Stitch
├─ tools/
│  ├─ migrations/
│  └─ seed/
├─ docs/                      13 dokumen ini
└─ .github/workflows/
```

### 2.1 Struktur Flutter (feature-first)

```
apps/mobile/lib/
├─ main.dart
├─ app/
│  ├─ app.dart
│  ├─ router.dart
│  └─ theme.dart
├─ core/
│  ├─ firebase/            firestore_paths.dart, app_check.dart
│  ├─ gateway/             gateway_client.dart
│  ├─ config/              app_config.dart (config/app realtime)
│  ├─ image/               webp_compress.dart
│  └─ widgets/             bento_card.dart, skeleton.dart, error_state.dart
├─ features/
│  ├─ auth/                (layar 1, 2)
│  ├─ home/                (3)
│  ├─ landmarks/           (4)
│  ├─ catalog/             (5, 6)
│  ├─ checkout/            (7)
│  ├─ tracking/            (8)  ← map/, eta/
│  ├─ driver/              (9, 10, 11, 20)
│  ├─ merchant/            (12, 13, 17, 21)
│  ├─ chat/                (16)
│  ├─ orders/              (18, 19)
│  ├─ profile/             (14)
│  ├─ admin/               (15)
│  └─ support/             (22)
└─ l10n/                   app_id.arb
```

## 3. Setup Flutter

### 3.1 `pubspec.yaml` (dependensi inti)

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: any
  firebase_auth: any
  cloud_firestore: any
  firebase_messaging: any
  firebase_app_check: any
  firebase_remote_config: any
  google_sign_in: any
  flutter_riverpod: any
  go_router: any
  freezed_annotation: any
  json_annotation: any
  maplibre_gl: any
  flutter_image_compress: any
  device_info_plus: any
  http: any
  uuid: any
  intl: any
  cached_network_image: any

dev_dependencies:
  build_runner: any
  freezed: any
  json_serializable: any
  flutter_test:
    sdk: flutter
  mocktail: any
```

Ganti `any` dengan versi pasti (pin) saat setup dan commit `pubspec.lock`.

### 3.2 `main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
    appleProvider: kReleaseMode ? AppleProvider.appAttest : AppleProvider.debug,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 50 * 1024 * 1024,
  );
  runApp(const ProviderScope(child: CampusExpressApp()));
}
```

### 3.3 Tema (`theme.dart`)

```dart
class Ce {
  static const emerald500 = Color(0xFF059669);
  static const emerald600 = Color(0xFF047857);
  static const emerald900 = Color(0xFF064E3B);
  static const bg = Color(0xFF04130E);
  static const surface = Color(0xFF0A2219);
  static const text = Color(0xFFECFDF5);
  static const radiusBento = 20.0;
  static const gap = 12.0;
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Ce.emerald500,
    brightness: Brightness.dark,
  ).copyWith(
    primary: Ce.emerald500,
    secondary: Ce.emerald600,
    surface: Ce.surface,
    onSurface: Ce.text,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Ce.bg,
    cardTheme: CardThemeData(
      color: Ce.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Ce.radiusBento)),
    ),
  );
}
```

### 3.4 Router dengan Penjaga Peran

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefresh(ref.watch(authStateProvider.stream)),
    redirect: (context, state) {
      final user = auth.valueOrNull;
      final loc = state.matchedLocation;
      if (user == null) return loc == '/auth' || loc == '/' ? null : '/auth';
      if (!user.profileComplete) return loc == '/auth/profile' ? null : '/auth/profile';
      if (loc.startsWith('/driver') && !user.claims.driver) return '/';
      if (loc.startsWith('/merchant') && user.claims.merchantId == null) return '/';
      if (loc.startsWith('/admin') && !user.claims.admin) return '/';
      return null;
    },
    routes: appRoutes,
  );
});
```

Penjaga router hanya UX; otorisasi sebenarnya di Rules dan Gateway.

### 3.5 Klien Gateway

```dart
class GatewayClient {
  GatewayClient(this._auth, this._base);
  final FirebaseAuth _auth;
  final String _base;

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? body]) async {
    final token = await _auth.currentUser!.getIdToken();
    final appCheck = await FirebaseAppCheck.instance.getToken();
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Firebase-AppCheck': appCheck ?? '',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body ?? {}),
    );
    final json = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) throw GatewayException(res.statusCode, json['code'] as String? ?? 'ERROR');
    return json;
  }
}
```

### 3.6 Kompresi Gambar WebP ≤ 80 KB

```dart
Future<Uint8List> compressToWebp(String path, {int maxBytes = 80 * 1024}) async {
  var quality = 80;
  var side = 1280;
  while (true) {
    final out = await FlutterImageCompress.compressWithFile(
      path,
      format: CompressFormat.webp,
      quality: quality,
      minWidth: side,
      minHeight: side,
      keepExif: false,
    );
    if (out == null) throw const ImageCompressException();
    if (out.length <= maxBytes) return out;
    if (quality > 40) {
      quality -= 10;
    } else if (side > 640) {
      side = (side * 0.8).round();
      quality = 60;
    } else {
      throw const ImageTooLargeException();
    }
  }
}
```

Unggah: `PUT {gateway}/upload/{kind}` dengan `Content-Type: image/webp`; respons `{ "key": "<objectKey>" }`.

## 4. Modul In-App Chat (Flutter)

### 4.1 Model

```dart
enum MessageType { text, chip, image, system }

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String senderUid,
    required MessageType type,
    String? text,
    String? imageKey,
    DateTime? createdAt,
    @Default(<String>[]) List<String> readBy,
    @Default(false) bool flagged,
    @Default(false) bool pending,
  }) = _ChatMessage;
}
```

### 4.2 Repository

```dart
class ChatRepository {
  ChatRepository(this._db, this._auth);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final List<DateTime> _sent = [];

  CollectionReference<Map<String, dynamic>> _messages(String orderId) =>
      _db.collection('chats').doc(orderId).collection('messages');

  Stream<List<ChatMessage>> watch(String orderId, {int limit = 30}) {
    return _messages(orderId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        .map((s) => s.docs.map((d) => _fromDoc(d)).toList());
  }

  Future<void> send(String orderId, {required MessageType type, String? text, String? imageKey}) async {
    _throttle();
    final uid = _auth.currentUser!.uid;
    final id = const Uuid().v4();
    final data = <String, dynamic>{
      'senderUid': uid,
      'type': type.name,
      'clientId': id,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [uid],
      'flagged': false,
      'expireAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      if (text != null) 'text': text.trim(),
      if (imageKey != null) 'imageKey': imageKey,
    };
    await _messages(orderId).doc(id).set(data);
  }

  void _throttle() {
    final now = DateTime.now();
    _sent.removeWhere((t) => now.difference(t) > const Duration(minutes: 1));
    if (_sent.length >= 20) throw const ChatRateLimitException();
    _sent.add(now);
  }

  Future<void> markRead(String orderId, List<String> messageIds) async {
    final uid = _auth.currentUser!.uid;
    final batch = _db.batch();
    for (final id in messageIds.take(20)) {
      batch.update(_messages(orderId).doc(id), {'readBy': FieldValue.arrayUnion([uid])});
    }
    await batch.commit();
  }

  Future<void> report(String orderId, String messageId, String reason) =>
      GatewayClient.instance.post('/chat/report', {'orderId': orderId, 'messageId': messageId, 'reason': reason});
}
```

ID dokumen = `clientId` sehingga pengiriman ulang pada koneksi buruk tidak menggandakan pesan (percobaan kedua ditolak rules sebagai update ilegal dan dianggap berhasil oleh klien).

### 4.3 Quick Chips

```dart
const consumerChips = [
  'Saya sudah di titik',
  'Tolong tunggu 2 menit',
  'Pesanan sudah benar?',
];
const driverChips = [
  'Saya sudah tiba',
  'Sedang antre di kedai',
  'Titik ini sulit, boleh pindah?',
];
```

### 4.4 Perilaku UI

| Aspek | Implementasi |
|---|---|
| Daftar | `ListView.builder(reverse: true)`, paginasi 30 pesan, tombol "muat lebih lama" menambah `limit` 30 |
| Pesan tertunda | `metadata.hasPendingWrites` → ikon jam |
| Read-only | Jika `chats/{id}.status != 'open'`, input diganti banner |
| Peringatan privasi | Regex nomor telepon pada teks yang diketik menampilkan banner sebelum kirim |
| Tautan | Tidak diubah menjadi tautan aktif; ketuk menampilkan konfirmasi domain |
| Gambar | Dikompres (§3.6), diunggah ke Gateway, pesan memuat `imageKey`; tampil lewat URL bertanda tangan |
| Notifikasi | FCM data message berisi `orderId` dan `type: chat`; badge dihitung lokal |

### 4.5 TTL Pesan

```bash
gcloud firestore fields ttls update expireAt \
  --collection-group=messages --enable-ttl --project=campus-express-prod
```

Penghapusan TTL berjalan di latar belakang dan tidak instan; chat tidak boleh bergantung padanya untuk privasi mendesak (gunakan penghapusan manual admin).

## 5. Peta 3D Isometrik dan ETA

### 5.1 Aset Peta (R2 publik)

| Berkas | Isi |
|---|---|
| `campus-map.v3.geojson` | FeatureCollection: `Polygon` bangunan (`height_m`, `name`), `LineString` jalur (`edge_id`) |
| `landmarks.v3.json` | `[{id, name, lat, lng, type, zoneId}]` |
| `vehicle-motor.png` | Sprite isometrik 128×128 (hasil render GLTF) |
| `vehicle-motor.glb` | Model GLTF untuk varian Three.js web |

Nama berkas memuat versi sehingga cache dapat `immutable` selama 7 hari.

### 5.2 Gaya MapLibre (tanpa tile eksternal)

```dart
String buildStyle(String mapUrl) => jsonEncode({
  'version': 8,
  'sources': {
    'campus': {'type': 'geojson', 'data': mapUrl},
    'vehicle': {'type': 'geojson', 'data': {'type': 'FeatureCollection', 'features': []}},
    'route': {'type': 'geojson', 'data': {'type': 'FeatureCollection', 'features': []}},
  },
  'layers': [
    {'id': 'bg', 'type': 'background', 'paint': {'background-color': '#04130E'}},
    {
      'id': 'paths', 'type': 'line', 'source': 'campus',
      'filter': ['==', ['geometry-type'], 'LineString'],
      'paint': {'line-color': '#0B3B2C', 'line-width': 4},
    },
    {
      'id': 'route', 'type': 'line', 'source': 'route',
      'paint': {'line-color': '#059669', 'line-width': 5, 'line-opacity': 0.9},
    },
    {
      'id': 'buildings', 'type': 'fill-extrusion', 'source': 'campus',
      'filter': ['==', ['geometry-type'], 'Polygon'],
      'paint': {
        'fill-extrusion-color': '#064E3B',
        'fill-extrusion-height': ['get', 'height_m'],
        'fill-extrusion-base': 0,
        'fill-extrusion-opacity': 0.95,
      },
    },
    {
      'id': 'vehicle', 'type': 'symbol', 'source': 'vehicle',
      'layout': {
        'icon-image': 'vehicle',
        'icon-size': 0.5,
        'icon-allow-overlap': true,
        'icon-rotation-alignment': 'map',
        'icon-rotate': ['get', 'bearing'],
      },
    },
  ],
});
```

### 5.3 Widget Peta

```dart
class IsoMapView extends StatefulWidget {
  const IsoMapView({super.key, required this.controller});
  final TrackingController controller;
  @override
  State<IsoMapView> createState() => _IsoMapViewState();
}

class _IsoMapViewState extends State<IsoMapView> with SingleTickerProviderStateMixin {
  MapLibreMapController? _map;
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (elapsed - _last < const Duration(milliseconds: 33)) return;
      _last = elapsed;
      _pushVehicle();
    })..start();
  }

  Future<void> _onStyleLoaded() async {
    final bytes = (await rootBundle.load('assets/map/vehicle-motor.png')).buffer.asUint8List();
    await _map!.addImage('vehicle', bytes);
  }

  void _pushVehicle() {
    final m = _map;
    final pose = widget.controller.pose(DateTime.now());
    if (m == null || pose == null) return;
    m.setGeoJsonSource('vehicle', {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {'bearing': pose.bearing},
          'geometry': {'type': 'Point', 'coordinates': [pose.position.longitude, pose.position.latitude]},
        }
      ],
    });
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: buildStyle(AppConfig.mapUrl),
      initialCameraPosition: CameraPosition(
        target: AppConfig.campusCenter,
        zoom: 16.5,
        tilt: 60,
        bearing: 45,
      ),
      onMapCreated: (c) => _map = c,
      onStyleLoadedCallback: _onStyleLoaded,
      compassEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      attributionButtonMargins: const Point(-100, -100),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
```

Catatan implementasi: nama parameter dan metode `maplibre_gl` (`setGeoJsonSource`, `addImage`, opsi kamera) mengikuti versi paket yang dipakai; verifikasi pada setup. Dukungan layer GLTF kustom tidak diasumsikan, itulah sebabnya kendaraan memakai sprite.

### 5.4 Graf Landmark dan Dijkstra

```dart
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

class LandmarkGraph {
  LandmarkGraph(this.adj);
  final Map<String, List<Edge>> adj;

  factory LandmarkGraph.fromConfig(Map<String, dynamic> json) {
    final adj = <String, List<Edge>>{};
    for (final e in (json['edges'] as List).cast<Map<String, dynamic>>()) {
      final a = e['a'] as String, b = e['b'] as String;
      final m = (e['meters'] as num).toDouble();
      (adj[a] ??= []).add(Edge(b, m));
      (adj[b] ??= []).add(Edge(a, m));
    }
    return LandmarkGraph(adj);
  }

  PathResult shortest(String from, String to) {
    if (from == to) return PathResult([from], 0);
    final dist = <String, double>{for (final k in adj.keys) k: double.infinity};
    final prev = <String, String>{};
    final open = adj.keys.toSet();
    dist[from] = 0;
    while (open.isNotEmpty) {
      String? u;
      for (final n in open) {
        if (u == null || dist[n]! < dist[u]!) u = n;
      }
      if (u == null || dist[u]!.isInfinite) break;
      if (u == to) break;
      open.remove(u);
      for (final e in adj[u]!) {
        final alt = dist[u]! + e.meters;
        if (alt < dist[e.to]!) {
          dist[e.to] = alt;
          prev[e.to] = u;
        }
      }
    }
    if (dist[to]!.isInfinite) throw StateError('NO_PATH:$from->$to');
    final nodes = <String>[to];
    while (nodes.first != from) {
      nodes.insert(0, prev[nodes.first]!);
    }
    return PathResult(nodes, dist[to]!);
  }
}
```

Dengan ≤ 60 simpul, kompleksitas O(V²) cukup; hasil jalur antar-landmark yang sering dipakai dapat di-cache dalam `Map<String, PathResult>`.

### 5.5 Kalkulator ETA

```dart
const _minMps = 10 / 3.6;
const _maxMps = 30 / 3.6;

class SpeedEstimator {
  SpeedEstimator(double kmh) : mps = kmh / 3.6;
  double mps;

  void observe(double meters, double seconds) {
    if (seconds <= 0 || meters <= 0) return;
    final observed = (meters / seconds).clamp(_minMps, _maxMps).toDouble();
    mps = (0.7 * mps + 0.3 * observed).clamp(_minMps, _maxMps).toDouble();
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
  final String current, pickup, dropoff;
  final bool pickedUp;
  final DateTime now;
  final DateTime? prepReadyAt;
  final double speedMps;
  final int waitBufferSec;
}

DateTime computeEta(LandmarkGraph g, EtaInput i) {
  Duration travel(double meters) => Duration(milliseconds: (meters / i.speedMps * 1000).round());

  if (i.pickedUp) {
    return i.now.add(travel(g.shortest(i.current, i.dropoff).meters));
  }
  final arrive = i.now.add(travel(g.shortest(i.current, i.pickup).meters));
  final ready = i.prepReadyAt ?? arrive.add(Duration(seconds: i.waitBufferSec));
  final depart = ready.isAfter(arrive) ? ready : arrive;
  return depart.add(travel(g.shortest(i.pickup, i.dropoff).meters));
}
```

`waitBufferSec`: 480 untuk jastip, 120 untuk paket, 0 untuk numpang; untuk umkm memakai `prepReadyAt`.

Tes numerik: 1.200 m pada 20 km/jam → 216 detik.

```dart
test('ETA 1200 m @ 20 km/jam = 216 dtk', () {
  final g = LandmarkGraph({'A': [const Edge('B', 1200)], 'B': [const Edge('A', 1200)]});
  final now = DateTime.utc(2026, 1, 1);
  final eta = computeEta(g, EtaInput(
    current: 'A', pickup: 'A', dropoff: 'B', pickedUp: false, now: now, speedMps: 20 / 3.6,
  ));
  expect(eta.difference(now).inSeconds, 216);
});
```

### 5.6 Animasi Posisi

```dart
class Pose {
  const Pose(this.position, this.bearing);
  final LatLng position;
  final double bearing;
}

class SegmentAnimator {
  SegmentAnimator({required this.polyline, required this.start, required this.durationSec})
      : _cum = _cumulative(polyline);
  final List<LatLng> polyline;
  final DateTime start;
  final double durationSec;
  final List<double> _cum;

  Pose at(DateTime now) {
    final p = (now.difference(start).inMilliseconds / 1000 / durationSec).clamp(0.0, 0.95);
    final target = _cum.last * p;
    var i = 1;
    while (i < _cum.length - 1 && _cum[i] < target) {
      i++;
    }
    final seg = _cum[i] - _cum[i - 1];
    final t = seg == 0 ? 0.0 : (target - _cum[i - 1]) / seg;
    final a = polyline[i - 1], b = polyline[i];
    return Pose(
      LatLng(a.latitude + (b.latitude - a.latitude) * t, a.longitude + (b.longitude - a.longitude) * t),
      _bearing(a, b),
    );
  }

  static List<double> _cumulative(List<LatLng> pts) {
    final out = <double>[0];
    for (var k = 1; k < pts.length; k++) {
      out.add(out.last + _haversine(pts[k - 1], pts[k]));
    }
    return out;
  }
}
```

`_haversine` mengembalikan meter, `_bearing` derajat 0–360 (rumus standar). Batas 0,95 menahan marker sebelum landmark sampai driver mengonfirmasi checkpoint.

### 5.7 Pengontrol Pelacakan

```dart
class TrackingController {
  TrackingController(this.graph, this.speed);
  final LandmarkGraph graph;
  final SpeedEstimator speed;
  SegmentAnimator? _anim;
  String? _lastNode;
  DateTime? _lastAt;

  void onTracking(Map<String, dynamic> t, Map<String, LatLng> coords) {
    final from = t['segmentFrom'] as String;
    final to = t['segmentTo'] as String;
    final at = (t['checkpointAt'] as Timestamp).toDate();
    if (_lastNode != null && _lastAt != null && _lastNode == from) {
      final m = graph.shortest(from, _lastNode!).meters;
      speed.observe(m, at.difference(_lastAt!).inSeconds.toDouble());
    }
    final path = graph.shortest(from, to);
    final poly = [for (final n in path.nodes) coords[n]!];
    _anim = SegmentAnimator(
      polyline: poly,
      start: at,
      durationSec: path.meters / speed.mps,
    );
    _lastNode = to;
    _lastAt = at;
  }

  Pose? pose(DateTime now) => _anim?.at(now);
}
```

### 5.8 Render 2D (Fallback)

```dart
class FlatMapPainter extends CustomPainter {
  FlatMapPainter({required this.paths, required this.landmarks, required this.vehicle, required this.bounds});
  final List<List<LatLng>> paths;
  final List<LatLng> landmarks;
  final LatLng? vehicle;
  final LatLngBounds bounds;

  Offset _p(LatLng c, Size s) => Offset(
        (c.longitude - bounds.southwest.longitude) / (bounds.northeast.longitude - bounds.southwest.longitude) * s.width,
        (1 - (c.latitude - bounds.southwest.latitude) / (bounds.northeast.latitude - bounds.southwest.latitude)) * s.height,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFF059669)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final path in paths) {
      final p = Path()..moveTo(_p(path.first, size).dx, _p(path.first, size).dy);
      for (final c in path.skip(1)) {
        final o = _p(c, size);
        p.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(p, line);
    }
    final dot = Paint()..color = const Color(0xFF047857);
    for (final l in landmarks) {
      canvas.drawCircle(_p(l, size), 5, dot);
    }
    if (vehicle != null) {
      canvas.drawCircle(_p(vehicle!, size), 8, Paint()..color = const Color(0xFFECFDF5));
    }
  }

  @override
  bool shouldRepaint(covariant FlatMapPainter old) => old.vehicle != vehicle;
}
```

### 5.9 Pemilihan Mode Render

```dart
enum RenderMode { iso3d, flat2d }

class RenderModeController extends ChangeNotifier {
  RenderMode mode = RenderMode.iso3d;
  bool forced = false;
  int _slow = 0;

  Future<void> init({required bool userBatterySaver}) async {
    if (userBatterySaver) return _set(RenderMode.flat2d, forced: true);
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.isLowRamDevice) return _set(RenderMode.flat2d);
    }
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> t) {
    if (forced || mode == RenderMode.flat2d) return;
    final slow = t.where((f) => f.totalSpan.inMilliseconds > 42).length;
    _slow = slow > t.length / 2 ? _slow + 1 : 0;
    if (_slow >= 3) _set(RenderMode.flat2d);
  }

  void _set(RenderMode m, {bool forced = false}) {
    mode = m;
    this.forced = forced;
    notifyListeners();
  }
}
```

Deviasi dari PRD §5.4: total RAM tidak tersedia lintas-platform tanpa kode native, jadi implementasi awal memakai `isLowRamDevice`, pemantauan FPS (frame > 42 ms ≈ < 24 fps), dan opsi pengguna. Ambang RAM 4 GB dapat ditambahkan lewat platform channel bila uji perangkat menunjukkan perlu.

### 5.10 Varian Web (Three.js)

```tsx
'use client';
import { useEffect, useRef } from 'react';
import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';

export function webglAvailable() {
  try {
    const c = document.createElement('canvas');
    return !!(c.getContext('webgl2') || c.getContext('webgl'));
  } catch {
    return false;
  }
}

export function IsoScene({ mapUrl, modelUrl }: { mapUrl: string; modelUrl: string }) {
  const host = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const el = host.current!;
    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.setSize(el.clientWidth, el.clientHeight);
    el.appendChild(renderer.domElement);

    const scene = new THREE.Scene();
    const aspect = el.clientWidth / el.clientHeight;
    const s = 120;
    const camera = new THREE.OrthographicCamera(-s * aspect, s * aspect, s, -s, 0.1, 1000);
    camera.position.set(150, 150, 150);
    camera.lookAt(0, 0, 0);
    scene.add(new THREE.AmbientLight(0xffffff, 0.7));
    const sun = new THREE.DirectionalLight(0xffffff, 0.8);
    sun.position.set(80, 120, 40);
    scene.add(sun);

    let vehicle: THREE.Object3D | null = null;
    new GLTFLoader().load(modelUrl, (g) => {
      vehicle = g.scene;
      scene.add(vehicle);
    });

    fetch(mapUrl)
      .then((r) => r.json())
      .then((geo) => addBuildings(scene, geo));

    let raf = 0;
    const loop = () => {
      raf = requestAnimationFrame(loop);
      renderer.render(scene, camera);
    };
    loop();
    return () => {
      cancelAnimationFrame(raf);
      renderer.dispose();
      el.removeChild(renderer.domElement);
    };
  }, [mapUrl, modelUrl]);
  return <div ref={host} className="h-full w-full" />;
}
```

`addBuildings` mengonversi koordinat ke bidang lokal (meter) dan membuat `ExtrudeGeometry` per poligon dengan tinggi `height_m`; bila `webglAvailable()` bernilai false, komponen induk merender `FlatMap` berbasis `<canvas>` 2D.

## 6. Landing Page Next.js 15

### 6.1 Struktur dan Konfigurasi

```
apps/web/
├─ next.config.mjs
├─ tailwind.config.ts
├─ app/
│  ├─ (marketing)/
│  │  ├─ layout.tsx
│  │  └─ page.tsx
│  ├─ r/[code]/page.tsx             simpan kode referral lalu arahkan ke unduhan
│  ├─ merchant/...                  dasbor merchant
│  └─ admin/...                     panel admin (klaim admin)
├─ components/landing/
│  ├─ HeroReferralBanner.tsx
│  ├─ WordRotator.tsx
│  ├─ SalesPings.tsx
│  ├─ CountUp.tsx
│  ├─ BentoShowcase.tsx
│  ├─ ProcessDraw.tsx
│  ├─ PriceRoll.tsx
│  ├─ CursorTour.tsx
│  └─ ReviewShuffle.tsx
└─ lib/
   ├─ firebase.ts
   ├─ gateway.ts
   └─ format.ts
```

```js
// next.config.mjs
const nextConfig = {
  output: 'export',
  images: { unoptimized: true },
  trailingSlash: true,
};
export default nextConfig;
```

```ts
// tailwind.config.ts
import type { Config } from 'tailwindcss';

export default {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        emerald: { 500: '#059669', 600: '#047857', 900: '#064E3B' },
        ink: { 950: '#04130E', 900: '#0A2219', 50: '#ECFDF5' },
      },
      borderRadius: { bento: '20px' },
    },
  },
} satisfies Config;
```

```ts
// lib/gateway.ts
const BASE = process.env.NEXT_PUBLIC_GATEWAY_URL!;

export async function getPublic<T>(path: string, signal?: AbortSignal): Promise<T> {
  const res = await fetch(`${BASE}${path}`, { signal });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json() as Promise<T>;
}

export async function postAuthed<T>(path: string, token: string, body: unknown = {}): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json() as Promise<T>;
}
```

```ts
// lib/format.ts
export const rupiah = (n: number) =>
  new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(n);
```

### 6.2 Word Rotator

```tsx
'use client';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { useEffect, useState } from 'react';

export function WordRotator({ words, interval = 2400 }: { words: string[]; interval?: number }) {
  const reduce = useReducedMotion();
  const [i, setI] = useState(0);

  useEffect(() => {
    if (reduce) return;
    const t = setInterval(() => setI((v) => (v + 1) % words.length), interval);
    return () => clearInterval(t);
  }, [reduce, words.length, interval]);

  const widest = words.reduce((a, b) => (b.length > a.length ? b : a), '');

  return (
    <span className="relative inline-grid overflow-hidden align-bottom">
      <span className="invisible col-start-1 row-start-1" aria-hidden>{widest}</span>
      <AnimatePresence mode="wait">
        <motion.span
          key={words[i]}
          className="col-start-1 row-start-1 text-emerald-500"
          initial={reduce ? false : { y: '100%', opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          exit={reduce ? undefined : { y: '-100%', opacity: 0 }}
          transition={{ duration: 0.35, ease: 'easeOut' }}
        >
          {words[i]}
        </motion.span>
      </AnimatePresence>
    </span>
  );
}
```

Pemakaian: `<h1>Mau <WordRotator words={['Numpang', 'Jastip', 'Kirim Paket', 'Jajan']} /> di kampus?</h1>`. Elemen tak terlihat dengan kata terpanjang mengunci lebar sehingga tidak ada layout shift.

### 6.3 Count-Up

```tsx
'use client';
import { useReducedMotion } from 'framer-motion';
import { useEffect, useRef, useState } from 'react';

export function CountUp({ to, duration = 1200, suffix = '' }: { to: number; duration?: number; suffix?: string }) {
  const ref = useRef<HTMLSpanElement>(null);
  const reduce = useReducedMotion();
  const [value, setValue] = useState(0);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const io = new IntersectionObserver(
      ([entry]) => {
        if (!entry.isIntersecting) return;
        io.disconnect();
        if (reduce) {
          setValue(to);
          return;
        }
        const t0 = performance.now();
        const tick = (t: number) => {
          const p = Math.min((t - t0) / duration, 1);
          setValue(Math.round(to * (1 - Math.pow(1 - p, 3))));
          if (p < 1) requestAnimationFrame(tick);
        };
        requestAnimationFrame(tick);
      },
      { threshold: 0.4 },
    );
    io.observe(el);
    return () => io.disconnect();
  }, [to, duration, reduce]);

  return <span ref={ref}>{value.toLocaleString('id-ID')}{suffix}</span>;
}
```

### 6.4 Sales Pings

```tsx
'use client';
import { AnimatePresence, motion } from 'framer-motion';
import { useEffect, useRef, useState } from 'react';
import { getPublic } from '@/lib/gateway';

type Ping = { id: string; label: string; place: string };

export function SalesPings() {
  const queue = useRef<Ping[]>([]);
  const seen = useRef(new Set<string>());
  const [current, setCurrent] = useState<Ping | null>(null);

  useEffect(() => {
    const ctrl = new AbortController();
    const poll = async () => {
      try {
        const data = await getPublic<{ pings: Ping[] }>('/public/pings', ctrl.signal);
        for (const p of data.pings) {
          if (!seen.current.has(p.id)) {
            seen.current.add(p.id);
            queue.current.push(p);
          }
        }
      } catch {
        // tampilan dekoratif; abaikan kegagalan jaringan
      }
    };
    poll();
    const pollTimer = setInterval(poll, 30_000);
    const showTimer = setInterval(() => {
      const next = queue.current.shift();
      if (!next) return;
      setCurrent(next);
      setTimeout(() => setCurrent((c) => (c?.id === next.id ? null : c)), 4000);
    }, 6000);
    return () => {
      ctrl.abort();
      clearInterval(pollTimer);
      clearInterval(showTimer);
    };
  }, []);

  return (
    <div className="pointer-events-none fixed bottom-4 left-4 z-40" aria-live="polite">
      <AnimatePresence>
        {current && (
          <motion.div
            key={current.id}
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 16 }}
            className="rounded-bento bg-ink-900 px-4 py-3 text-sm text-ink-50 shadow-lg ring-1 ring-emerald-900"
          >
            Seseorang di <b>{current.place}</b> baru memesan <b>{current.label}</b>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
```

### 6.5 Price Roll Calculator

```tsx
'use client';
import { motion, useSpring, useTransform } from 'framer-motion';
import { useEffect, useState } from 'react';
import { rupiah } from '@/lib/format';

const OURS = 0.005;

export function PriceRoll({ bigRate = 0.2 }: { bigRate?: number }) {
  const [total, setTotal] = useState(30000);
  const saving = total * (bigRate - OURS);
  const spring = useSpring(saving, { stiffness: 120, damping: 20 });
  const text = useTransform(spring, (v) => rupiah(Math.round(v)));

  useEffect(() => {
    spring.set(saving);
  }, [saving, spring]);

  return (
    <div className="rounded-bento bg-ink-900 p-6 ring-1 ring-emerald-900">
      <label htmlFor="order-total" className="text-sm text-ink-50/70">Nilai pesanan</label>
      <input
        id="order-total"
        type="range"
        min={10000}
        max={200000}
        step={5000}
        value={total}
        onChange={(e) => setTotal(Number(e.target.value))}
        className="mt-2 w-full accent-emerald-500"
      />
      <div className="mt-1 font-semibold text-ink-50">{rupiah(total)}</div>
      <dl className="mt-4 grid grid-cols-2 gap-3 text-sm">
        <div>
          <dt className="text-ink-50/70">Komisi {Math.round(bigRate * 100)}% (asumsi)</dt>
          <dd className="text-lg">{rupiah(Math.round(total * bigRate))}</dd>
        </div>
        <div>
          <dt className="text-ink-50/70">Komisi Campus Express 0,5%</dt>
          <dd className="text-lg text-emerald-500">{rupiah(Math.round(total * OURS))}</dd>
        </div>
      </dl>
      <p className="mt-4 text-sm text-ink-50/70">Selisih untuk driver dan UMKM</p>
      <motion.p className="text-3xl font-bold text-emerald-500">{text}</motion.p>
      <p className="mt-2 text-xs text-ink-50/50">Angka {Math.round(bigRate * 100)}% adalah asumsi ilustrasi, bukan data resmi platform tertentu.</p>
    </div>
  );
}
```

### 6.6 Process Draw SVG Timeline

```tsx
'use client';
import { motion, useScroll } from 'framer-motion';
import { useRef } from 'react';

const STEPS = ['Pilih layanan', 'Pesan & bayar', 'Driver klaim', 'Lacak & chat', 'Serahkan dengan PIN'];

export function ProcessDraw() {
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start 80%', 'end 40%'] });
  return (
    <div ref={ref} className="relative mx-auto max-w-xl py-8">
      <svg viewBox="0 0 40 500" className="absolute left-0 top-0 h-full w-10" aria-hidden>
        <path d="M20 10 V490" stroke="#0B3B2C" strokeWidth="4" fill="none" />
        <motion.path d="M20 10 V490" stroke="#059669" strokeWidth="4" fill="none" style={{ pathLength: scrollYProgress }} />
      </svg>
      <ol className="ml-14 space-y-16">
        {STEPS.map((s, i) => (
          <li key={s} className="text-ink-50">
            <span className="text-emerald-500">0{i + 1}</span> {s}
          </li>
        ))}
      </ol>
    </div>
  );
}
```

### 6.7 Review Shuffle Carousel

```tsx
'use client';
import { motion } from 'framer-motion';
import { useState } from 'react';

type Review = { id: string; name: string; text: string; rating: number };

export function ReviewShuffle({ reviews }: { reviews: Review[] }) {
  const [order, setOrder] = useState(reviews.map((r) => r.id));
  const byId = Object.fromEntries(reviews.map((r) => [r.id, r]));
  const rotate = () => setOrder(([first, ...rest]) => [...rest, first]);

  return (
    <div className="relative mx-auto h-56 w-full max-w-sm">
      {order.slice(0, 4).map((id, depth) => {
        const r = byId[id];
        const top = depth === 0;
        return (
          <motion.article
            key={id}
            drag={top ? 'x' : false}
            dragSnapToOrigin
            onDragEnd={(_, info) => {
              if (Math.abs(info.offset.x) > 100) rotate();
            }}
            animate={{ scale: 1 - depth * 0.05, y: depth * 14, opacity: 1 - depth * 0.2 }}
            className="absolute inset-0 rounded-bento bg-ink-900 p-5 ring-1 ring-emerald-900"
            style={{ zIndex: 10 - depth }}
          >
            <p className="text-ink-50">{r.text}</p>
            <footer className="mt-3 text-sm text-ink-50/70">{r.name} · {'★'.repeat(r.rating)}</footer>
          </motion.article>
        );
      })}
      <button onClick={rotate} className="absolute -bottom-10 right-0 text-sm text-emerald-500">Berikutnya</button>
    </div>
  );
}
```

### 6.8 Hero Referral Banner

```tsx
'use client';
import { GoogleAuthProvider, signInWithPopup } from 'firebase/auth';
import { useState } from 'react';
import { auth } from '@/lib/firebase';
import { postAuthed } from '@/lib/gateway';

export function HeroReferralBanner() {
  const [code, setCode] = useState<string | null>(null);
  const [success, setSuccess] = useState(0);
  const [error, setError] = useState<string | null>(null);

  async function start() {
    setError(null);
    try {
      const provider = new GoogleAuthProvider();
      provider.setCustomParameters({ hd: 'mhs.uin.ac.id' });
      const { user } = await signInWithPopup(auth, provider);
      const token = await user.getIdToken();
      const res = await postAuthed<{ code: string; successCount: number }>('/referrals/code', token);
      setCode(res.code);
      setSuccess(res.successCount);
    } catch {
      setError('Masuk dengan akun @mhs.uin.ac.id untuk mendapatkan tautan undangan.');
    }
  }

  const link = code ? `${location.origin}/r/${code}/` : '';

  return (
    <section className="rounded-bento bg-emerald-900 p-6 text-ink-50">
      {!code ? (
        <button onClick={start} className="rounded-xl bg-emerald-500 px-5 py-3 font-semibold">
          Dapatkan tautan undanganmu
        </button>
      ) : (
        <div className="space-y-2">
          <input readOnly value={link} className="w-full rounded-lg bg-ink-950 px-3 py-2" aria-label="Tautan undangan" />
          <button onClick={() => navigator.clipboard.writeText(link)} className="rounded-lg bg-emerald-500 px-4 py-2">
            Salin
          </button>
          <p className="text-sm">Teman yang berhasil bergabung: <b>{success}</b></p>
        </div>
      )}
      {error && <p role="alert" className="mt-2 text-sm text-amber-300">{error}</p>}
    </section>
  );
}
```

Halaman `/r/[code]` memvalidasi `^[A-Z0-9]{6}$`, menyimpan kode di `localStorage`, lalu mengarahkan ke tautan unduhan; aplikasi mengirim kode itu ke `POST /me/bootstrap` saat pendaftaran. Parameter `hd` hanya petunjuk UI; validasi sesungguhnya tetap di server.

### 6.9 Cursor Tour Preview

```tsx
'use client';
import { useState } from 'react';

type Hotspot = { id: string; x: number; y: number; title: string; body: string };

export function CursorTour({ src, hotspots }: { src: string; hotspots: Hotspot[] }) {
  const [active, setActive] = useState<string | null>(hotspots[0]?.id ?? null);
  return (
    <div className="relative inline-block">
      <img src={src} alt="Pratinjau layar aplikasi" className="max-h-[560px] rounded-bento" />
      {hotspots.map((h) => (
        <button
          key={h.id}
          style={{ left: `${h.x}%`, top: `${h.y}%` }}
          onClick={() => setActive(h.id)}
          onFocus={() => setActive(h.id)}
          onMouseEnter={() => setActive(h.id)}
          aria-label={h.title}
          className="absolute h-6 w-6 -translate-x-1/2 -translate-y-1/2 rounded-full bg-emerald-500 ring-4 ring-emerald-500/30"
        />
      ))}
      {hotspots.filter((h) => h.id === active).map((h) => (
        <div
          key={h.id}
          role="status"
          style={{ left: `${Math.min(h.x, 60)}%`, top: `${h.y + 6}%` }}
          className="absolute w-52 rounded-xl bg-ink-900 p-3 text-sm text-ink-50 ring-1 ring-emerald-900"
        >
          <b>{h.title}</b>
          <p>{h.body}</p>
        </div>
      ))}
    </div>
  );
}
```

### 6.10 Bento Build Showcase

Grid CSS tanpa pustaka: `grid grid-cols-1 gap-3 md:grid-cols-2 lg:grid-cols-4` dengan kartu `rounded-bento`; kartu Konsumen, Driver, Merchant memakai `lg:col-span-2` bergantian dengan kartu fakta kecil (komisi 0,5%, PIN serah-terima, chat dalam aplikasi, peta 3D).

### 6.11 Aturan Performa dan Aksesibilitas Landing

| Aturan | Detail |
|---|---|
| Komponen berat | `dynamic(() => import(...), { ssr: false })` untuk `CursorTour`, `ReviewShuffle`, `IsoScene` |
| Gambar | WebP, `width`/`height` eksplisit, `loading="lazy"` kecuali hero |
| Gerak | `useReducedMotion` pada WordRotator, CountUp; ProcessDraw menampilkan garis penuh bila reduced motion |
| Header keamanan | Berkas `_headers` (Cloudflare Pages) berisi CSP, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `frame-ancestors 'none'` |
| Cache | Aset statis `immutable`; data publik dari Gateway ber-cache 30 detik |

## 7. Firestore Security Rules

Klaim cermin pada token: `driver` (boolean), `merchantId` (string), `suspended` (boolean), `admin` (boolean). Gateway menetapkan klaim saat persetujuan dan mencabut token saat suspend.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() { return request.auth != null; }
    function campusMail() {
      return signedIn()
        && request.auth.token.email_verified == true
        && request.auth.token.email.matches('.*@mhs[.]uin[.]ac[.]id');
    }
    function active() {
      return campusMail() && request.auth.token.get('suspended', false) != true;
    }
    function isAdmin() { return active() && request.auth.token.get('admin', false) == true; }
    function isDriver() { return active() && request.auth.token.get('driver', false) == true; }
    function merchantId() { return request.auth.token.get('merchantId', ''); }
    function onlyChanges(keys) {
      return request.resource.data.diff(resource.data).affectedKeys().hasOnly(keys);
    }

    match /{document=**} { allow read, write: if false; }

    match /users/{uid} {
      allow get: if active() && (request.auth.uid == uid || isAdmin());
      allow list: if isAdmin();
      allow create, delete: if false;
      allow update: if active() && request.auth.uid == uid
        && onlyChanges(['displayName', 'photoUrl', 'phone', 'activeRole', 'fcmTokens', 'blockedUids', 'updatedAt'])
        && request.resource.data.activeRole in resource.data.roles
        && request.resource.data.fcmTokens.size() <= 5
        && request.resource.data.blockedUids.size() <= 50;
    }

    match /driverProfiles/{uid} {
      allow get: if active() && (request.auth.uid == uid || isAdmin());
      allow list: if isAdmin();
      allow update: if isDriver() && request.auth.uid == uid
        && onlyChanges(['online', 'updatedAt']);
      allow create, delete: if false;
    }

    match /wallets/{uid} {
      allow get: if active() && (request.auth.uid == uid || isAdmin());
      allow list, write: if false;
    }
    match /walletTx/{id} {
      allow get, list: if active() && (resource.data.uid == request.auth.uid || isAdmin());
      allow write: if false;
    }

    match /merchants/{id} {
      allow get, list: if active() && (resource.data.status == 'approved' || merchantId() == id || isAdmin());
      allow update: if active() && merchantId() == id
        && onlyChanges(['isOpen', 'description', 'prepTimeMin', 'schedule', 'updatedAt']);
      allow create, delete: if false;
    }
    match /merchantMenus/{id} {
      allow get: if active();
      allow create, update: if active() && merchantId() == id;
      allow delete, list: if false;
    }

    match /landmarks/{id} { allow get, list: if active(); }
    match /zones/{id} { allow get, list: if active(); }
    match /fareMatrix/{id} { allow get, list: if active(); }
    match /config/{id} { allow get: if active(); }

    match /orders/{orderId} {
      function isConsumer() { return resource.data.consumerUid == request.auth.uid; }
      function isMerchantOf() { return merchantId() != '' && resource.data.get('merchantId', '') == merchantId(); }
      function isDriverOf() { return resource.data.get('driverUid', '') == request.auth.uid; }
      function driverStep(from, to) {
        return (from == 'CLAIMED' && to == 'AT_PICKUP')
          || (from == 'AT_PICKUP' && to == 'ON_DELIVERY')
          || (from == 'ON_DELIVERY' && to == 'ARRIVED');
      }

      allow get: if active() && (isConsumer() || isMerchantOf() || isDriverOf() || isAdmin());
      allow list: if active() && (
        isConsumer() || isMerchantOf() || isDriverOf() || isAdmin()
        || (isDriver() && resource.data.status == 'AWAITING_DRIVER' && resource.data.finalized == true)
      );

      allow create: if active()
        && request.resource.data.consumerUid == request.auth.uid
        && request.resource.data.status == 'PLACED'
        && request.resource.data.finalized == false
        && request.resource.data.type in ['numpang', 'jastip', 'paket', 'umkm']
        && request.resource.data.pricing.total <= 500000
        && request.resource.data.keys().hasOnly([
          'type', 'status', 'consumerUid', 'merchantId', 'participants', 'items', 'pickup', 'dropoff',
          'pricing', 'payment', 'idempotencyKey', 'finalized', 'version', 'schemaVersion', 'createdAt', 'updatedAt'
        ]);

      allow update: if active() && (
        (isConsumer() && resource.data.status == 'PLACED'
          && request.resource.data.status == 'CANCELLED'
          && onlyChanges(['status', 'updatedAt', 'version']))
        || (isMerchantOf() && resource.data.status == 'PLACED'
          && request.resource.data.status in ['ACCEPTED', 'CANCELLED']
          && onlyChanges(['status', 'prepReadyAt', 'updatedAt', 'version']))
        || (isMerchantOf() && resource.data.status == 'ACCEPTED'
          && request.resource.data.status in ['READY', 'AWAITING_DRIVER']
          && onlyChanges(['status', 'updatedAt', 'version']))
        || (isDriverOf() && driverStep(resource.data.status, request.resource.data.status)
          && onlyChanges(['status', 'tracking', 'updatedAt', 'version']))
      );
      allow delete: if false;

      match /events/{eventId} {
        allow read: if active() && (
          get(/databases/$(database)/documents/orders/$(orderId)).data.participants.hasAny([request.auth.uid]) || isAdmin());
        allow write: if false;
      }
      match /secrets/{docId} {
        allow get: if active()
          && get(/databases/$(database)/documents/orders/$(orderId)).data.consumerUid == request.auth.uid;
        allow list, write: if false;
      }
    }

    match /chats/{orderId} {
      function chat() { return get(/databases/$(database)/documents/chats/$(orderId)).data; }
      allow get: if active() && request.auth.uid in resource.data.participants;
      allow list, write: if false;

      match /messages/{messageId} {
        allow get, list: if active() && request.auth.uid in chat().participants;
        allow create: if active()
          && request.auth.uid in chat().participants
          && chat().status == 'open'
          && request.resource.data.senderUid == request.auth.uid
          && request.resource.data.createdAt == request.time
          && request.resource.data.type in ['text', 'chip', 'image']
          && (!('text' in request.resource.data) || request.resource.data.text.size() <= 500)
          && request.resource.data.keys().hasOnly([
            'senderUid', 'type', 'text', 'imageKey', 'clientId', 'createdAt', 'readBy', 'flagged', 'expireAt'
          ]);
        allow update: if active()
          && request.auth.uid in chat().participants
          && onlyChanges(['readBy'])
          && request.resource.data.readBy.hasAll(resource.data.readBy);
        allow delete: if false;
      }
    }

    match /reviews/{id} { allow get, list: if active(); allow write: if false; }
    match /disputes/{id} {
      allow get: if active() && (request.auth.uid in resource.data.participants || isAdmin());
      allow list: if isAdmin();
      allow write: if false;
    }
    match /referrals/{code} {
      allow get: if active() && resource.data.ownerUid == request.auth.uid;
      allow list, write: if false;
    }
  }
}
```

Catatan biaya dan perilaku:

| Hal | Catatan |
|---|---|
| `get()` di rules | Setiap `get()` dihitung sebagai pembacaan dokumen; kirim pesan chat menambah sekitar 1 baca. Anggarkan pada `Architecture.md` §9.3 |
| Aturan `list` | Rules bukan filter; query klien harus memuat `where` yang sejalan (mis. `consumerUid == uid`) atau akan ditolak |
| Tes | Semua aturan wajib punya tes emulator (§9) |

### 7.1 Indeks

```json
{
  "indexes": [
    { "collectionGroup": "orders", "queryScope": "COLLECTION",
      "fields": [{ "fieldPath": "status", "order": "ASCENDING" }, { "fieldPath": "createdAt", "order": "DESCENDING" }] },
    { "collectionGroup": "orders", "queryScope": "COLLECTION",
      "fields": [{ "fieldPath": "consumerUid", "order": "ASCENDING" }, { "fieldPath": "createdAt", "order": "DESCENDING" }] },
    { "collectionGroup": "orders", "queryScope": "COLLECTION",
      "fields": [{ "fieldPath": "driverUid", "order": "ASCENDING" }, { "fieldPath": "createdAt", "order": "DESCENDING" }] },
    { "collectionGroup": "orders", "queryScope": "COLLECTION",
      "fields": [{ "fieldPath": "merchantId", "order": "ASCENDING" }, { "fieldPath": "status", "order": "ASCENDING" }, { "fieldPath": "createdAt", "order": "DESCENDING" }] },
    { "collectionGroup": "walletTx", "queryScope": "COLLECTION",
      "fields": [{ "fieldPath": "uid", "order": "ASCENDING" }, { "fieldPath": "createdAt", "order": "DESCENDING" }] }
  ],
  "fieldOverrides": []
}
```

## 8. Trusted Gateway (Cloudflare Workers)

### 8.1 Struktur dan Konfigurasi

```
services/gateway/
├─ wrangler.toml
├─ package.json
├─ tsconfig.json
└─ src/
   ├─ index.ts            router (Hono)
   ├─ auth.ts             verifikasi ID token dan App Check
   ├─ firestore.ts        klien REST Firestore + transaksi
   ├─ money.ts            hitung komisi
   ├─ routes/
   │  ├─ orders.ts        finalize, claim, complete, cancel
   │  ├─ wallet.ts        topup, approve
   │  ├─ files.ts         upload, signed url
   │  ├─ public.ts        pings, stats, reviews
   │  └─ admin.ts         approve driver/merchant, suspend, claims
   └─ cron.ts             expire order, rekonsiliasi
```

```toml
# wrangler.toml
name = "ce-gateway"
main = "src/index.ts"
compatibility_date = "2025-01-01"

[vars]
FIREBASE_PROJECT_ID = "campus-express-prod"
ALLOWED_ORIGINS = "https://campusexpress.example,https://admin.campusexpress.example"

[[r2_buckets]]
binding = "PUBLIC_BUCKET"
bucket_name = "ce-public"

[[r2_buckets]]
binding = "PRIVATE_BUCKET"
bucket_name = "ce-private"

[triggers]
crons = ["*/2 * * * *", "0 17 * * *"]
```

Rahasia (`FIREBASE_SERVICE_ACCOUNT_JSON`, `URL_SIGNING_KEY`) ditetapkan dengan `wrangler secret put` (lihat `secrets.md`). Ganti domain contoh dengan domain nyata.

### 8.2 Verifikasi ID Token

```ts
// src/auth.ts
import { createRemoteJWKSet, jwtVerify, type JWTPayload } from 'jose';

const JWKS = createRemoteJWKSet(
  new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'),
);

export interface Caller extends JWTPayload {
  uid: string;
  email: string;
  email_verified: boolean;
  admin?: boolean;
  adminScope?: string[];
  driver?: boolean;
  merchantId?: string;
  suspended?: boolean;
}

export async function verifyIdToken(token: string, projectId: string): Promise<Caller> {
  const { payload } = await jwtVerify(token, JWKS, {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
  });
  const email = String(payload.email ?? '');
  if (!payload.sub || payload.email_verified !== true || !/@mhs\.uin\.ac\.id$/i.test(email)) {
    throw new HttpError(403, 'DOMAIN_NOT_ALLOWED');
  }
  if (payload.suspended === true) throw new HttpError(403, 'SUSPENDED');
  return { ...payload, uid: payload.sub, email, email_verified: true } as Caller;
}

export class HttpError extends Error {
  constructor(public status: number, public code: string) {
    super(code);
  }
}
```

```ts
// src/index.ts
import { Hono } from 'hono';
import { HttpError, verifyIdToken, type Caller } from './auth';
import { scheduled } from './cron';

type Env = {
  Bindings: Cloudflare.Env;
  Variables: { caller: Caller };
};

const app = new Hono<Env>();

app.use('*', async (c, next) => {
  const origin = c.req.header('Origin') ?? '';
  const allowed = c.env.ALLOWED_ORIGINS.split(',');
  if (allowed.includes(origin)) {
    c.header('Access-Control-Allow-Origin', origin);
    c.header('Access-Control-Allow-Headers', 'Authorization, Content-Type, X-Firebase-AppCheck');
    c.header('Vary', 'Origin');
  }
  if (c.req.method === 'OPTIONS') return c.body(null, 204);
  await next();
});

app.use('/orders/*', requireAuth);
app.use('/wallet/*', requireAuth);
app.use('/upload/*', requireAuth);
app.use('/files/*', requireAuth);
app.use('/admin/*', requireAuth);
app.use('/referrals/*', requireAuth);
app.use('/me/*', requireAuth);

async function requireAuth(c: any, next: () => Promise<void>) {
  const header = c.req.header('Authorization') ?? '';
  if (!header.startsWith('Bearer ')) throw new HttpError(401, 'NO_TOKEN');
  c.set('caller', await verifyIdToken(header.slice(7), c.env.FIREBASE_PROJECT_ID));
  await next();
}

app.onError((err, c) => {
  if (err instanceof HttpError) return c.json({ code: err.code }, err.status as 400);
  console.error(JSON.stringify({ level: 'error', msg: String(err) }));
  return c.json({ code: 'INTERNAL' }, 500);
});

export default { fetch: app.fetch, scheduled };
```

Verifikasi token App Check ditambahkan sebagai middleware tambahan (`X-Firebase-AppCheck`) menggunakan JWKS App Check; mode enforce diaktifkan setelah klien rilis stabil.

### 8.3 Klien REST Firestore

```ts
// src/firestore.ts
import { importPKCS8, SignJWT } from 'jose';

type Sa = { client_email: string; private_key: string };
type Doc = { id: string; data: Record<string, any>; updateTime: string } | null;

export function enc(v: unknown): any {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(enc) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v as object).map(([k, x]) => [k, enc(x)])) } };
}

export function dec(f: any): any {
  if ('nullValue' in f) return null;
  if ('booleanValue' in f) return f.booleanValue;
  if ('integerValue' in f) return Number(f.integerValue);
  if ('doubleValue' in f) return f.doubleValue;
  if ('stringValue' in f) return f.stringValue;
  if ('timestampValue' in f) return new Date(f.timestampValue);
  if ('arrayValue' in f) return (f.arrayValue.values ?? []).map(dec);
  if ('mapValue' in f) return Object.fromEntries(Object.entries(f.mapValue.fields ?? {}).map(([k, x]) => [k, dec(x)]));
  return undefined;
}

let cached: { token: string; exp: number } | null = null;

async function accessToken(sa: Sa): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.exp - 60 > now) return cached.token;
  const key = await importPKCS8(sa.private_key, 'RS256');
  const assertion = await new SignJWT({ scope: 'https://www.googleapis.com/auth/datastore' })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }),
  });
  const json = (await res.json()) as { access_token: string; expires_in: number };
  cached = { token: json.access_token, exp: now + json.expires_in };
  return json.access_token;
}

export type WriteOp = {
  path: string;
  set?: Record<string, any>;
  mask?: string[];
  mustNotExist?: boolean;
  precondition?: string;
  serverTime?: string[];
  increments?: Record<string, number>;
};

export class Firestore {
  private base: string;
  private sa: Sa;
  constructor(env: { FIREBASE_PROJECT_ID: string; FIREBASE_SERVICE_ACCOUNT_JSON: string }) {
    this.sa = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_JSON);
    this.base = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents`;
  }

  private async call(url: string, init: RequestInit = {}) {
    const res = await fetch(url, {
      ...init,
      headers: { Authorization: `Bearer ${await accessToken(this.sa)}`, 'Content-Type': 'application/json' },
    });
    if (!res.ok) throw new FirestoreError(res.status, await res.text());
    return res.json() as Promise<any>;
  }

  async begin(): Promise<string> {
    const r = await this.call(`${this.base}:beginTransaction`, { method: 'POST', body: '{}' });
    return r.transaction;
  }

  async get(path: string, txn?: string): Promise<Doc> {
    const q = txn ? `?transaction=${encodeURIComponent(txn)}` : '';
    const res = await fetch(`${this.base}/${path}${q}`, {
      headers: { Authorization: `Bearer ${await accessToken(this.sa)}` },
    });
    if (res.status === 404) return null;
    if (!res.ok) throw new FirestoreError(res.status, await res.text());
    const d = (await res.json()) as any;
    return { id: d.name.split('/').pop(), data: dec({ mapValue: { fields: d.fields ?? {} } }), updateTime: d.updateTime };
  }

  async commit(ops: WriteOp[], txn?: string): Promise<void> {
    const writes = ops.map((op) => {
      const name = `${this.base.replace('https://firestore.googleapis.com/v1/', '')}/${op.path}`;
      const fields = op.set ? (enc(op.set) as any).mapValue.fields : {};
      const w: any = { update: { name, fields } };
      if (op.mask) w.updateMask = { fieldPaths: op.mask };
      if (op.mustNotExist) w.currentDocument = { exists: false };
      else if (op.precondition) w.currentDocument = { updateTime: op.precondition };
      const transforms = [
        ...(op.serverTime ?? []).map((fieldPath) => ({ fieldPath, setToServerValue: 'REQUEST_TIME' })),
        ...Object.entries(op.increments ?? {}).map(([fieldPath, n]) => ({
          fieldPath,
          increment: { integerValue: String(n) },
        })),
      ];
      if (transforms.length) w.updateTransforms = transforms;
      return w;
    });
    await this.call(`${this.base}:commit`, {
      method: 'POST',
      body: JSON.stringify({ writes, ...(txn ? { transaction: txn } : {}) }),
    });
  }
}

export class FirestoreError extends Error {
  constructor(public status: number, public body: string) {
    super(`FIRESTORE_${status}`);
  }
}
```

Catatan: `precondition` memakai `updateTime` dokumen yang dibaca dalam transaksi sehingga commit gagal bila dokumen berubah (kontrol konkurensi). Untuk operasi sensitif pada banyak dokumen, semua dokumen yang dibaca diberi `precondition`.

### 8.4 Komisi

```ts
// src/money.ts
export function computeCommission(total: number, bps: number, min: number): number {
  return Math.max(min, Math.floor((total * bps + 5000) / 10000));
}

export function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}
```

```ts
// money.test.ts
import { describe, expect, it } from 'vitest';
import { computeCommission } from './money';

describe('computeCommission', () => {
  it.each([
    [30000, 150],
    [17500, 88],
    [5000, 50],
    [500000, 2500],
  ])('total %i -> %i', (total, expected) => {
    expect(computeCommission(total, 50, 50)).toBe(expected);
  });
});
```

### 8.5 Klaim Order (Atomik)

```ts
// src/routes/orders.ts (cuplikan)
export async function claimOrder(env: Env, uid: string, orderId: string) {
  const fs = new Firestore(env);
  const txn = await fs.begin();
  const [order, wallet, driver, cfg] = await Promise.all([
    fs.get(`orders/${orderId}`, txn),
    fs.get(`wallets/${uid}`, txn),
    fs.get(`driverProfiles/${uid}`, txn),
    fs.get('config/app', txn),
  ]);

  if (!order || order.data.finalized !== true) throw new HttpError(404, 'ORDER_NOT_FOUND');
  if (order.data.status !== 'AWAITING_DRIVER') throw new HttpError(409, 'ORDER_TAKEN');
  if (order.data.consumerUid === uid) throw new HttpError(403, 'SELF_ORDER');
  if (!driver || driver.data.status !== 'approved') throw new HttpError(403, 'DRIVER_NOT_APPROVED');
  if (!wallet) throw new HttpError(402, 'NO_WALLET');

  const c = cfg!.data;
  const estimate = computeCommission(order.data.pricing.total, c.commissionBps, c.minCommission);
  const available = wallet.data.balance - wallet.data.pendingCommission;
  if (wallet.data.balance < c.driverMinBalance || available < estimate) {
    throw new HttpError(402, 'INSUFFICIENT_BALANCE');
  }
  if ((driver.data.activeJobs ?? 0) >= c.maxActiveJobsPerDriver) throw new HttpError(409, 'TOO_MANY_JOBS');

  try {
    await fs.commit(
      [
        {
          path: `orders/${orderId}`,
          precondition: order.updateTime,
          mask: ['status', 'driverUid', 'participants', 'claimedAt', 'pricing.commission', 'version'],
          set: {
            status: 'CLAIMED',
            driverUid: uid,
            participants: [...order.data.participants, uid],
            claimedAt: new Date(),
            pricing: { ...order.data.pricing, commission: estimate },
            version: order.data.version + 1,
          },
          serverTime: ['updatedAt'],
        },
        {
          path: `wallets/${uid}`,
          precondition: wallet.updateTime,
          mask: ['pendingCommission'],
          set: { pendingCommission: wallet.data.pendingCommission + estimate },
          serverTime: ['updatedAt'],
        },
        {
          path: `driverProfiles/${uid}`,
          precondition: driver.updateTime,
          mask: ['activeJobs'],
          set: { activeJobs: (driver.data.activeJobs ?? 0) + 1 },
          serverTime: ['updatedAt'],
        },
        {
          path: `orders/${orderId}/events/claim_${uid}`,
          mustNotExist: true,
          set: { type: 'CLAIMED', fromStatus: 'AWAITING_DRIVER', toStatus: 'CLAIMED', actorUid: uid, actorRole: 'driver' },
          serverTime: ['at'],
        },
        {
          path: `chats/${orderId}`,
          mask: ['participants', 'roles.' + uid],
          set: { participants: [...order.data.participants, uid], roles: { [uid]: 'driver' } },
        },
      ],
      txn,
    );
  } catch (e) {
    if (e instanceof FirestoreError && (e.status === 409 || e.status === 400)) throw new HttpError(409, 'ORDER_TAKEN');
    throw e;
  }
  return { ok: true, commissionEstimate: estimate };
}
```

Konkurensi: bila dua driver melakukan klaim bersamaan, hanya satu commit yang lolos `precondition`; yang lain menerima `ORDER_TAKEN`. Catatan: pembaruan `chats/{orderId}` ikut dalam commit yang sama; pastikan dokumen chat sudah dibuat saat finalisasi.

### 8.6 Penyelesaian Order (PIN dan Komisi)

```ts
export async function completeOrder(env: Env, caller: Caller, orderId: string, pin: string) {
  const fs = new Firestore(env);
  const order = await fs.get(`orders/${orderId}`);
  if (!order) throw new HttpError(404, 'ORDER_NOT_FOUND');
  if (order.data.status === 'COMPLETED') return { ok: true, already: true };
  if (order.data.status !== 'ARRIVED' && order.data.status !== 'READY') throw new HttpError(409, 'BAD_STATE');

  const byDriver = order.data.driverUid === caller.uid;
  const byMerchant = !order.data.driverUid && caller.merchantId === order.data.merchantId;
  if (!byDriver && !byMerchant) throw new HttpError(403, 'NOT_ALLOWED');

  const secret = await fs.get(`orders/${orderId}/secrets/handover`);
  if (!secret) throw new HttpError(500, 'NO_SECRET');
  const s = secret.data;
  const cfg = (await fs.get('config/app'))!.data;
  if (s.lockedUntil && new Date(s.lockedUntil) > new Date()) throw new HttpError(429, 'PIN_LOCKED');

  if (!safeEqual(String(s.pin), pin)) {
    const attempts = (s.attempts ?? 0) + 1;
    const lock = attempts >= cfg.pinMaxAttempts;
    await fs.commit([{
      path: `orders/${orderId}/secrets/handover`,
      mask: lock ? ['attempts', 'lockedUntil'] : ['attempts'],
      set: lock ? { attempts: 0, lockedUntil: new Date(Date.now() + cfg.pinLockSec * 1000) } : { attempts },
    }]);
    throw new HttpError(lock ? 429 : 403, lock ? 'PIN_LOCKED' : 'PIN_WRONG');
  }

  const txn = await fs.begin();
  const fresh = (await fs.get(`orders/${orderId}`, txn))!;
  if (fresh.data.status === 'COMPLETED') return { ok: true, already: true };

  const ops: WriteOp[] = [{
    path: `orders/${orderId}`,
    precondition: fresh.updateTime,
    mask: ['status', 'completedAt', 'version'],
    set: { status: 'COMPLETED', completedAt: new Date(), version: fresh.data.version + 1 },
    serverTime: ['updatedAt'],
  }];

  if (fresh.data.driverUid) {
    const driverUid = fresh.data.driverUid as string;
    const wallet = (await fs.get(`wallets/${driverUid}`, txn))!;
    const driver = (await fs.get(`driverProfiles/${driverUid}`, txn))!;
    const commission = computeCommission(fresh.data.pricing.total, cfg.commissionBps, cfg.minCommission);
    const estimate = fresh.data.pricing.commission ?? commission;
    const balanceAfter = wallet.data.balance - commission;
    if (balanceAfter < 0) throw new HttpError(402, 'WALLET_NEGATIVE');
    ops.push(
      {
        path: `wallets/${driverUid}`,
        precondition: wallet.updateTime,
        mask: ['balance', 'pendingCommission'],
        set: { balance: balanceAfter, pendingCommission: Math.max(0, wallet.data.pendingCommission - estimate) },
        serverTime: ['updatedAt'],
      },
      {
        path: `walletTx/commission_${orderId}`,
        mustNotExist: true,
        set: {
          uid: driverUid, type: 'commission', amount: -commission, balanceAfter,
          orderId, status: 'approved', idempotencyKey: `commission:${orderId}`,
        },
        serverTime: ['createdAt'],
      },
      {
        path: `driverProfiles/${driverUid}`,
        precondition: driver.updateTime,
        mask: ['activeJobs'],
        set: { activeJobs: Math.max(0, (driver.data.activeJobs ?? 1) - 1) },
      },
    );
  }

  ops.push(
    {
      path: `orders/${orderId}/events/complete`,
      mustNotExist: true,
      set: { type: 'COMPLETED', fromStatus: fresh.data.status, toStatus: 'COMPLETED', actorUid: caller.uid },
      serverTime: ['at'],
    },
    {
      path: `salesPings/${orderId}`,
      mustNotExist: true,
      set: { label: pingLabel(fresh.data), place: await landmarkName(fs, fresh.data.dropoff.landmarkId), expireAt: new Date(Date.now() + 86_400_000) },
      serverTime: ['createdAt'],
    },
    { path: 'stats/campus', mask: [], set: {}, increments: { orders: 1, savedRupiah: savedVsBig(fresh.data.pricing.total) } },
  );

  await fs.commit(ops, txn);
  return { ok: true };
}
```

Fungsi bantu (`pingLabel`, `landmarkName`, `savedVsBig`) memetakan ke label menu umum tanpa identitas, nama landmark, dan selisih ilustratif terhadap asumsi komisi besar (`total × 0,195`, dibulatkan). `salesPings` memakai `expireAt` + TTL 24 jam. Semua dokumen yang dibaca dalam transaksi diberi `precondition`; hanya `stats/campus` yang memakai increment tanpa precondition.

### 8.7 Unggah R2 (Gateway)

```ts
// src/routes/files.ts
const LIMIT = 85 * 1024;
const KINDS = {
  product: { bucket: 'PUBLIC_BUCKET', roles: ['merchant'] },
  chat: { bucket: 'PRIVATE_BUCKET', roles: ['any'] },
  proof: { bucket: 'PRIVATE_BUCKET', roles: ['any'] },
  doc: { bucket: 'PRIVATE_BUCKET', roles: ['any'] },
} as const;

function isWebp(b: Uint8Array) {
  const s = (o: number, t: string) => [...t].every((ch, i) => b[o + i] === ch.charCodeAt(0));
  return b.length > 12 && s(0, 'RIFF') && s(8, 'WEBP');
}

app.put('/upload/:kind', async (c) => {
  const caller = c.get('caller');
  const kind = c.req.param('kind') as keyof typeof KINDS;
  const cfg = KINDS[kind];
  if (!cfg) throw new HttpError(404, 'UNKNOWN_KIND');
  if (kind === 'product' && !caller.merchantId) throw new HttpError(403, 'NOT_MERCHANT');

  const len = Number(c.req.header('Content-Length') ?? 0);
  if (!len || len > LIMIT) throw new HttpError(413, 'TOO_LARGE');
  const bytes = new Uint8Array(await c.req.arrayBuffer());
  if (bytes.length > LIMIT || !isWebp(bytes)) throw new HttpError(415, 'NOT_WEBP');

  const key = `${kind}/${caller.uid}/${crypto.randomUUID()}.webp`;
  await c.env[cfg.bucket].put(key, bytes, { httpMetadata: { contentType: 'image/webp', cacheControl: 'public, max-age=31536000, immutable' } });
  return c.json({ key });
});
```

Kuota harian per UID: gunakan binding Rate Limiting Workers bila tersedia pada paket yang dipakai (verifikasi), atau dokumen `uploadCounters/{uid}_{yyyyMMdd}` dengan satu tulis per unggah. `EXIF` hilang karena klien mengonversi ulang ke WebP dan Gateway hanya menerima WebP; pengguna yang mengirim langsung dengan WebP berisi metadata tetap dibatasi 85 KB, jadi risiko kecil.

### 8.8 URL Bertanda Tangan untuk Berkas Privat

```ts
async function hmacHex(secret: string, data: string) {
  const k = await crypto.subtle.importKey('raw', new TextEncoder().encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('HMAC', k, new TextEncoder().encode(data));
  return [...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

app.get('/files/*', async (c) => {
  const caller = c.get('caller');
  const key = decodeURIComponent(new URL(c.req.url).pathname.replace('/files/', ''));
  const [kind, ownerUid] = key.split('/');
  const allowed = ownerUid === caller.uid || (caller.admin && caller.adminScope?.includes('verify'));
  if (!allowed && !(await isOrderPeer(c.env, caller.uid, key))) throw new HttpError(403, 'FORBIDDEN');
  const exp = Math.floor(Date.now() / 1000) + 300;
  const sig = await hmacHex(c.env.URL_SIGNING_KEY, `${key}.${exp}`);
  return c.json({ url: `${new URL(c.req.url).origin}/f/${encodeURIComponent(key)}?exp=${exp}&sig=${sig}` });
});

app.get('/f/:key', async (c) => {
  const key = decodeURIComponent(c.req.param('key'));
  const exp = Number(c.req.query('exp'));
  const sig = c.req.query('sig') ?? '';
  const expected = await hmacHex(c.env.URL_SIGNING_KEY, `${key}.${exp}`);
  if (!exp || exp < Date.now() / 1000 || !safeEqual(sig, expected)) throw new HttpError(403, 'BAD_SIGNATURE');
  const obj = await c.env.PRIVATE_BUCKET.get(key);
  if (!obj) throw new HttpError(404, 'NOT_FOUND');
  return new Response(obj.body, { headers: { 'Content-Type': 'image/webp', 'Cache-Control': 'private, max-age=300' } });
});
```

`isOrderPeer` memeriksa bahwa pemanggil adalah peserta order yang mereferensikan kunci berkas (mis. gambar chat). Admin hanya mengakses dokumen KTM/SIM dan bukti dengan cakupan `verify` atau `finance`; setiap akses menulis `auditLogs`.

### 8.9 Endpoint Publik Ber-Cache

```ts
app.get('/public/pings', async (c) => {
  const cache = caches.default;
  const cacheKey = new Request(new URL('/public/pings', c.req.url).toString());
  const hit = await cache.match(cacheKey);
  if (hit) return hit;

  const fs = new Firestore(c.env);
  const rows = await fs.listLatest('salesPings', 8);
  const body = JSON.stringify({
    pings: rows.map((r) => ({ id: r.id, label: r.data.label, place: r.data.place })),
  });
  const res = new Response(body, {
    headers: {
      'Content-Type': 'application/json',
      'Cache-Control': 'public, s-maxage=30, stale-while-revalidate=60',
      'Access-Control-Allow-Origin': '*',
    },
  });
  c.executionCtx.waitUntil(cache.put(cacheKey, res.clone()));
  return res;
});
```

`listLatest` memakai `runQuery` dengan `orderBy createdAt desc` dan `limit`. Endpoint `/public/stats` identik dengan membaca `stats/campus` (1 dokumen). Respons tidak memuat UID, nama, atau waktu presisi.

### 8.10 Cron

| Jadwal | Tugas |
|---|---|
| Tiap 2 menit | Cari order `PLACED` > 5 menit (umkm) dan `AWAITING_DRIVER` > 10 menit → `EXPIRED`; finalisasi order yang tertinggal; order dengan driver tanpa aktivitas 10 menit setelah `AT_PICKUP` → dispute otomatis |
| Harian | Rekonsiliasi invarian I1–I4 (`Monetization.md` §3.5), ringkasan kuota, peringatan ke admin |

Query Cron memakai indeks `status + createdAt` dan `limit(50)`; Cron tidak memindai seluruh koleksi.

## 9. Pengujian

### 9.1 Tes Rules (Emulator)

```ts
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';

let env: Awaited<ReturnType<typeof initializeTestEnvironment>>;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'ce-test',
    firestore: { rules: readFileSync('firebase/firestore.rules', 'utf8') },
  });
});

const consumer = () =>
  env.authenticatedContext('u1', { email: 'a@mhs.uin.ac.id', email_verified: true }).firestore();

it('menolak email non-kampus', async () => {
  const db = env.authenticatedContext('x', { email: 'a@gmail.com', email_verified: true }).firestore();
  await assertFails(db.doc('config/app').get());
});

it('menolak klien menyelesaikan order', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc('orders/o1').set({
      consumerUid: 'u1', status: 'ARRIVED', driverUid: 'd1', participants: ['u1', 'd1'], version: 1,
    });
  });
  const db = env.authenticatedContext('d1', {
    email: 'd@mhs.uin.ac.id', email_verified: true, driver: true,
  }).firestore();
  await assertFails(db.doc('orders/o1').update({ status: 'COMPLETED', version: 2 }));
});

it('mengizinkan konsumen membatalkan order PLACED', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc('orders/o2').set({
      consumerUid: 'u1', status: 'PLACED', participants: ['u1'], version: 1,
    });
  });
  await assertSucceeds(consumer().doc('orders/o2').update({ status: 'CANCELLED', version: 2 }));
});
```

Daftar kasus minimum mengikuti `UserRole.md` §9.

### 9.2 Tes Gateway

| Tes | Tujuan |
|---|---|
| `computeCommission` tabel | Pembulatan dan minimum |
| Klaim konkuren (dua panggilan `Promise.all`) | Tepat satu sukses |
| `completeOrder` dipanggil dua kali | Komisi dipotong sekali |
| PIN salah 5× | Kunci 10 menit |
| Unggah non-WebP / > 85 KB | 415 / 413 |
| URL bertanda tangan kedaluwarsa | 403 |

### 9.3 Tes Klien

| Tes | Alat |
|---|---|
| ETA 1.200 m = 216 dtk, kecepatan terkoreksi 10–30 km/jam | `flutter test` |
| Dijkstra pada graf sampel dan graf kampus nyata (tidak ada simpul yatim) | `flutter test` |
| Animator: progres tidak melewati 0,95 | `flutter test` |
| Alur order end-to-end | `integration_test` dengan emulator Firebase |
| Pratinjau kontras dan skala font 200% | Uji manual + golden tests |

## 10. Konvensi dan Anggaran Kinerja

| Area | Konvensi |
|---|---|
| Penamaan | Dart `lowerCamelCase`/`UpperCamelCase`; koleksi Firestore `camelCase` |
| Uang | `int` Rupiah; tidak ada `double` untuk uang |
| Waktu | UTC pada server; tampilan zona waktu perangkat (WIB) |
| Query | Selalu `limit()`; `onSnapshot` hanya pada dokumen/koleksi kecil bermanfaat |
| State | Riverpod; tidak ada logika bisnis di widget |
| Error | Kode galat Gateway dipetakan ke pesan i18n di satu tempat |
| Logging | Terstruktur JSON; tanpa PIN, token, atau isi chat |
| Komit | Conventional Commits; satu PR = satu tujuan |

| Anggaran | Target |
|---|---|
| Cold start Android 8 / 3 GB | ≤ 3 dtk |
| Frame layar peta 3D | ≥ 30 fps, jatuh ke 2D bila < 24 fps |
| Ukuran APK | ≤ 40 MB |
| Gambar | ≤ 80 KB per berkas |
| Baca Firestore per DAU | ≤ 12 per hari |
| Tulis Firestore per order | ≈ 37 |

## 11. Langkah Setup Awal (Urutan)

1. Buat tiga proyek Firebase (`dev`, `stg`, `prod`), aktifkan Auth Google, Firestore, FCM, Remote Config, App Check.
2. Buat bucket R2 `ce-public` dan `ce-private` per lingkungan; pastikan `ce-private` tidak memiliki domain publik.
3. Deploy Rules dan indeks: `firebase deploy --only firestore`.
4. Seed `config/app`, `landmarks`, `zones`, `fareMatrix`, `config/landmarkGraph`, `stats/campus` lewat `tools/seed`.
5. Atur rahasia Gateway (`secrets.md` §5.1) dan deploy: `wrangler deploy`.
6. Aktifkan TTL (`messages.expireAt`, `salesPings.expireAt`).
7. Jalankan tes rules dan Gateway di CI; atur gerbang rilis (`safe-change-rules.md`).
8. Buat akun admin pertama lewat skrip terkontrol (`UserRole.md` §7).
9. Pilot tertutup sesuai `PRD.md` §7.