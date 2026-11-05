/**
 * Data hub UINSU Tuntungan + rekomendasi harga OSRM untuk web.
 * Nilai tier identik dengan `backend/functions/src/core/osrmRouting.ts` agar UI
 * dan server tidak pernah menampilkan angka berbeda.
 */

export type HubZone = 'Zona 1' | 'Zona 2' | 'Zona 3';

export interface HubLandmark {
  id: string;
  name: string;
  zone: HubZone;
  latitude: number;
  longitude: number;
  type: string;
}

/** 6 landmark riil Kampus IV UINSU Tuntungan (Fase 5). */
export const TUNTUNGAN_LANDMARKS: readonly HubLandmark[] = [
  {
    id: 'gedung-fst-uinsu',
    name: 'Gedung FST UINSU Tuntungan',
    zone: 'Zona 1',
    latitude: 3.5479,
    longitude: 98.6469,
    type: 'gedung',
  },
  {
    id: 'gedung-rektorat-dekanat',
    name: 'Gedung Rektorat & Dekanat',
    zone: 'Zona 1',
    latitude: 3.5473,
    longitude: 98.6462,
    type: 'gedung',
  },
  {
    id: 'pujasera-kantin-kampus',
    name: 'Pujasera Kantin Kampus',
    zone: 'Zona 1',
    latitude: 3.5484,
    longitude: 98.6476,
    type: 'kantin',
  },
  {
    id: 'kos-jl-lapangan-golf',
    name: 'Area Kos Jl. Lapangan Golf',
    zone: 'Zona 2',
    latitude: 3.5495,
    longitude: 98.6488,
    type: 'kost',
  },
  {
    id: 'tugu-simpang-tuntungan',
    name: 'Tugu / Simpang Tuntungan',
    zone: 'Zona 3',
    latitude: 3.5469,
    longitude: 98.6505,
    type: 'gerbang',
  },
  {
    id: 'pasar-induk-lau-cih',
    name: 'Pasar Induk Lau Cih',
    zone: 'Zona 3',
    latitude: 3.5523,
    longitude: 98.6542,
    type: 'pasar',
  },
];

export const HUB_CENTER = { latitude: 3.5479, longitude: 98.6469 } as const;

export interface FareRecommendation {
  tier: 1 | 2 | 3;
  basePrice: number;
  minPrice: number;
  maxPrice: number;
  distanceKm: number;
  label: string;
}

const rupiah = (amount: number) => `Rp ${Math.round(amount).toLocaleString('id-ID')}`;
const roundTo = (value: number, step: number) => Math.round(value / step) * step;

/** Rumus tier: 5.000 / 7.000 / 7.000 + 2.000 per km berikutnya. */
export function recommendFare(distanceMeters: number): FareRecommendation {
  const meters = Number.isFinite(distanceMeters) && distanceMeters > 0 ? distanceMeters : 0;
  const km = meters / 1000;

  let tier: 1 | 2 | 3;
  let basePrice: number;
  if (km <= 1) {
    tier = 1;
    basePrice = 5000;
  } else if (km <= 2.5) {
    tier = 2;
    basePrice = 7000;
  } else {
    tier = 3;
    basePrice = 7000 + 2000 * Math.ceil(km - 2.5);
  }

  const minPrice = Math.max(5000, roundTo(basePrice - 1000, 500));
  const maxPrice = Math.max(minPrice, roundTo(basePrice + 1000, 500));

  return {
    tier,
    basePrice,
    minPrice,
    maxPrice,
    distanceKm: Math.round(km * 10) / 10,
    label: `Jarak ${km.toFixed(1)} km • Rekomendasi: ${rupiah(minPrice)} - ${rupiah(maxPrice)}`,
  };
}

export function formatRecommendationBadge(distanceMeters: number): string {
  return recommendFare(distanceMeters).label;
}