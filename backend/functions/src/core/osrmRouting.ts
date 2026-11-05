/**
 * Fase 5 — OSRM Routing Engine + rekomendasi harga area UINSU Tuntungan.
 *
 * Jarak jalan riil diambil dari OSRM publik:
 *   GET http://router.project-osrm.org/route/v1/driving/{lng1},{lat1};{lng2},{lat2}?overview=false
 *
 * Bila jaringan/emulator tidak tersedia, helper jatuh ke haversine × faktor
 * jalan 1,3 sehingga kalkulasi tetap deterministik untuk pengujian.
 */
export const DEFAULT_OSRM_BASE_URL = 'http://router.project-osrm.org';
export const OSRM_TIMEOUT_MS = 4_000;

/** Kecepatan motor rata-rata kampus (km/jam) — sama dengan AppConfig mobile. */
export const MOTORCYCLE_KMH = 20;

/** Faktor jalan: jarak rute ≈ 1,3 × jarak garis lurus. */
export const ROAD_FACTOR = 1.3;

export interface Coordinate {
  latitude: number;
  longitude: number;
}

export type FareTier = 1 | 2 | 3;

export interface FareTierSpec {
  tier: FareTier;
  minKm: number;
  maxKm: number;
  basePrice: number;
  label: string;
}

export const FARE_TIERS: readonly FareTierSpec[] = [
  {
    tier: 1,
    minKm: 0,
    maxKm: 1,
    basePrice: 5_000,
    label: 'Ring 1 kampus & kos dekat',
  },
  {
    tier: 2,
    minKm: 1,
    maxKm: 2.5,
    basePrice: 7_000,
    label: 'Simpang Tuntungan, Pasar Induk Lau Cih',
  },
  {
    tier: 3,
    minKm: 2.5,
    maxKm: 5,
    basePrice: 7_000,
    label: 'Outer Tuntungan & Medan',
  },
];

export interface RouteResult {
  distanceMeters: number;
  durationSeconds: number;
  source: 'OSRM' | 'HAVERSINE';
}

export interface FareRecommendation {
  distanceMeters: number;
  distanceKm: number;
  tier: FareTier;
  basePrice: number;
  minPrice: number;
  maxPrice: number;
  estimatedArrivalMinutes: number;
  label: string;
}

const RAD = Math.PI / 180;

