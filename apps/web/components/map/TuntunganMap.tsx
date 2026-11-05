'use client';

import 'leaflet/dist/leaflet.css';
import { divIcon, type DivIcon } from 'leaflet';
import { MapContainer, Marker, Polyline, Popup, TileLayer } from 'react-leaflet';
import { HUB_CENTER, TUNTUNGAN_LANDMARKS, type HubLandmark } from '@/lib/tuntungan';

/** Tile OSM publik; dapat dioverride lewat variabel publik (bukan rahasia). */
const OSM_TILE_URL =
  process.env.NEXT_PUBLIC_OSM_TILE_URL ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const OSM_ATTRIBUTION = '&copy; OpenStreetMap contributors';

/** Palet marker kustom — Design.md §A.1 (`primary`, `star`, `danger`). */
const EMERALD = '#006C4A';
const AMBER = '#F59E0B';
const DROP_RED = '#BA1A1A';

type Coordinate = { latitude: number; longitude: number };
type LatLngTuple = [number, number];

/**
 * Glif SVG inline (Material Symbols, gaya `components/ui/Icon.tsx`) berformat
 * outline putih 1,9 px agar tetap terbaca di atas badge marker berwarna.
 */
const GLYPHS = {
  /** `two_wheeler` — motor driver. */
  motor:
    'M19.44 9.03 15.41 5H11v2h3.59l2 2H13c-2.8 0-5 2.2-5 5s2.2 5 5 5 5-2.2 5-5c0-2.8-2.2-5-5-5h1.5l-1.5 1.75V19h2v-5.5l3.5-4.03 1.44 1.52a3.49 3.49 0 0 0-.94 2.01c0 1.93 1.57 3.5 3.5 3.5s3.5-1.57 3.5-3.5-1.57-3.5-3.5-3.5c-2.09 0-3.72 1.85-3.5 3.99zM5 12c-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4-1.79-4-4-4zm0 6c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2z',
  /** `restaurant` — sendok-garpu untuk kantin/pujasera. */
  restaurant:
    'M11 9H9V2H7v7H5V2H3v7c0 2.12 1.66 3.84 3.75 3.97V22h2.5v-9.03C11.34 12.84 13 11.12 13 9V2h-2v7zm5-3v8h2.5v8H21V2c-2.76 0-5 2.24-5 4z',
  /** `store` — toko untuk pasar/merchant. */
  store: 'M20 4H4v2h16V4zm1 10v-2l-1-5H4l-1 5v2h1v6h10v-6h4v6h2v-6h1zm-9 4H6v-4h6v4z',
  /** `school` — gedung kampus. */
  school: 'M12 3 1 9l11 6 9-4.91V17h2V9L12 3zM5 13.18v4L12 21l7-3.82v-4L12 17l-7-3.82z',
  /** `location_on` — penanda lokasi umum. */
  place:
    'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5A2.5 2.5 0 1 1 12 6.5a2.5 2.5 0 0 1 0 5z',
  /** `location_on` terisi untuk pin tujuan. */
  pin: 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5A2.5 2.5 0 1 1 12 6.5a2.5 2.5 0 0 1 0 5z',
} as const;

function outlineGlyph(path: string, size: number): string {
  return `<svg viewBox="0 0 24 24" width="${size}" height="${size}" fill="none" stroke="#FFFFFF" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="${path}"/></svg>`;
}

function filledGlyph(path: string, size: number, color: string): string {
  return `<svg viewBox="0 0 24 24" width="${size}" height="${size}" fill="${color}" aria-hidden="true"><path d="${path}"/></svg>`;
}

/** Cegah injeksi markup saat nama landmark disisipkan ke `divIcon`. */
function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/**
 * Marker driver (motor): badge bundar emerald `#006C4A` berikon motor putih,
 * dikelilingi gelombang animasi (`animate-ping`) sebagai indikator live.
 */
function driverIcon(): DivIcon {
  return divIcon({
    className: 'ce-marker',
    iconSize: [56, 56],
    iconAnchor: [28, 28],
    popupAnchor: [0, -28],
    html: `
      <span class="relative flex h-14 w-14 items-center justify-center">
        <span class="absolute inset-0 m-auto h-10 w-10 animate-ping rounded-full opacity-60" style="background:${EMERALD}"></span>
        <span class="relative inline-flex h-10 w-10 items-center justify-center rounded-full border-2 border-white shadow-lg" style="background:${EMERALD}">
          ${outlineGlyph(GLYPHS.motor, 22)}
        </span>
      </span>
    `,
  });
}

/** Marker UMKM (kantin/toko): badge amber `#F59E0B` berikon sendok-garpu/toko. */
function merchantIcon(glyph: string): DivIcon {
  return divIcon({
    className: 'ce-marker',
    iconSize: [40, 40],
    iconAnchor: [20, 20],
    popupAnchor: [0, -20],
    html: `
      <span class="flex h-9 w-9 items-center justify-center rounded-full border-2 border-white shadow-md" style="background:${AMBER}">
        ${outlineGlyph(glyph, 18)}
      </span>
    `,
  });
}

/** Marker landmark umum: badge emerald kecil berikon gedung/lokasi. */
function landmarkIcon(glyph: string): DivIcon {
  return divIcon({
    className: 'ce-marker',
    iconSize: [36, 36],
    iconAnchor: [18, 18],
    popupAnchor: [0, -18],
    html: `
      <span class="flex h-8 w-8 items-center justify-center rounded-full border-2 border-white shadow-sm" style="background:${EMERALD}">
        ${outlineGlyph(glyph, 16)}
      </span>
    `,
  });
}

