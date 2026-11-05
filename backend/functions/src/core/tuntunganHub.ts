import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { FARE_TIERS } from './osrmRouting';

/**
 * Fase 5 — Seed landmark riil area Kampus IV UINSU Tuntungan.
 *
 * Koordinat adalah titik acuan operasional (perlu diverifikasi ulang dengan
 * survei lapangan sebelum publikasi). Zona mengikuti pembagian radius layanan:
 * - Zona 1: dalam kampus (rektorat, FST, pujasera)
 * - Zona 2: kos & permukiman ring dekat (Jl. Lapangan Golf)
 * - Zona 3: koridor luar (Simpang Tuntungan, Pasar Induk Lau Cih)
 */
export type TuntunganZone = 'Zona 1' | 'Zona 2' | 'Zona 3';

export interface TuntunganLandmark {
  id: string;
  name: string;
  zone_group: TuntunganZone;
  latitude: number;
  longitude: number;
  type: string;
}

export const TUNTUNGAN_HUB_LANDMARKS: readonly TuntunganLandmark[] = [
  {
    id: 'gedung-fst-uinsu',
    name: 'Gedung FST UINSU Tuntungan',
    zone_group: 'Zona 1',
    latitude: 3.5479,
    longitude: 98.6469,
    type: 'gedung',
  },
  {
    id: 'gedung-rektorat-dekanat',
    name: 'Gedung Rektorat & Dekanat',
    zone_group: 'Zona 1',
    latitude: 3.5473,
    longitude: 98.6462,
    type: 'gedung',
  },
  {
    id: 'pujasera-kantin-kampus',
    name: 'Pujasera Kantin Kampus',
    zone_group: 'Zona 1',
    latitude: 3.5484,
    longitude: 98.6476,
    type: 'kantin',
  },
  {
    id: 'kos-jl-lapangan-golf',
    name: 'Area Kos Jl. Lapangan Golf',
    zone_group: 'Zona 2',
    latitude: 3.5495,
    longitude: 98.6488,
    type: 'kost',
  },
  {
    id: 'tugu-simpang-tuntungan',
    name: 'Tugu / Simpang Tuntungan',
    zone_group: 'Zona 3',
    latitude: 3.5469,
    longitude: 98.6505,
    type: 'gerbang',
  },
  {
    id: 'pasar-induk-lau-cih',
    name: 'Pasar Induk Lau Cih',
    zone_group: 'Zona 3',
    latitude: 3.5523,
    longitude: 98.6542,
    type: 'pasar',
  },
];

export interface SeedTuntunganResult {
  landmarkCount: number;
  zone1Count: number;
  zone2Count: number;
  zone3Count: number;
  ids: string[];
}

/** Seeder idempoten: menimpa 6 landmark hub + metadata tier OSRM. */
export async function seedTuntunganHub(
  db: Firestore,
): Promise<SeedTuntunganResult> {
  const batch = db.batch();
  const landmarks = db.collection('landmarks');

  for (const landmark of TUNTUNGAN_HUB_LANDMARKS) {
    batch.set(
      landmarks.doc(landmark.id),
      {
        id: landmark.id,
        name: landmark.name,
        zone_group: landmark.zone_group,
        lat: landmark.latitude,
        lng: landmark.longitude,
        type: landmark.type,
      },
      { merge: true },
    );
  }

  batch.set(
    db.collection('config').doc('tuntungan_hub'),
    {
      hub_id: 'uinsu-tuntungan',
      name: 'Kampus IV UINSU Tuntungan',
      center: { lat: 3.5479, lng: 98.6469 },
      fare_tiers: FARE_TIERS,
      osrm_profile: 'driving',
      updated_at: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  await batch.commit();

  return {
    landmarkCount: TUNTUNGAN_HUB_LANDMARKS.length,
    zone1Count: TUNTUNGAN_HUB_LANDMARKS.filter((l) => l.zone_group === 'Zona 1').length,
    zone2Count: TUNTUNGAN_HUB_LANDMARKS.filter((l) => l.zone_group === 'Zona 2').length,
    zone3Count: TUNTUNGAN_HUB_LANDMARKS.filter((l) => l.zone_group === 'Zona 3').length,
    ids: TUNTUNGAN_HUB_LANDMARKS.map((l) => l.id),
  };
}