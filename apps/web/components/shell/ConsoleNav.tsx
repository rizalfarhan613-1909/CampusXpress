'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Brand } from './Brand';
import { Icon, type IconName } from '@/components/ui/Icon';

export interface ConsoleNavItem {
  href: string;
  label: string;
  icon: IconName;
}

/** Bar navigasi dasbor (merchant & admin) — horizontal, dapat digulir di mobile. */
export function ConsoleNav({
  items,
  rolePill,
  homeHref,
}: {
  items: ConsoleNavItem[];
  rolePill: string;
  homeHref: string;
}) {
  const pathname = usePathname();
  const normalised = pathname.endsWith('/') ? pathname : `${pathname}/`;

  return (
    <header className="sticky top-0 z-40 border-b border-line-divider bg-surface">
      <div className="ce-container flex h-16 items-center justify-between gap-4">
        <Brand href={homeHref} withBadge={false} />
        <div className="flex items-center gap-2">
          <span className="hidden h-7 items-center rounded-full bg-lav-300 px-3 font-sans text-micro uppercase text-text-strong sm:inline-flex">
            {rolePill}
          </span>
          <Link href="/" className="ce-focus rounded text-body-s font-semibold text-primary">
            ← Landing
          </Link>
        </div>
      </div>

      <nav aria-label="Navigasi dasbor" className="border-t border-line-divider">
        <ul className="ce-container ce-rail flex gap-1 overflow-x-auto py-2">
          {items.map((item) => {
            const active = normalised === item.href;
            return (
              <li key={item.href}>
                <Link
                  href={item.href}
                  aria-current={active ? 'page' : undefined}
                  className={`ce-focus inline-flex h-10 items-center gap-2 whitespace-nowrap rounded-md px-3 font-display text-body-m transition-colors duration-fast ${
                    active
                      ? 'bg-primary text-on-primary'
                      : 'text-text-body hover:bg-lav-100'
                  }`}
                >
                  <Icon name={item.icon} size={20} />
                  {item.label}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>
    </header>
  );
}