/** Marker tujuan (drop-off): pin merah `#BA1A1A` berlabel nama gedung. */
function dropoffIcon(label: string): DivIcon {
  return divIcon({
    className: 'ce-marker',
    iconSize: [168, 60],
    iconAnchor: [84, 58],
    popupAnchor: [0, -58],
    html: `
      <div class="flex w-[168px] flex-col items-center">
        <span class="max-w-[160px] truncate rounded-full px-2.5 py-1 text-[11px] font-bold text-white shadow-lg" style="background:${DROP_RED}">${escapeHtml(label)}</span>
        <span class="mt-0.5">${filledGlyph(GLYPHS.pin, 30, DROP_RED)}</span>
      </div>
    `,
  });
}

/** Label ramah untuk pin tujuan (mis. `Gedung FST` → "Lobi Utama FST"). */
function shortLabel(landmark: HubLandmark): string {
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

type MarkerKind = 'destination' | 'merchant' | 'landmark';

function markerKind(landmark: HubLandmark, isDestination: boolean): MarkerKind {
  if (isDestination) return 'destination';
  if (landmark.type === 'kantin' || landmark.type === 'pasar') return 'merchant';
  return 'landmark';
}

function iconFor(kind: MarkerKind, landmark: HubLandmark): DivIcon {
  switch (kind) {
    case 'destination':
      return dropoffIcon(shortLabel(landmark));
    case 'merchant':
      return merchantIcon(landmark.type === 'pasar' ? GLYPHS.store : GLYPHS.restaurant);
    default:
      return landmarkIcon(landmark.type === 'gedung' ? GLYPHS.school : GLYPHS.place);
  }
}

export interface TuntunganMapProps {
  height?: number;
  highlightId?: string;
  /** Koordinat driver realtime; bila kosong dipakai titik tengah jalur. */
  driver?: Coordinate | null;
  /** Rute OSRM `[lat, lng]`; bila kosong digambar garis hub → tujuan. */
  route?: ReadonlyArray<LatLngTuple>;
}

/**
 * Peta Leaflet + tile OpenStreetMap untuk hub UINSU Tuntungan.
 * Dipakai oleh papan bidding web (`/tracking/`).
 *
 * Penanda memakai ikon kustom (`L.divIcon`), bukan bulatan polos: badge motor
 * emerald berdenyut untuk driver, badge amber untuk UMKM, dan pin merah
 * berlabel untuk tujuan. Jalur digambar sebagai polyline emerald putus-putus.
 */
export default function TuntunganMap({
  height = 340,
  highlightId,
  driver,
  route,
}: TuntunganMapProps) {
  const destination =
    TUNTUNGAN_LANDMARKS.find((landmark) => landmark.id === highlightId) ??
    TUNTUNGAN_LANDMARKS[0];

  // Titik awal jalur: pusat hub, kecuali hub sendiri yang menjadi tujuan.
  const origin =
    destination.id === 'gedung-fst-uinsu'
      ? TUNTUNGAN_LANDMARKS.find((landmark) => landmark.id === 'pasar-induk-lau-cih') ??
        TUNTUNGAN_LANDMARKS[1]
      : HUB_CENTER;

  const destinationPosition: LatLngTuple = [destination.latitude, destination.longitude];
  const driverPosition: LatLngTuple = driver
    ? [driver.latitude, driver.longitude]
    : [
        (origin.latitude + destination.latitude) / 2,
        (origin.longitude + destination.longitude) / 2,
      ];

  const routePositions: LatLngTuple[] =
    route && route.length > 1
      ? route.map(([latitude, longitude]) => [latitude, longitude])
      : [[origin.latitude, origin.longitude], driverPosition, destinationPosition];

  const routeLabel = route && route.length > 1 ? 'Rute OSRM' : 'Jalur perkiraan';

  return (
    <div className="overflow-hidden rounded-lg border border-line-subtle" style={{ height }}>
      <MapContainer
        center={[HUB_CENTER.latitude, HUB_CENTER.longitude]}
        zoom={15}
        scrollWheelZoom={false}
        style={{ height: '100%', width: '100%' }}
      >
        <TileLayer attribution={OSM_ATTRIBUTION} url={OSM_TILE_URL} />

        <Polyline
          positions={routePositions}
          pathOptions={{
            color: EMERALD,
            weight: 5,
            opacity: 0.9,
            dashArray: '10 12',
            lineCap: 'round',
          }}
        />

        {TUNTUNGAN_LANDMARKS.map((landmark) => {
          const kind = markerKind(landmark, landmark.id === destination.id);
          return (
            <Marker
              key={landmark.id}
              position={[landmark.latitude, landmark.longitude]}
              icon={iconFor(kind, landmark)}
              zIndexOffset={kind === 'destination' ? 500 : 0}
            >
              <Popup>
                <strong>{landmark.name}</strong>
                <br />
                {landmark.zone} · {landmark.type}
              </Popup>
            </Marker>
          );
        })}

        <Marker position={driverPosition} icon={driverIcon()} zIndexOffset={900}>
          <Popup>
            <strong>Driver menuju lokasi</strong>
            <br />
            {routeLabel} · badge motor emerald
          </Popup>
        </Marker>
      </MapContainer>
    </div>
  );
}