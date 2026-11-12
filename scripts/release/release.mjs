#!/usr/bin/env node
/**
 * Campus Express — CLI rilis Fase 6 (Firebase, Cloudflare Workers, Web, APK).
 *
 * Semua perintah dijalankan dari root repo:
 *
 *   node scripts/release/release.mjs preflight
 *   node scripts/release/release.mjs firebase --project=campus-express-prod
 *   node scripts/release/release.mjs seed --project=campus-express-prod --yes
 *   node scripts/release/release.mjs gateway:secrets
 *   node scripts/release/release.mjs gateway
 *   node scripts/release/release.mjs web --gateway-url=https://ce-gateway.<sub>.workers.dev
 *   node scripts/release/release.mjs web --gateway-url=... --deploy
 *   node scripts/release/release.mjs apk --gateway-url=https://ce-gateway.<sub>.workers.dev
 *
 * Skrip ini TIDAK menyimpan rahasia: nilai rahasia hanya dimasukkan secara
 * interaktif ke `wrangler secret put`. Konfigurasi publik dibaca dari variabel
 * lingkungan atau argumen `--nama=nilai`.
 */
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { copyFile, mkdir, readFile, readdir, stat, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const MOBILE = path.join(ROOT, 'apps', 'mobile');
const WEB = path.join(ROOT, 'apps', 'web');
const GATEWAY = path.join(ROOT, 'services', 'gateway');
const RELEASE_DIR = path.join(ROOT, '.release');
const DIST = path.join(ROOT, 'dist');

const FIREBASE_CONFIG = path.join(ROOT, 'backend', 'firebase', 'firebase.json');
const GATEWAY_SECRETS = [
  'FIREBASE_SERVICE_ACCOUNT_JSON',
  'URL_SIGNING_KEY',
  'R2_ACCOUNT_ID',
  'R2_ACCESS_KEY_ID',
  'R2_SECRET_ACCESS_KEY',
  'R2_BUCKET_NAME',
  'R2_PRIVATE_BUCKET_NAME',
];

const FIREBASE_WEB_KEYS = [
  'FIREBASE_API_KEY',
  'FIREBASE_APP_ID',
  'FIREBASE_MESSAGING_SENDER_ID',
  'FIREBASE_PROJECT_ID',
  'FIREBASE_STORAGE_BUCKET',
];

const env = process.env;
const argv = process.argv.slice(2);
const command = argv[0];
const flags = new Set(argv.slice(1).filter((a) => a.startsWith('--') && !a.includes('=')));
const opts = Object.fromEntries(
  argv
    .slice(1)
    .filter((a) => a.startsWith('--') && a.includes('='))
    .map((a) => {
      const i = a.indexOf('=');
      return [a.slice(2, i), a.slice(i + 1)];
    }),
);

const c = {
  reset: '\u001b[0m',
  bold: '\u001b[1m',
  dim: '\u001b[2m',
  red: '\u001b[31m',
  green: '\u001b[32m',
  yellow: '\u001b[33m',
  cyan: '\u001b[36m',
};

function log(msg = '') {
  console.log(msg);
}

function step(msg) {
  log(`\n${c.cyan}${c.bold}▶ ${msg}${c.reset}`);
}

function ok(msg) {
  log(`${c.green}✔${c.reset} ${msg}`);
}

function warn(msg) {
  log(`${c.yellow}!${c.reset} ${msg}`);
}

function fail(msg) {
  console.error(`\n${c.red}✖ ${msg}${c.reset}`);
  process.exit(1);
}

function requireValue(name, value, hint) {
  if (!value || value.trim() === '') {
    fail(`${name} belum diisi.${hint ? `\n  ${hint}` : ''}`);
  }
  return value.trim();
}

function assertHttps(name, value) {
  if (!/^https:\/\/[^\s]+$/.test(value)) {
    fail(`${name} harus URL https absolut, diterima: "${value}"`);
  }
  if (/example|\.invalid|<|>/.test(value)) {
    fail(`${name} masih placeholder: "${value}"`);
  }
  return value.replace(/\/+$/, '');
}

function run(cmd, { cwd = ROOT, capture = false, allowFailure = false, env: extraEnv } = {}) {
  log(`${c.dim}$ ${cmd}${c.reset}${cwd === ROOT ? '' : `  (cwd: ${path.relative(ROOT, cwd)})`}`);
  const result = spawnSync(cmd, {
    cwd,
    shell: true,
    stdio: capture ? ['ignore', 'pipe', 'pipe'] : 'inherit',
    encoding: 'utf8',
    env: { ...env, ...extraEnv },
  });
  const stdout = result.stdout ?? '';
  const stderr = result.stderr ?? '';
  if (capture && stdout.trim()) process.stdout.write(stdout);
  if (capture && result.status !== 0 && stderr.trim()) process.stderr.write(stderr);
  if (result.status !== 0 && !allowFailure) {
    fail(`Perintah gagal (exit ${result.status ?? 'null'}): ${cmd}`);
  }
  return { status: result.status, stdout: stdout.trim(), stderr: stderr.trim() };
}

function inTerminal() {
  return Boolean(process.stdin.isTTY && process.stdout.isTTY);
}

async function exists(p) {
  try {
    await stat(p);
    return true;
  } catch {
    return false;
  }
}

function humanSize(bytes) {
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
}

async function walkFiles(dir, filter = () => true) {
  const out = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...(await walkFiles(full, filter)));
    else if (entry.isFile() && filter(full)) out.push(full);
  }
  return out;
}

