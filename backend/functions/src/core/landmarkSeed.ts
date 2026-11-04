import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import {
  ZONE_1,
  ZONE_2,
  ZONE_FARE_MATRIX,
  type CampusZone,
} from './fareMatrix';

export interface SeedLandmark {
  id: string;
  name: string;
  zone_group: CampusZone;
}

/**
 * 11 landmark preset sesuai PRD M03. Tidak ada alamat bebas.
 * Field mengikuti skema Fase 1 (id, name, zone_group).
 */
export const SEED_LANDMARKS: readonly SeedLandmark[] = [
  // Zona 1 — area dalam kampus
  { id: 'gedung-kuliah-terpadu', name: 'Gedung Kuliah Terpadu', zone_group: ZONE_1 },
  { id: 'perpustakaan-pusat', name: 'Perpustakaan Pusat', zone_group: ZONE_1 },
  { id: 'fakultas-saintek', name: 'Fakultas Saintek', zone_group: ZONE_1 },
  { id: 'fakultas-ekonomi', name: 'Fakultas Ekonomi', zone_group: ZONE_1 },
  { id: 'masjid-kampus', name: 'Masjid Kampus', zone_group: ZONE_1 },
  { id: 'lapangan-utama', name: 'Lapangan Utama', zone_group: ZONE_1 },

  // Zona 2 — area luar/gerbang
  { id: 'gate-utama', name: 'Gate Utama', zone_group: ZONE_2 },
  { id: 'gate-2', name: 'Gate 2', zone_group: ZONE_2 },
  { id: 'kost-gang-melati', name: 'Area Kost Gang Melati', zone_group: ZONE_2 },
  { id: 'kost-gang-mawar', name: 'Area Kost Gang Mawar', zone_group: ZONE_2 },
  { id: 'kantin-pusat-b', name: 'Kantin Pusat B', zone_group: ZONE_2 },
];

export interface SeedLandmarksResult {
  landmarkCount: number;
  zone1Count: number;
  zone2Count: number;
  ids: string[];
}

/**
 * Seeder idempoten. Menulis ulang 11 landmark preset dan matriks tarif.
 * Menggunakan batch karena tidak ada operasi baca-yang-diubah (bukan transaksi bisnis).
 */
export async function seedLandmarks(db: Firestore): Promise<SeedLandmarksResult> {
  const batch = db.batch();
  const landmarks = db.collection('landmarks');

  for (const landmark of SEED_LANDMARKS) {
    batch.set(
      landmarks.doc(landmark.id),
      {
        id: landmark.id,
        name: landmark.name,
        zone_group: landmark.zone_group,
      },
      { merge: true },
    );
  }

  batch.set(
    db.collection('config').doc('fare_matrix'),
    {
      zone_rates: ZONE_FARE_MATRIX,
      updated_at: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  await batch.commit();

  return {
    landmarkCount: SEED_LANDMARKS.length,
    zone1Count: SEED_LANDMARKS.filter((item) => item.zone_group === ZONE_1).length,
    zone2Count: SEED_LANDMARKS.filter((item) => item.zone_group === ZONE_2).length,
    ids: SEED_LANDMARKS.map((item) => item.id),
  };
}
