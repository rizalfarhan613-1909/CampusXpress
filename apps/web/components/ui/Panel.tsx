import type { ReactNode } from 'react';
import { Icon, type IconName } from './Icon';

/** Kartu dasar `surface` + `shadow-card` (Design.md §B.3 / §E.1). */
export function Panel({
  children,
  className = '',
  id,
}: {
  children: ReactNode;
  className?: string;
  /** Untuk target tautan jangkar, mis. `#verifikasi` pada panel admin. */
  id?: string;
}) {
  return (
    <section id={id} className={`ce-panel p-4 ${className}`}>
      {children}
    </section>
  );
}

/** Header kartu: tile ikon 40 `mint-100` + judul `h4` + badge kanan (Design.md §B.5). */
export function PanelHeader({
  icon,
  title,
  description,
  badge,
  action,
}: {
  icon?: IconName;
  title: string;
  description?: string;
  badge?: ReactNode;
  action?: ReactNode;
}) {
  return (
    <header className="mb-3 flex items-start gap-3">
      {icon ? (
        <span className="grid h-10 w-10 shrink-0 place-items-center rounded-md bg-mint-100 text-primary">
          <Icon name={icon} size={22} />
        </span>
      ) : null}
      <div className="min-w-0 flex-1">
        <h4 className="text-h4 leading-tight">{title}</h4>
        {description ? (
          <p className="mt-0.5 text-body-s text-text-muted">{description}</p>
        ) : null}
      </div>
      {badge}
      {action}
    </header>
  );
}

/** Baris statistik ringkas: label `caption` + nilai `h2` (Design.md §B.3). */
export function StatRow({
  label,
  value,
  tone = 'default',
}: {
  label: string;
  value: string;
  tone?: 'default' | 'primary' | 'muted';
}) {
  const valueClass =
    tone === 'primary'
      ? 'text-primary'
      : tone === 'muted'
        ? 'text-text-muted'
        : 'text-text-strong';
  return (
    <div className="flex items-center justify-between gap-3 py-1.5">
      <span className="text-body-s text-text-body">{label}</span>
      <span className={`font-display text-h5 ${valueClass}`}>{value}</span>
    </div>
  );
}

/** Callout hijau (§B.5): fill `mint-100`, ikon centang-perisai, teks `on-mint`. */
export function Callout({ children, icon = 'verified_user' }: { children: ReactNode; icon?: IconName }) {
  return (
    <div className="flex gap-2.5 rounded-md bg-mint-100 p-3">
      <Icon name={icon} size={20} className="mt-0.5 shrink-0 text-primary" />
      <p className="text-body-s text-mint-on">{children}</p>
    </div>
  );
}

/** Kartu tonal `lav-300` (Design.md §B.3, §E.1 "Kartu tonal"). */
export function TonalCard({
  children,
  className = '',
}: {
  children: ReactNode;
  className?: string;
}) {
  return <div className={`rounded-md bg-lav-300 p-3 ${className}`}>{children}</div>;
}
