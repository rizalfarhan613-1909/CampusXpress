import Link from 'next/link';
import { Icon } from '@/components/ui/Icon';
import { Badge } from '@/components/ui/Badge';

/** Logo lockup Design.md §C.23: tile 32 `primary` + ikon petir putih + wordmark. */
export function Brand({
  href = '/',
  withBadge = true,
}: {
  href?: string;
  withBadge?: boolean;
}) {
  return (
    <Link href={href} className="ce-focus inline-flex items-center gap-2 rounded-md">
      <span className="grid h-8 w-8 place-items-center rounded-md bg-primary text-white">
        <Icon name="bolt" size={18} filled />
      </span>
      <span className="font-display text-h4 tracking-[-0.2px] text-text-strong">
        Campus Express
      </span>
      {withBadge ? <Badge tone="mint" className="hidden sm:inline-flex">GO-CAMPUS</Badge> : null}
    </Link>
  );
}
