/**
 * Seeder Landmark & Tarif Kampus (PRD M03, X3).
 *
 * Pemakaian:
 *   npm run build:functions
 *   npx tsx scripts/seedLandmarks.ts --emulator     # Firebase Emulator
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npx tsx scripts/seedLandmarks.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=... npx tsx scripts/seedLandmarks.ts
 *
 * Skrip idempoten: menjalankan ulang hanya menimpa 11 landmark preset dan
 * dokumen config/fare_matrix.
 */
import { createRequire } from 'node:module';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const require = createRequire(
  path.join(fileURLToPath(new URL('.', import.meta.url)), '../backend/functions/package.json'),
);
const args = new Set(process.argv.slice(2));

if (args.has('--emulator') && !process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
}

const projectId =
  process.env.FIREBASE_PROJECT_ID ??
  process.env.GCLOUD_PROJECT ??
  'campus-express-dev';

const { applicationDefault, getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

let seedModule: typeof import('../backend/functions/lib/core/landmarkSeed.js');
try {
  seedModule = require('./lib/core/landmarkSeed.js');
} catch (error) {
  console.error(
    'Modul engine belum dibangun. Jalankan `npm run build:functions` terlebih dahulu.',
  );
  throw error;
}

const { SEED_LANDMARKS, seedLandmarks } = seedModule;
const { calculateDeliveryFee, ZONE_FARE_MATRIX } = require(
  './lib/core/fareMatrix.js',
) as typeof import('../backend/functions/lib/core/fareMatrix.js');

async function main(): Promise<void> {
  if (getApps().length === 0) {
    initializeApp({
      projectId,
      ...(process.env.FIRESTORE_EMULATOR_HOST
        ? {}
        : { credential: applicationDefault() }),
    });
  }

  const db = getFirestore();
  const target = process.env.FIRESTORE_EMULATOR_HOST
    ? `Emulator (${process.env.FIRESTORE_EMULATOR_HOST})`
    : `Project ${projectId}`;

  console.log(`\nCampus Express — Seeder Landmark & Tarif`);
  console.log(`Target: ${target}\n`);

  const result = await seedLandmarks(db);

  for (const landmark of SEED_LANDMARKS) {
    console.log(`  [${landmark.zone_group}] ${landmark.id.padEnd(24)} ${landmark.name}`);
  }

  console.log(
    `\nSelesai: ${result.landmarkCount} landmark (${result.zone1Count} Zona 1, ${result.zone2Count} Zona 2).`,
  );
  console.log('\nMatriks ongkir:');
  console.log(
    `  Zona 1 -> Zona 1 = Rp ${ZONE_FARE_MATRIX['Zona 1']['Zona 1'].toLocaleString('id-ID')}`,
  );
  console.log(
    `  Zona 1 -> Zona 2 = Rp ${calculateDeliveryFee('Zona 1', 'Zona 2').toLocaleString('id-ID')}`,
  );
  console.log(
    `  Zona 2 -> Zona 2 = Rp ${ZONE_FARE_MATRIX['Zona 2']['Zona 2'].toLocaleString('id-ID')}\n`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