export function haversineMeters(from: Coordinate, to: Coordinate): number {
  const dLat = (to.latitude - from.latitude) * RAD;
  const dLon = (to.longitude - from.longitude) * RAD;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(from.latitude * RAD) *
      Math.cos(to.latitude * RAD) *
      Math.sin(dLon / 2) ** 2;
  return 6_371_000 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function roundTo(value: number, step: number): number {
  return Math.round(value / step) * step;
}

function rupiah(amount: number): string {
  return `Rp ${Math.round(amount).toLocaleString('id-ID')}`;
}

export function estimateMotorcycleDurationSeconds(
  meters: number,
  kmh = MOTORCYCLE_KMH,
): number {
  if (!Number.isFinite(meters) || meters <= 0) return 0;
  return Math.round((meters / 1000 / kmh) * 3600);
}

/**
 * Rentang harga rekomendasi dari jarak jalan riil.
 *
 * - Tier 1 (0 – 1,0 km): basis Rp 5.000
 * - Tier 2 (1,0 – 2,5 km): basis Rp 7.000
 * - Tier 3 (> 2,5 km): Rp 7.000 + Rp 2.000 per km berikutnya
 *
 * Pita rekomendasi = basis ± Rp 1.000, dibulatkan ke Rp 500 dan minimal
 * Rp 5.000, sehingga jarak 2,1 km menghasilkan Rp 6.000 – Rp 8.000.
 */
export function recommendFare(distanceMeters: number): FareRecommendation {
  const safeMeters =
    Number.isFinite(distanceMeters) && distanceMeters > 0 ? distanceMeters : 0;
  const km = safeMeters / 1000;

  let tier: FareTier;
  let basePrice: number;
  if (km <= 1) {
    tier = 1;
    basePrice = 5_000;
  } else if (km <= 2.5) {
    tier = 2;
    basePrice = 7_000;
  } else {
    tier = 3;
    basePrice = 7_000 + 2_000 * Math.ceil(km - 2.5);
  }

  const minPrice = Math.max(5_000, roundTo(basePrice - 1_000, 500));
  const maxPrice = Math.max(minPrice, roundTo(basePrice + 1_000, 500));
  const estimatedArrivalMinutes = Math.max(
    1,
    Math.round(estimateMotorcycleDurationSeconds(safeMeters) / 60),
  );

  return {
    distanceMeters: Math.round(safeMeters),
    distanceKm: Math.round(km * 10) / 10,
    tier,
    basePrice,
    minPrice,
    maxPrice,
    estimatedArrivalMinutes,
    label: `Jarak ${km.toFixed(1)} km • Rekomendasi: ${rupiah(minPrice)} - ${rupiah(maxPrice)}`,
  };
}

/** Badge UI: "Jarak 2.1 km • Rekomendasi: Rp 6.000 - Rp 8.000". */
export function formatRecommendationBadge(distanceMeters: number): string {
  return recommendFare(distanceMeters).label;
}

interface OsrmResponse {
  code?: string;
  routes?: Array<{ distance?: number; duration?: number }>;
}

export interface OSRMOptions {
  baseUrl?: string;
  timeoutMs?: number;
  /** Pengganti fetch untuk pengujian tanpa jaringan. */
  fetcher?: typeof fetch;
}

/**
 * Memanggil OSRM dan mengembalikan jarak/tempuh. Kegagalan jaringan tidak
 * pernah melempar error: hasil haversine dikembalikan dengan `source:
 * 'HAVERSINE'` agar UI tetap menampilkan rekomendasi.
 */
export async function fetchOsrmRoute(
  from: Coordinate,
  to: Coordinate,
  options: OSRMOptions = {},
): Promise<RouteResult> {
  const baseUrl = (options.baseUrl ?? DEFAULT_OSRM_BASE_URL).replace(/\/+$/, '');
  const fetcher = options.fetcher ?? globalThis.fetch;
  const url =
    `${baseUrl}/route/v1/driving/` +
    `${from.longitude},${from.latitude};${to.longitude},${to.latitude}` +
    '?overview=false';

  if (typeof fetcher !== 'function') {
    return fallbackRoute(from, to);
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), options.timeoutMs ?? OSRM_TIMEOUT_MS);
  try {
    const response = await fetcher(url, { signal: controller.signal });
    if (!response.ok) return fallbackRoute(from, to);
    const json = (await response.json()) as OsrmResponse;
    const route = json.routes?.[0];
    const distance = route?.distance;
    const duration = route?.duration;
    if (
      json.code !== 'Ok' ||
      typeof distance !== 'number' ||
      !Number.isFinite(distance) ||
      distance <= 0
    ) {
      return fallbackRoute(from, to);
    }
    return {
      distanceMeters: Math.round(distance),
      durationSeconds:
        typeof duration === 'number' && Number.isFinite(duration)
          ? Math.round(duration)
          : estimateMotorcycleDurationSeconds(distance),
      source: 'OSRM',
    };
  } catch {
    return fallbackRoute(from, to);
  } finally {
    clearTimeout(timer);
  }
}

export function fallbackRoute(from: Coordinate, to: Coordinate): RouteResult {
  const distanceMeters = Math.round(haversineMeters(from, to) * ROAD_FACTOR);
  return {
    distanceMeters,
    durationSeconds: estimateMotorcycleDurationSeconds(distanceMeters),
    source: 'HAVERSINE',
  };
}

export interface FareEstimate extends FareRecommendation {
  durationSeconds: number;
  source: RouteResult['source'];
}

/** Kunci pasangan koordinat untuk cache/idempotensi. */
export function compareCoordinates(from: Coordinate, to: Coordinate): string {
  return (
    `${from.latitude.toFixed(6)},${from.longitude.toFixed(6)}>` +
    `${to.latitude.toFixed(6)},${to.longitude.toFixed(6)}`
  );
}

/** Rute + rekomendasi harga dalam satu panggilan. */
export async function estimateFare(
  from: Coordinate,
  to: Coordinate,
  options: OSRMOptions = {},
): Promise<FareEstimate> {
  const route = await fetchOsrmRoute(from, to, options);
  const recommendation = recommendFare(route.distanceMeters);
  return {
    ...recommendation,
    durationSeconds: route.durationSeconds,
    source: route.source,
  };
}