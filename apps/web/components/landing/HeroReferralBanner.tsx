'use client';

import { useState } from 'react';
import { Icon } from '@/components/ui/Icon';
import { firebaseConfigured, getFirebaseAuth } from '@/lib/firebase';
import { postAuthed } from '@/lib/gateway';

/** Kode referral selalu berpola `^[A-Z0-9]{6}$` (tech.md §6.8). */
const CODE_PATTERN = /^[A-Z0-9]{6}$/;
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function buatKodeDemo(): string {
  const bytes = new Uint8Array(6);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (byte) => ALPHABET[byte % ALPHABET.length]).join('');
}

/**
 * Hero Referral Banner — pill program referral statis (sesuai gambar 27) plus
 * generator tautan undangan (PRD §8, tech.md §6.8).
 *
 * Bila Firebase belum dikonfigurasi, generator berjalan dalam mode demo lokal
 * sehingga tautan `/r/[kode]/` tetap dapat dicoba tanpa backend.
 */
export function HeroReferralBanner() {
  const [code, setCode] = useState<string | null>(null);
  const [link, setLink] = useState('');
  const [joined, setJoined] = useState(0);
  const [loading, setLoading] = useState(false);
  const [copied, setCopied] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function mulai() {
    setLoading(true);
    setError(null);
    try {
      if (firebaseConfigured) {
        const { GoogleAuthProvider, signInWithPopup } = await import('firebase/auth');
        const auth = getFirebaseAuth();
        if (auth) {
          const provider = new GoogleAuthProvider();
          // Petunjuk UI saja; validasi akun tetap dilakukan di server.
          provider.setCustomParameters({ hd: 'mhs.uin.ac.id' });
          const { user } = await signInWithPopup(auth, provider);
          const token = await user.getIdToken();
          const hasil = await postAuthed<{ code: string; successCount: number }>(
            '/referrals/code',
            token,
          );
          setCode(hasil.code);
          setJoined(hasil.successCount);
          setLink(`${window.location.origin}/r/${hasil.code}/`);
          setLoading(false);
          return;
        }
      }

      const kode = buatKodeDemo();
      setCode(kode);
      setJoined(2);
      setLink(`${window.location.origin}/r/${kode}/`);
    } catch {
      setError('Masuk dengan akun @mhs.uin.ac.id untuk mendapatkan tautan undangan.');
    } finally {
      setLoading(false);
    }
  }

  async function salin() {
    try {
      await navigator.clipboard.writeText(link);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2000);
    } catch {
      setError('Peramban menolak akses papan klip. Salin tautan secara manual.');
    }
  }

  const kodeValid = code !== null && CODE_PATTERN.test(code);

  return (
    <section
      id="referral"
      aria-label="Program referral kampus"
      className="mx-auto flex w-fit max-w-full flex-col items-center gap-3 rounded-full bg-mint-300 py-2 pl-3 pr-4 text-center sm:flex-row sm:text-left"
    >
      <span className="flex items-center gap-2">
        <span className="grid h-6 w-6 shrink-0 place-items-center rounded-full bg-primary text-mint-300">
          <Icon name="bolt" size={14} filled />
        </span>
        <span className="font-display text-body-s font-bold text-mint-on">
          Program Referral Kampus: ajak 3 teman kuliah, dapatkan bebas ongkir 100%!
        </span>
      </span>

      {code ? (
        <span className="flex w-full flex-col items-center gap-2 sm:w-auto sm:flex-row">
          <label className="sr-only" htmlFor="tautan-referral">
            Tautan undangan referral
          </label>
          <input
            id="tautan-referral"
            readOnly
            value={link}
            className="h-9 w-full rounded-full border border-primary-bright bg-surface px-3 font-mono text-caption text-text-strong focus:outline-none sm:w-64"
          />
          <span className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => void salin()}
              className="ce-focus inline-flex h-9 items-center gap-1.5 rounded-full bg-primary px-3 font-display text-caption font-bold text-on-primary transition-colors duration-fast hover:bg-primary-pressed"
            >
              <Icon name={copied ? 'check' : 'receipt_long'} size={16} />
              {copied ? 'Tersalin' : 'Salin'}
            </button>
            <span className="whitespace-nowrap font-sans text-caption text-mint-on">
              {joined}/3 teman
            </span>
          </span>
        </span>
      ) : (
        <button
          type="button"
          onClick={() => void mulai()}
          disabled={loading}
          className="ce-focus inline-flex h-9 items-center gap-1.5 rounded-full bg-primary px-4 font-display text-caption font-bold text-on-primary transition-colors duration-fast hover:bg-primary-pressed disabled:opacity-70"
        >
          <Icon name="bolt" size={16} />
          {loading ? 'Menyiapkan…' : 'Dapatkan tautan undanganmu'}
        </button>
      )}

      {error ? (
        <span role="alert" className="w-full text-caption text-danger sm:w-auto">
          {error}
        </span>
      ) : null}

      {kodeValid ? (
        <span className="sr-only">
          Kode referral {code} aktif. Setiap teman yang mendaftar sebelum tenggat akan
          menghitung satu slot bebas ongkir.
        </span>
      ) : null}
    </section>
  );
}