function firebaseProject() {
  return opts.project ?? env.FIREBASE_PROJECT_ID ?? null;
}

function requireProject() {
  const project = firebaseProject();
  if (!project) {
    fail(
      'Proyek Firebase belum ditentukan.\n' +
        '  Gunakan --project=campus-express-prod atau set FIREBASE_PROJECT_ID.',
    );
  }
  if (/^(demo-|campus-express-dev$|campus-express-stg$)/.test(project) && flags.has('--production')) {
    fail(`--production tidak boleh dipakai untuk proyek "${project}".`);
  }
  return project;
}

/* ------------------------------------------------------------------ preflight */

function cmdPreflight() {
  step('Preflight — Git & toolchain');

  const branch = run('git rev-parse --abbrev-ref HEAD', { capture: true }).stdout;
  if (branch !== 'main') fail(`Branch harus main, sekarang "${branch}".`);
  ok(`Branch: ${branch}`);

  const dirty = run('git status --porcelain', { capture: true }).stdout;
  if (dirty) {
    warn('Working tree belum bersih:');
    log(dirty.split('\n').map((l) => `    ${l}`).join('\n'));
    if (!flags.has('--allow-dirty')) {
      fail('Commit/stash perubahan dulu, atau jalankan dengan --allow-dirty (tidak disarankan).');
    }
  } else {
    ok('Working tree bersih.');
  }

  const remote = run('git remote get-url origin', { capture: true }).stdout;
  ok(`Remote origin: ${remote}`);

  const nodeMajor = Number(process.versions.node.split('.')[0]);
  if (nodeMajor < 22) fail(`Node.js ${process.versions.node} terdeteksi; dibutuhkan >= 22.`);
  ok(`Node.js ${process.versions.node}`);

  step('Preflight — Typecheck & audit rahasia');
  run('npm run typecheck');
  run('npm run security:audit');

  step('Preflight — Validasi konfigurasi Wrangler (dry-run, tanpa auth)');
  run('npx wrangler deploy --dry-run --outdir .dryrun', { cwd: GATEWAY });

  if (!flags.has('--skip-mobile')) {
    step('Preflight — Flutter analyze');
    run('flutter analyze', { cwd: MOBILE });
  }

  if (flags.has('--with-tests')) {
    step('Preflight — Integration test engine (Firestore Emulator)');
    run('npm run test:engine');
  }

  ok('Preflight selesai. Semua gerbang verifikasi lulus.');
}

/* ------------------------------------------------------------------- firebase */

function cmdFirebase() {
  const project = requireProject();
  const only = opts.only ?? 'firestore:rules,firestore:indexes,functions';

  step(`Firebase deploy — project ${project}, only ${only}`);
  warn('Pastikan sudah login: npx firebase login (atau FIREBASE_TOKEN untuk CI).');

  run('npm run build:functions');
  run(
    `npx firebase deploy --config "${FIREBASE_CONFIG}" --project ${project} ` +
      `--only ${only} --non-interactive`,
  );

  ok('Firebase deploy selesai.');
  log(`  Rules/Indexes: https://console.firebase.google.com/project/${project}/firestore/rules`);
  log(`  Functions    : https://console.firebase.google.com/project/${project}/functions`);
}

/* ----------------------------------------------------------------------- seed */

