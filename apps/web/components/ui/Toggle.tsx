'use client';

/**
 * Toggle sakelar — thumb bergeser 150 ms ease-out (Design.md §D.6).
 * Dipakai untuk Buka/Tutup Toko, Kuota Harian, jadwal, dan kill switch admin.
 */
export function Toggle({
  checked,
  onChange,
  label,
  disabled = false,
  tone = 'primary',
}: {
  checked: boolean;
  onChange: (next: boolean) => void;
  /** Wajib: dipakai sebagai `aria-label` sekaligus judul pada tooltip aksesibilitas. */
  label: string;
  disabled?: boolean;
  tone?: 'primary' | 'mint';
}) {
  const onColor = tone === 'mint' ? 'bg-mint-300' : 'bg-primary';

  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={`ce-focus inline-flex h-7 w-12 shrink-0 items-center rounded-full p-0.5 transition-colors duration-fast ease-emphasis ${
        checked ? onColor : 'bg-lav-400'
      } ${disabled ? 'cursor-not-allowed opacity-50' : ''}`}
    >
      <span
        aria-hidden="true"
        className={`block h-6 w-6 rounded-full bg-surface shadow-card transition-transform duration-fast ease-out ${
          checked ? 'translate-x-5' : 'translate-x-0'
        }`}
      />
    </button>
  );
}
