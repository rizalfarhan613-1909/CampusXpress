#!/usr/bin/env node
/**
 * Audit rahasia frontend Campus Express.
 *
 * Memastikan `apps/web` dan `apps/mobile` HANYA memuat konfigurasi publik:
 * tidak ada `R2_SECRET_ACCESS_KEY`, `R2_ACCESS_KEY_ID`,
 * `FIREBASE_SERVICE_ACCOUNT_JSON`, `URL_SIGNING_KEY`, blok private key, maupun
 * variabel `NEXT_PUBLIC_*` yang sebenarnya rahasia.
 *
 * Kunci privat hanya boleh berada di lingkungan aman: secret Cloudflare Worker
 * (`wrangler secret put`) atau Firebase Admin Functions.
 *
 * Pemakaian: `npm run security:audit` (exit code 1 bila ada pelanggaran).
 */
import { readdir, readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const TARGETS = ['apps/web', 'apps/mobile'];

/** Folder build/dependency yang tidak perlu dipindai. */
const SKIP_DIRS = new Set([
  '.dart_tool',
  '.git',
  '.gradle',
  '.idea',
  '.next',
  'build',
  'node_modules',
  'out',
]);

/** Berkas biner/turunan yang dilewati. */
const SKIP_EXTENSIONS = new Set([
  '.aab',
  '.apk',
  '.gif',
  '.ico',
  '.jar',
  '.jks',
  '.jpg',
  '.jpeg',
  '.keystore',
  '.lockb',
  '.mp4',
  '.otf',
  '.pdf',
  '.png',
  '.so',
  '.ttf',
  '.webp',
  '.woff',
  '.woff2',
]);

const MAX_FILE_BYTES = 512 * 1024;

/**
 * Pola kunci privat yang tidak boleh muncul di kode klien.
 * Pola menuntut konteks penugasan (`NAME=nilai`) atau blok kredensial agar
 * penyebutan nama variabel di dokumentasi tidak menjadi positif palsu.
 */
const FORBIDDEN = [
  {
    pattern: /R2_SECRET_ACCESS_KEY\s*[:=]\s*\S+/g,
    label: 'nilai R2 secret access key',
  },
  {
    pattern: /R2_ACCESS_KEY_ID\s*[:=]\s*\S+/g,
    label: 'nilai R2 access key id',
  },
  {
    pattern: /FIREBASE_SERVICE_ACCOUNT(?:_JSON)?\s*[:=]\s*\S+/g,
    label: 'kredensial service account Firebase',
  },
  {
    pattern: /URL_SIGNING_KEY\s*[:=]\s*\S+/g,
    label: 'nilai URL signing key',
  },
  { pattern: /-----BEGIN [A-Z ]*PRIVATE KEY-----/g, label: 'blok private key' },
  {
    pattern: /"type"\s*:\s*"service_account"/g,
    label: 'berkas kredensial service account',
  },
  {
    pattern: /"private_key"\s*:\s*"-----BEGIN/g,
    label: 'private_key service account',
  },
  {
    pattern: /"private_key_id"\s*:\s*"[0-9a-f]{16,}"/g,
    label: 'private_key_id service account',
  },
];

/** Variabel `NEXT_PUBLIC_*` yang namanya menandakan rahasia. */
const FORBIDDEN_PUBLIC_VAR =
  /NEXT_PUBLIC_[A-Z0-9_]*(?:SECRET|PRIVATE|SERVICE_ACCOUNT|SIGNING)[A-Z0-9_]*/g;

/** Baris `.env` non-publik (mis. `R2_BUCKET_NAME=...`) pada template web. */
const NON_PUBLIC_ENV_LINE = /^\s*([A-Z0-9_]+)\s*=/;

const findings = [];

function record(file, line, label) {
  findings.push({
    file: path.relative(ROOT, file),
    line,
    label,
  });
}

function lineOf(text, index) {
  return text.slice(0, index).split('\n').length;
}

async function scanFile(file, name) {
  const info = await stat(file);
  if (!info.isFile() || info.size === 0 || info.size > MAX_FILE_BYTES) return;

  const extension = path.extname(name).toLowerCase();
  const isEnvTemplate = name === '.env.example' || name.endsWith('.env.example');
  if (SKIP_EXTENSIONS.has(extension) && !isEnvTemplate) return;

  let text;
  try {
    text = await readFile(file, 'utf8');
  } catch {
    return; // Berkas biner/tak terbaca dilewati.
  }
  if (text.includes('\u0000')) return;

  for (const { pattern, label } of FORBIDDEN) {
    pattern.lastIndex = 0;
    for (const match of text.matchAll(pattern)) {
      record(file, lineOf(text, match.index ?? 0), label);
    }
  }

  for (const match of text.matchAll(FORBIDDEN_PUBLIC_VAR)) {
    record(file, lineOf(text, match.index ?? 0), `variabel publik bocor: ${match[0]}`);
  }

  if (isEnvTemplate) {
    text.split(/\r?\n/).forEach((line, index) => {
      if (/^\s*#/.test(line)) return;
      const match = NON_PUBLIC_ENV_LINE.exec(line);
      if (!match) return;
      if (match[1].startsWith('NEXT_PUBLIC_')) return;
      record(
        file,
        index + 1,
        `variabel non-publik pada template web: ${match[1]}`,
      );
    });
  }
}

async function walk(directory) {
  const entries = await readdir(directory, { withFileTypes: true }).catch(() => []);
  for (const entry of entries) {
    const full = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      if (SKIP_DIRS.has(entry.name)) continue;
      await walk(full);
    } else if (entry.isFile()) {
      await scanFile(full, entry.name);
    }
  }
}

for (const target of TARGETS) {
  await walk(path.join(ROOT, target));
}

if (findings.length > 0) {
  console.error('✖ Audit keamanan frontend GAGAL — kunci privat terdeteksi:');
  for (const finding of findings) {
    console.error(`  ${finding.file}:${finding.line} — ${finding.label}`);
  }
  console.error(
    '\nPindahkan rahasia ke `wrangler secret put` (Gateway) atau Firebase Admin Functions.',
  );
  process.exit(1);
}

console.log(
  `✔ Audit keamanan frontend lulus — ${TARGETS.join(' + ')} hanya memuat konfigurasi publik.`,
);