async function cmdSeed() {
  const emulator = flags.has('--emulator') ? '127.0.0.1:8080' : null;

  step('Seed landmark Hub UINSU Tuntungan');
  log('  6 landmark: Simpang Tuntungan, Pasar Induk Lau Cih, Kos Jl. Lapangan Golf,');
  log('  Gedung FST, Rektorat & Dekanat, Pujasera — plus config/tuntungan_hub (tier tarif).');

  run('npm run build:functions');

  if (emulator) {
    run(`npx tsx scripts/seed-tuntungan-hub.ts --emulator`, {
      env: { FIRESTORE_EMULATOR_HOST: emulator },
    });
    ok(`Seed emulator selesai (${emulator}).`);
    return;
  }

  const target = requireProject();
  if (!flags.has('--yes') && !flags.has('--emulator')) {
    fail(
      `Target "${target}" adalah Firestore NYATA (bukan emulator).\n` +
        '  Tinjau dampaknya, lalu ulangi dengan --yes.',
    );
  }
  const credentials = env.GOOGLE_APPLICATION_CREDENTIALS;
  if (credentials) {
    if (!(await exists(credentials))) {
      fail(`Berkas kredensial tidak ditemukan: ${credentials}`);
    }
  } else {
    const adc =
      process.platform === 'win32'
        ? path.join(env.APPDATA ?? '', 'gcloud', 'application_default_credentials.json')
        : path.join(env.HOME ?? '', '.config', 'gcloud', 'application_default_credentials.json');
    if (!(await exists(adc))) {
      fail(
        'Kredensial Google belum tersedia.\n' +
          '  Set GOOGLE_APPLICATION_CREDENTIALS ke JSON service account (role Cloud Datastore User),\n' +
          '  atau jalankan: gcloud auth application-default login',
      );
    }
    ok(`Memakai Application Default Credentials: ${adc}`);
  }

  warn(`Menulis ke Firestore PRODUKSI: ${target}`);
  run(`npx tsx scripts/seed-tuntungan-hub.ts --yes`, {
    env: { FIREBASE_PROJECT_ID: target },
  });

  ok(`Seed produksi selesai: ${target}`);
  log('  Verifikasi: buka Firestore Console → koleksi `landmarks` (6 dokumen)');
  log('  dan `config/tuntungan_hub` (fare_tiers).');
}

/* -------------------------------------------------------------------- gateway */

function wranglerAuthed() {
  const who = run('npx wrangler whoami', { cwd: GATEWAY, capture: true, allowFailure: true });
  return who.status === 0 && !/not authenticated|You are not authenticated/i.test(`${who.stdout}\n${who.stderr}`);
}

function requireWranglerAuth() {
  if (!wranglerAuthed()) {
    fail(
      'Wrangler belum terautentikasi.\n' +
        '  Jalankan: npx --prefix services/gateway wrangler login\n' +
        '  (atau set CLOUDFLARE_API_TOKEN + CLOUDFLARE_ACCOUNT_ID).',
    );
  }
  ok('Wrangler terautentikasi.');
}

function cmdGatewaySecrets() {
  step('Cloudflare Workers — production secrets');
  requireWranglerAuth();
  if (!inTerminal()) {
    fail(
      'Perintah ini butuh terminal interaktif (nilai rahasia diketik langsung ke Wrangler).\n' +
        '  Jalankan manual: cd services/gateway && npx wrangler secret put <NAMA>',
    );
  }
  warn('Setiap nilai diminta oleh Wrangler dan tidak pernah masuk ke repo/log.');
  log('  Wajib: FIREBASE_SERVICE_ACCOUNT_JSON (JSON satu baris, role Cloud Datastore User),');
  log('         URL_SIGNING_KEY (HMAC acak ≥ 32 byte), R2_ACCOUNT_ID, R2_ACCESS_KEY_ID,');
  log('         R2_SECRET_ACCESS_KEY, R2_BUCKET_NAME (ce-public), R2_PRIVATE_BUCKET_NAME (ce-private).');

  for (const name of GATEWAY_SECRETS) {
    step(`wrangler secret put ${name}`);
    run(`npx wrangler secret put ${name}`, { cwd: GATEWAY });
  }

  step('Daftar secret terpasang (nilai tidak ditampilkan)');
  run('npx wrangler secret list', { cwd: GATEWAY });
  ok('Secrets production selesai dipasang.');
}

