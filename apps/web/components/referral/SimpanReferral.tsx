'use client';

import { useEffect, useState } from 'react';
import { Icon } from '@/components/ui/Icon';

/** Kode referral disimpan agar dapat dikirim ke `POST /me/bootstrap` saat pendaftaran. */
export const REFERRAL_STORAGE_KEY = 'ce_referral_code';

export function SimpanReferral({ code }: { code: string }) {
  const [tersimpan, setTersimpan] = useState(false);

  useEffect(() => {
    try {
      window.localStorage.setItem(REFERRAL_STORAGE_KEY, code);
      setTersimpan(true);
    } catch {
      // Mode privat peramban dapat menolak localStorage; abaikan.
      setTersimpan(false);
    }
  }, [code]);

  return (
    <p
      role="status"
      className="mt-4 flex items-start gap-2 rounded-md bg-mint-100 p-3 text-body-s text-mint-on"
    >
      <Icon name="check_circle" size={18} className="mt-0.5 shrink-0 text-primary" />
      {tersimpan
        ? `Kode referral ${code} sudah disimpan di peramban ini. Kode akan dikirim otomatis saat kamu mendaftar.`
        : `Kode referral ${code} valid. Salin manual bila peramban menolak penyimpanan lokal.`}
    </p>
  );
}
