/**
 * Seeder Landmark Hub UINSU Tuntungan (Fase 5).
 *
 * Pemakaian:
 *   npm run build:functions
 *   npx tsx scripts/seed-tuntungan-hub.ts --emulator
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npx tsx scripts/seed-tuntungan-hub.ts
 *   GOOGLE_APPLICATION_CREDENTIALS=... npx tsx scripts/seed-tuntungan-hub.ts
 *
 * Menulis 6 landmark riil Kampus IV UINSU Tuntungan (Zona 1–3) + dokumen
 * `config/tuntungan_hub` berisi metadata tier rekomendasi OSRM. Idempoten.
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

let hubModule: typeof import('../backend/functions/lib/core/tuntunganHub.js');
try {
  hubModule = require('./lib/core/tuntunganHub.js');
} catch (error) {
  console.error(
    'Modul engine belum dibangun. Jalankan `npm run build:functions` terlebih dahulu.',
  );
  throw error;
}

const { TUNTUNGAN_HUB_LANDMARKS, seedTuntunganHub } = hubModule;

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

  console.log('\nCampus Express — Seeder Hub UINSU Tuntungan');
  console.log(`Target: ${target}\n`);

  const result = await seedTuntunganHub(db);

  for (const landmark of TUNTUNGAN_HUB_LANDMARKS) {
    console.log(
      `  [${landmark.zone_group}] ${landmark.id.padEnd(28)} ` +
        `${landmark.name} (${landmark.latitude}, ${landmark.longitude})`,
    );
  }

  console.log(
    `\nSelesai: ${result.landmarkCount} landmark ` +
      `(${result.zone1Count} Zona 1, ${result.zone2Count} Zona 2, ` +
      `${result.zone3Count} Zona 3).`,
  );
  console.log('\nTier rekomendasi OSRM:');
  console.log('  Tier 1 (0-1,0 km)      = Rp 5.000');
  console.log('  Tier 2 (1,0-2,5 km)    = Rp 7.000');
  console.log('  Tier 3 (>2,5 km)       = Rp 7.000 + Rp 2.000/km berikutnya\n');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});