async function cmdGateway() {
  step('Cloudflare Workers — deploy Trusted Gateway');
  requireWranglerAuth();

  if (flags.has('--create-buckets')) {
    step('Membuat bucket R2 (abaikan bila sudah ada)');
    run('npx wrangler r2 bucket create ce-public', { cwd: GATEWAY, allowFailure: true });
    run('npx wrangler r2 bucket create ce-private', { cwd: GATEWAY, allowFailure: true });
  }

  const deployArgs = [];
  if (opts['allowed-origins']) {
    deployArgs.push(`--var ALLOWED_ORIGINS:${opts['allowed-origins']}`);
  }
  if (opts['public-domain']) {
    deployArgs.push(`--var R2_PUBLIC_DOMAIN:${opts['public-domain']}`);
  }

  const result = run(`npx wrangler deploy ${deployArgs.join(' ')}`.trim(), {
    cwd: GATEWAY,
    capture: true,
  });

  const combined = `${result.stdout}\n${result.stderr}`;
  const match = combined.match(/https:\/\/[^\s"']+\.workers\.dev/);
  if (!match) {
    warn('URL Worker tidak terdeteksi otomatis. Cek dashboard Cloudflare → Workers → ce-gateway.');
    return;
  }

  const url = match[0].replace(/\/+$/, '');
  await mkdir(RELEASE_DIR, { recursive: true });
  await writeFile(
    path.join(RELEASE_DIR, 'production.json'),
    `${JSON.stringify({ gatewayUrl: url, deployedAt: new Date().toISOString() }, null, 2)}\n`,
    'utf8',
  );

  ok(`Worker URL: ${url}`);
  log(`  Simpan ke apps/web/.env.production → NEXT_PUBLIC_GATEWAY_URL=${url}`);

  step('Health check pasca-deploy');
  const health = await fetch(`${url}/health`, { signal: AbortSignal.timeout(15000) }).catch((e) => e);
  if (health instanceof Error) {
    warn(`GET /health gagal: ${health.message}`);
  } else if (!health.ok) {
    warn(`GET /health → HTTP ${health.status}`);
  } else {
    ok(`GET /health → ${await health.text()}`);
  }

  const deps = await fetch(`${url}/health/deps`, { signal: AbortSignal.timeout(15000) }).catch((e) => e);
  if (deps instanceof Error) {
    warn(`GET /health/deps gagal: ${deps.message}`);
  } else {
    const body = await deps.text();
    if (deps.ok) ok(`GET /health/deps → ${body}`);
    else warn(`GET /health/deps → HTTP ${deps.status} ${body}`);
  }
}

/* ------------------------------------------------------------------------ web */

async function cmdWeb() {
  step('Web frontend — Next.js 15 static export');

  const gatewayUrl = assertHttps(
    'NEXT_PUBLIC_GATEWAY_URL',
    opts['gateway-url'] ?? env.NEXT_PUBLIC_GATEWAY_URL,
    'Contoh: --gateway-url=https://ce-gateway.<subdomain>.workers.dev',
  );

  const values = {
    NEXT_PUBLIC_GATEWAY_URL: gatewayUrl,
    NEXT_PUBLIC_OSM_TILE_URL:
      opts['osm-tile-url'] ??
      env.NEXT_PUBLIC_OSM_TILE_URL ??
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    NEXT_PUBLIC_FIREBASE_API_KEY: requireValue(
      'NEXT_PUBLIC_FIREBASE_API_KEY',
      opts['firebase-api-key'] ?? env.NEXT_PUBLIC_FIREBASE_API_KEY,
      'Ambil dari Firebase Console → Project settings → Your apps (Web).',
    ),
    NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN:
      opts['firebase-auth-domain'] ??
      env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN ??
      'campus-express-prod.firebaseapp.com',
    NEXT_PUBLIC_FIREBASE_PROJECT_ID:
      opts['firebase-project-id'] ??
      env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ??
      'campus-express-prod',
    NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET:
      opts['firebase-storage-bucket'] ??
      env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET ??
      'campus-express-prod.firebasestorage.app',
    NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID: requireValue(
      'NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID',
      opts['firebase-messaging-sender-id'] ?? env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
    ),
    NEXT_PUBLIC_FIREBASE_APP_ID: requireValue(
      'NEXT_PUBLIC_FIREBASE_APP_ID',
      opts['firebase-app-id'] ?? env.NEXT_PUBLIC_FIREBASE_APP_ID,
    ),
  };

  const envPath = path.join(WEB, '.env.production');
  const body =
    '# Dihasilkan oleh scripts/release/release.mjs — jangan commit (gitignored).\n' +
    Object.entries(values)
      .map(([k, v]) => `${k}=${v}`)
      .join('\n') +
    '\n';
  await writeFile(envPath, body, 'utf8');
  ok(`Menulis apps/web/.env.production (${Object.keys(values).length} variabel publik).`);

  step('next build → apps/web/out');
  run('npm run build', { cwd: WEB });

  const outDir = path.join(WEB, 'out');
  if (!(await exists(path.join(outDir, 'index.html')))) {
    fail('Build tidak menghasilkan apps/web/out/index.html.');
  }
  if (!(await exists(path.join(outDir, '_headers')))) {
    warn('apps/web/out/_headers tidak ada — cache Cloudflare Pages tidak optimal.');
  }

  step('Verifikasi endpoint produksi ter-embed di bundle');
  const host = new URL(gatewayUrl).host;
  const files = await walkFiles(outDir, (f) => /\.(html|js|json|txt)$/.test(f));
  let embedded = false;
  for (const file of files) {
    const text = await readFile(file, 'utf8');
    if (text.includes(host)) {
      embedded = true;
      break;
    }
  }
  if (!embedded) fail(`Host Gateway "${host}" tidak ditemukan di bundle out/.`);
  ok(`Gateway ${host} ter-embed di bundle.`);

  const sizeFiles = await walkFiles(outDir);
  let sizeBytes = 0;
  for (const file of sizeFiles) sizeBytes += (await stat(file)).size;
  ok(`Ukuran out/: ${humanSize(sizeBytes)} (${sizeFiles.length} berkas)`);

  if (!flags.has('--deploy')) {
    log('\nLangkah berikutnya:');
    log(`  npx --prefix . wrangler pages deploy apps/web/out --project-name=${opts['pages-project'] ?? 'campusxpress'} --branch=main`);
    log('  atau: node scripts/release/release.mjs web --gateway-url=... --deploy');
    return;
  }

  step('Cloudflare Pages — deploy');
  requireWranglerAuth();
  const pagesProject = opts['pages-project'] ?? 'campusxpress';
  run(`npx wrangler pages deploy apps/web/out --project-name=${pagesProject} --branch=main`);
  ok(`Web ter-deploy ke Cloudflare Pages (${pagesProject}).`);
}

/* ------------------------------------------------------------------------ apk */

async function readProdConfig() {
  const file = path.join(MOBILE, 'config', 'prod.json');
  if (!(await exists(file))) return {};
  try {
    return JSON.parse(await readFile(file, 'utf8'));
  } catch (error) {
    fail(`apps/mobile/config/prod.json tidak valid: ${error.message}`);
  }
}

async function cmdApk() {
  step('Flutter — release APK untuk pilot launch');

  const existing = await readProdConfig();
  const allowPlaceholders = flags.has('--allow-placeholders');
  const pick = (key) => opts[key.toLowerCase().replace(/_/g, '-')] ?? env[key] ?? existing[key];

  const gatewayUrl = opts['gateway-url'] ?? env.GATEWAY_BASE_URL ?? opts['gateway-base-url'] ?? existing.GATEWAY_BASE_URL;
  const defines = {
    GATEWAY_BASE_URL: assertHttps(
      'GATEWAY_BASE_URL',
      gatewayUrl,
      'Contoh: --gateway-url=https://ce-gateway.<subdomain>.workers.dev',
    ),
    OSM_TILE_URL:
      pick('OSM_TILE_URL') ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  };

  const missing = [];
  for (const key of FIREBASE_WEB_KEYS) {
    const value = pick(key);
    if (!value) missing.push(key);
    defines[key] = value ?? '';
  }
  defines.FIREBASE_PROJECT_ID ||= 'campus-express-prod';
  defines.FIREBASE_STORAGE_BUCKET ||=
    `${defines.FIREBASE_PROJECT_ID}.firebasestorage.app`;
  const stillMissing = missing.filter((key) => !defines[key]);
  if (stillMissing.length > 0) {
    const msg =
      `Konfigurasi Firebase produksi belum lengkap: ${stillMissing.join(', ')}.\n` +
      '  Tanpa nilai ini APK berjalan di mode demo. Isi lewat --firebase-*=... atau env.';
    if (!allowPlaceholders) fail(msg);
    warn(msg);
  }
  if (allowPlaceholders) {
    warn('--allow-placeholders: APK ini hanya untuk validasi pipeline, BUKAN untuk pilot launch.');
  }

  const configPath = path.join(MOBILE, 'config', 'prod.json');
  await mkdir(path.dirname(configPath), { recursive: true });
  await writeFile(configPath, `${JSON.stringify(defines, null, 2)}\n`, 'utf8');
  ok(`Menulis apps/mobile/config/prod.json (${Object.keys(defines).length} dart-define).`);

  const keyProps = path.join(MOBILE, 'android', 'key.properties');
  if (!(await exists(keyProps))) {
    warn(
      'android/key.properties tidak ada → APK ditandatangani kunci DEBUG.\n' +
        '  Layak untuk sideload pilot, tetapi JANGAN diunggah ke Play Store.',
    );
  } else {
    ok('Keystore rilis ditemukan (android/key.properties).');
  }

  step('flutter build apk --release');
  // Pilot: satu APK universal berisi 3 ABI menembus 40 MB (PRD.md). Arm64
  // mencakup seluruh ponsel Android modern yang dipakai driver/UMKM pilot;
  // gunakan --target-platform=android-arm untuk perangkat 32-bit, atau AAB
  // untuk Play Store (ukuran per-perangkat otomatis).
  const targetPlatform = opts['target-platform'] ?? 'android-arm64';
  run(
    `flutter build apk --release --target-platform ${targetPlatform} ` +
      '--dart-define-from-file=config/prod.json',
    { cwd: MOBILE },
  );

  const apk = path.join(MOBILE, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');
  if (!(await exists(apk))) fail('APK tidak ditemukan di build/app/outputs/flutter-apk/.');

  const info = await stat(apk);
  const limit = 40 * 1024 * 1024;
  if (info.size > limit) {
    fail(
      `Ukuran APK ${humanSize(info.size)} melebihi target 40 MB (PRD.md).\n` +
        '  Build universal memuat 3 ABI. Gunakan --target-platform=android-arm64 ' +
        '(default pilot) atau hasilkan AAB untuk Play Store.',
    );
  }
  ok(`APK: ${path.relative(ROOT, apk)} (${humanSize(info.size)} ≤ 40 MB, ${targetPlatform})`);

  const pubspec = await readFile(path.join(MOBILE, 'pubspec.yaml'), 'utf8');
  const version = /^version:\s*([^\s]+)/m.exec(pubspec)?.[1] ?? '0.0.0';
  const target = path.join(DIST, `CampusExpress-${version}-release.apk`);
  await mkdir(DIST, { recursive: true });
  await copyFile(apk, target);

  const sha = createHash('sha256').update(await readFile(apk)).digest('hex');
  await writeFile(path.join(DIST, 'SHA256SUMS.txt'), `${sha}  ${path.basename(target)}\n`, 'utf8');

  ok(`Artefak rilis: ${path.relative(ROOT, target)}`);
  log(`  SHA-256: ${sha}`);
  log('  Instalasi uji: adb install -r dist/' + path.basename(target));
}

/* ----------------------------------------------------------------------- main */

const HELP = `
Campus Express — CLI rilis Fase 6

  preflight   Git bersih, typecheck, audit rahasia, wrangler dry-run, flutter analyze
  firebase    Build functions + deploy rules/indexes/functions
  seed        Seed 6 landmark Hub UINSU Tuntungan (--emulator untuk lokal)
  gateway:secrets  Input interaktif seluruh secret Cloudflare Workers
  gateway     Deploy Worker + health check
  web         Tulis .env.production, build out/, verifikasi bundle (--deploy untuk Pages)
  apk         Build release APK + cek ukuran ≤ 40 MB

Opsi umum: --project=, --gateway-url=, --only=, --yes, --deploy, --allow-dirty,
            --skip-mobile, --with-tests, --allow-placeholders
`;

async function main() {
  switch (command) {
    case 'preflight':
      cmdPreflight();
      break;
    case 'firebase':
      cmdFirebase();
      break;
    case 'seed':
      await cmdSeed();
      break;
    case 'gateway:secrets':
      cmdGatewaySecrets();
      break;
    case 'gateway':
      await cmdGateway();
      break;
    case 'web':
      await cmdWeb();
      break;
    case 'apk':
      await cmdApk();
      break;
    case 'help':
    case '--help':
    case undefined:
      log(HELP);
      break;
    default:
      fail(`Perintah tidak dikenal: ${command}\n${HELP}`);
  }
}

main().catch((error) => fail(error?.stack ?? String(error)));
