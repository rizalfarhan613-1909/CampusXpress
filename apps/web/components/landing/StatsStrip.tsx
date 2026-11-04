import { CountUp } from './CountUp';
import { Icon, type IconName } from '@/components/ui/Icon';

interface Stat {
  id: string;
  label: string;
  to: number;
  suffix?: string;
  decimals?: number;
  caption: string;
  icon: IconName;
  tone: 'primary' | 'info';
}

/** Grid statistik count-up (Design.md §C.23 & §D.7). Seluruh angka ilustratif. */
const STATS: Stat[] = [
  {
    id: 'pengguna',
    label: 'Pengguna Aktif',
    to: 10000,
    suffix: '+',
    caption: 'Mahasiswa lintas fakultas',
    icon: 'group',
    tone: 'primary',
  },
  {
    id: 'driver',
    label: 'Driver Kampus',
    to: 50,
    suffix: '+',
    caption: 'Rider mahasiswa terverifikasi',
    icon: 'two_wheeler',
    tone: 'primary',
  },
  {
    id: 'mitra',
    label: 'Mitra Kantin',
    to: 30,
    suffix: '+',
    caption: 'Stan aktif di pujasera kampus',
    icon: 'restaurant',
    tone: 'primary',
  },
  {
    id: 'komisi',
    label: 'Potongan Komisi',
    to: 0.5,
    decimals: 1,
    suffix: '%',
    caption: 'Bandingkan platform lain (20%+)',
    icon: 'trending_up',
    tone: 'info',
  },
];

export function StatsStrip() {
  return (
    <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
      {STATS.map((stat) => (
        <div
          key={stat.id}
          className="rounded-lg border border-line-subtle bg-surface p-4 shadow-card"
        >
          <div className="flex items-start justify-between gap-2">
            <p className="font-display text-micro uppercase text-text-muted">{stat.label}</p>
            <span className="grid h-7 w-7 shrink-0 place-items-center rounded-full bg-mint-100 text-primary">
              <Icon name={stat.icon} size={16} />
            </span>
          </div>
          <p
            className={`mt-2 font-display text-web-stat ${
              stat.tone === 'info' ? 'text-info' : 'text-primary'
            }`}
          >
            <CountUp to={stat.to} suffix={stat.suffix} decimals={stat.decimals} />
          </p>
          <p className="mt-1 text-web-small text-text-muted">{stat.caption}</p>
        </div>
      ))}
    </div>
  );
}
