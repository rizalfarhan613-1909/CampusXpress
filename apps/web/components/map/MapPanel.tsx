'use client';

import dynamic from 'next/dynamic';

/**
 * Peta Leaflet dimuat hanya di klien (SSR dimatikan) agar `window`/`document`
 * tidak dievaluasi saat static export Next.js.
 */
const TuntunganMap = dynamic(() => import('./TuntunganMap'), {
  ssr: false,
  loading: () => (
    <div className="grid h-[340px] place-items-center rounded-lg border border-line-subtle bg-lav-100 text-body-s text-text-muted">
      Memuat peta OpenStreetMap…
    </div>
  ),
});

/** Koordinat WGS84 sederhana (derajat) untuk penempatan marker & rute peta. */
export interface MapCoordinate {
  latitude: number;
  longitude: number;
}

export function MapPanel({
  height = 340,
  highlightId,
  driver,
  route,
}: {
  height?: number;
  highlightId?: string;
  /** Posisi driver realtime; kosong = titik tengah jalur menuju tujuan. */
  driver?: MapCoordinate | null;
  /** Rute OSRM `[lat, lng]`; kosong = garis hub → tujuan. */
  route?: ReadonlyArray<[number, number]>;
}) {
  return (
    <TuntunganMap
      height={height}
      highlightId={highlightId}
      driver={driver}
      route={route}
    />
  );
}