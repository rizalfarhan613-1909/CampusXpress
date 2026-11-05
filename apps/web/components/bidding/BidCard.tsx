import { Badge } from '@/components/ui/Badge';
import { Icon } from '@/components/ui/Icon';
import type { BidOffer } from '@/lib/bidding';
import { rupiah } from '@/lib/format';
import type { FareRecommendation } from '@/lib/tuntungan';

function initials(name: string): string {
  return name
    .split(' ')
    .slice(0, 2)
    .map((part) => part.charAt(0).toUpperCase())
    .join('');
}

/**
 * Badge rekomendasi tarif OSRM: membandingkan `offeredPrice` dengan rentang
 * `recommendFare(distanceMeters)` supaya konsumen tahu penawaran masih wajar.
 * Label contoh: "Tarif Sesuai" saat penawaran ada di dalam rentang acuan.
 */
function fareBadge(
  offeredPrice: number,
  recommendation: FareRecommendation,
): { label: string; tone: 'mint' | 'info' | 'lav' } {
  if (offeredPrice < recommendation.minPrice) {
    return { label: 'Di Bawah Acuan', tone: 'info' };
  }
  if (offeredPrice > recommendation.maxPrice) {
    return { label: 'Di Atas Acuan', tone: 'lav' };
  }
  return { label: 'Tarif Sesuai', tone: 'mint' };
}

/** Kartu penawaran driver (Reverse Auction) — tombol hijau "TERIMA PENAWARAN". */
export function BidCard({
  bid,
  accepted,
  disabled,
  pending = false,
  commission,
  recommendation,
  onAccept,
}: {
  bid: BidOffer;
  accepted: boolean;
  disabled: boolean;
  /** `acceptBid` sedang diproses server (permintaan atomik belum selesai). */
  pending?: boolean;
  /** Pratinjau komisi 0,5% untuk tampilan; server selalu menghitung ulang. */
  commission?: number;
  /** Rentang tarif acuan OSRM untuk badge "Tarif Sesuai". */
  recommendation?: FareRecommendation | null;
  onAccept: (bid: BidOffer) => void;
}) {
  const osrm = recommendation ? fareBadge(bid.offeredPrice, recommendation) : null;

  return (
    <article
      className={`ce-card transition duration-fast ease-emphasis ${
        accepted
          ? 'border-primary ring-2 ring-primary/25'
          : disabled
            ? 'opacity-55'
            : 'hover:-translate-y-0.5 hover:shadow-float'
      }`}
      aria-label={`Penawaran ${bid.driverName}`}
    >
      <div className="flex items-start gap-3">
        <span className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-mint-100 font-display text-h5 text-primary">
          {initials(bid.driverName)}
        </span>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <h3 className="truncate font-display text-web-card-title text-text-strong">
              {bid.driverName}
            </h3>
            <span className="rounded-xs bg-lav-200 px-1.5 py-0.5 font-mono text-mono text-text-strong">
              {bid.platNumber}
            </span>
            {osrm ? <Badge tone={osrm.tone}>{osrm.label}</Badge> : null}
          </div>
          <p className="text-body-s text-text-muted">
            {bid.vehicleModel} · {bid.trips} trip selesai
          </p>
          <div className="mt-1 flex flex-wrap items-center gap-x-2 gap-y-0.5 text-caption">
            <span className="inline-flex items-center gap-1 font-semibold text-star">
              <Icon name="star" size={14} filled />
              {bid.rating.toFixed(1)}
            </span>
            <span className="text-text-muted">· ETA {bid.etaMinutes} menit</span>
          </div>
        </div>
        <div className="shrink-0 text-right">
          <p className="font-display text-price-l text-primary">
            {rupiah(bid.offeredPrice)}
          </p>
          <p className="text-caption text-text-muted">penawaran</p>
          {typeof commission === 'number' ? (
            <p className="mt-0.5 text-caption text-text-muted">
              komisi {rupiah(commission)}
            </p>
          ) : null}
        </div>
      </div>

      <button
        type="button"
        onClick={() => onAccept(bid)}
        disabled={disabled || accepted || pending}
        aria-pressed={accepted}
        aria-busy={pending}
        className={`ce-focus mt-3 inline-flex h-11 w-full items-center justify-center gap-2 rounded-md font-display text-body-m font-bold transition duration-fast ease-emphasis ${
          accepted
            ? 'cursor-default bg-mint-100 text-mint-on'
            : 'bg-primary text-on-primary shadow-cta hover:bg-primary-pressed active:scale-[.99] disabled:cursor-not-allowed disabled:opacity-60'
        }`}
      >
        <Icon
          name={pending ? 'sync' : accepted ? 'check_circle' : 'verified_user'}
          size={18}
          filled={accepted}
          className={pending ? 'animate-pulse-soft' : undefined}
        />
        {pending
          ? 'MENGUNCI HARGA…'
          : accepted
            ? 'PENAWARAN DITERIMA'
            : 'TERIMA PENAWARAN'}
      </button>
    </article>
  );
}