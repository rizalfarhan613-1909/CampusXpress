'use client';

import { onAuthStateChanged } from 'firebase/auth';
import { useCallback, useEffect, useState } from 'react';
import { BidCard } from './BidCard';
import { MapPanel } from '@/components/map/MapPanel';
import { Badge, Chip } from '@/components/ui/Badge';
import { Icon } from '@/components/ui/Icon';
import { Callout, Panel, PanelHeader } from '@/components/ui/Panel';
import { DEMO_BIDS, DEMO_TRACKING_ORDER, type BidOffer } from '@/lib/bidding';
import { firebaseConfigured, getFirebaseApp, getFirebaseAuth } from '@/lib/firebase';
import { GatewayError, gatewayConfigured, postAuthed } from '@/lib/gateway';
import { rupiah } from '@/lib/format';
import { formatRecommendationBadge, recommendFare } from '@/lib/tuntungan';

/**
 * Papan Reverse Auction sisi konsumen (Fase 5).
 *
 * - Daftar `BidCard` mengikuti order berstatus `SEARCHING_BIDS` secara realtime
 *   (`onSnapshot` pada `orders/{orderId}/bids`) dan jatuh ke data demo bila
 *   Firebase belum dikonfigurasi.
 * - Tombol hijau "TERIMA PENAWARAN" memanggil endpoint atomik
 *   `POST /orders/:orderId/bids/:bidId/accept` di Trusted Gateway.
 * - Zero-trust: klien hanya mengirim `orderId` + `bidId`. `finalPrice`,
 *   komisi `max(50, round(finalPrice × 0,005))`, saldo deposit, dan penolakan
 *   bid lain dihitung ulang server di dalam transaksi; UI hanya menampilkan
 *   angka balikan server.
 */

/** Tarif komisi platform (Monetization.md §2.1) — hanya untuk pratinjau UI. */
const COMMISSION_RATE = 0.005;
/** Lantai komisi: `max(50, ...)` sesuai `core/money.ts`. */
const COMMISSION_FLOOR = 50;
/** Batas bawah penawaran; ditegakkan Gateway, dicerminkan di UI. */
const MIN_OFFERED_PRICE = 3_000;

/**
 * Pratinjau komisi untuk ditampilkan sebelum transaksi.
 *
 * Nilai ini TIDAK pernah dikirim ke server: Gateway membaca `offeredPrice`
 * milik bid di Firestore lalu menghitung ulang komisi di dalam transaksi.
 */
function previewCommission(finalPrice: number): number {
  return Math.max(COMMISSION_FLOOR, Math.round(finalPrice * COMMISSION_RATE));
}

/** Balikan `POST /orders/:orderId/bids/:bidId/accept` (`services/gateway`). */
interface AcceptBidResponse {
  ok: true;
  orderId: string;
  bidId: string;
  driverId: string;
  finalPrice: number;
  commission: number;
  balanceAfter: number;
  rejectedBids: number;
}

/** Hasil akhir papan: angka server (atau pratinjau demo tanpa Gateway). */
interface Settlement {
  bid: BidOffer;
  finalPrice: number;
  commission: number;
  rejectedBids: number;
  driverBalanceAfter: number | null;
  source: 'server' | 'demo';
}

function toNumber(value: unknown, fallback: number): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

/** Memetakan dokumen `orders/{orderId}/bids/{bidId}` menjadi `BidOffer`. */
function mapBidDocument(id: string, data: Record<string, unknown>): BidOffer | null {
  if (String(data.status ?? 'PENDING') !== 'PENDING') return null;

  const offeredPrice = Math.round(
    toNumber(data.offeredPrice ?? data.offered_price, 0),
  );
  if (offeredPrice < MIN_OFFERED_PRICE) return null;

  const eta = Math.round(
    toNumber(data.estimatedArrivalMinutes ?? data.eta_minutes, 10),
  );

  return {
    id,
    driverName: String(data.driverName ?? data.driver_name ?? 'Driver'),
    rating: toNumber(data.rating, 5),
    platNumber: String(data.platNumber ?? data.plat_number ?? '—'),
    vehicleModel: String(data.vehicleModel ?? data.vehicle_model ?? 'Motor'),
    offeredPrice,
    etaMinutes: Math.min(Math.max(eta, 1), 120),
    trips: Math.max(0, Math.round(toNumber(data.trips ?? data.trips_count, 0))),
  };
}

/**
 * Langganan realtime `orders/{orderId}/bids` (Rules: peserta order boleh baca).
 * Tanpa Firebase atau tanpa sesi masuk, papan memakai data demo dan diberi
 * label "MODE DEMO" agar halaman statis tetap berfungsi.
 */
function useRealtimeBids(orderId: string) {
  const [bids, setBids] = useState<readonly BidOffer[]>(DEMO_BIDS);
  const [live, setLive] = useState(false);

  useEffect(() => {
    let active = true;
    let unsubscribeBids: (() => void) | undefined;

    const reset = () => {
      unsubscribeBids?.();
      unsubscribeBids = undefined;
      if (!active) return;
      setBids(DEMO_BIDS);
      setLive(false);
    };

    const auth = firebaseConfigured ? getFirebaseAuth() : null;
    const app = firebaseConfigured ? getFirebaseApp() : null;
    if (!auth || !app) {
      reset();
      return () => {
        active = false;
      };
    }

    const subscribe = () => {
      if (!active || unsubscribeBids) return;
      // Dimuat dinamis agar Firestore tidak masuk bundel halaman statis.
      void import('firebase/firestore')
        .then(({ collection, getFirestore, onSnapshot }) => {
          if (!active || unsubscribeBids) return;
          unsubscribeBids = onSnapshot(
            collection(getFirestore(app), 'orders', orderId, 'bids'),
            (snapshot) => {
              if (!active) return;
              const next = snapshot.docs
                .map((doc) =>
                  mapBidDocument(doc.id, doc.data() as Record<string, unknown>),
                )
                .filter((bid): bid is BidOffer => bid !== null)
                .sort((a, b) => a.offeredPrice - b.offeredPrice);
              setBids(next);
              setLive(true);
            },
            reset,
          );
        })
        .catch(reset);
    };

    const stopAuth = onAuthStateChanged(auth, (user) => {
      if (!active) return;
      if (user) subscribe();
      else reset();
    });

    return () => {
      active = false;
      stopAuth();
      unsubscribeBids?.();
    };
  }, [orderId]);

  return { bids, live };
}

/** Pesan galat `acceptBid` yang ramah pengguna (kode dari Gateway). */
function describeAcceptError(cause: unknown): string {
  if (cause instanceof GatewayError) {
    switch (cause.code) {
      case 'AUTH_REQUIRED':
      case 'ORDER_NOT_OWNER':
        return 'Masuk dengan akun konsumen pemilik order untuk menerima penawaran.';
      case 'INSUFFICIENT_BALANCE':
        return 'Saldo deposit driver tidak mencukupi komisi. Pilih penawaran driver lain.';
      case 'BID_TOO_LOW':
        return 'Nominal penawaran tidak valid. Muat ulang papan untuk melihat penawaran terbaru.';
      case 'BID_NOT_FOUND':
      case 'ORDER_NOT_BIDDING':
      case 'BID_ALREADY_EXISTS':
        return 'Penawaran ini sudah tidak aktif — kemungkinan sudah diterima lebih dulu. Muat ulang papan.';
      case 'TOO_MANY_JOBS':
        return 'Driver sudah menangani 2 order aktif. Pilih penawaran driver lain.';
      case 'COD_LIMIT_EXCEEDED':
        return 'Penawaran melebihi batas COD Rp 200.000. Pilih penawaran lain atau gunakan QRIS.';
      case 'ORDER_NOT_FOUND':
        return 'Order tidak ditemukan. Periksa tautan atau muat ulang halaman.';
      default:
        break;
    }
    if (cause.status === 0) {
      return 'NEXT_PUBLIC_GATEWAY_URL belum dikonfigurasi sehingga papan berjalan dalam mode demo.';
    }
    return cause.message || `Gateway menolak permintaan (HTTP ${cause.status}).`;
  }
  if (cause instanceof Error) return cause.message;
  return 'Gagal menerima penawaran. Coba lagi.';
}

/**
 * Papan bidding konsumen: kartu penawaran realtime, pill rekomendasi OSRM, dan
 * tombol "TERIMA PENAWARAN" yang memanggil `acceptBid` atomik di Gateway.
 */
export function BiddingBoard() {
  const order = DEMO_TRACKING_ORDER;
  const { bids, live } = useRealtimeBids(order.id);
  const [settled, setSettled] = useState<Settlement | null>(null);
  const [pendingBidId, setPendingBidId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const recommendation = recommendFare(order.distanceMeters);
  const isBidding = settled === null && order.status === 'SEARCHING_BIDS';
  const bidCount = settled ? settled.rejectedBids + 1 : bids.length;

  // Pill ringkasan: angka server setelah settle, selain itu penawaran terendah.
  const cheapestBid =
    bids.length > 0 ? Math.min(...bids.map((offer) => offer.offeredPrice)) : null;
  const headlinePrice = settled?.finalPrice ?? cheapestBid ?? recommendation.basePrice;
  const headlineCommission = settled?.commission ?? previewCommission(headlinePrice);
  const highlightId = order.dropoff.includes('Lapangan Golf')
    ? 'kos-jl-lapangan-golf'
    : 'gedung-fst-uinsu';

  const handleAccept = useCallback(
    async (bid: BidOffer) => {
      // Cegah klik ganda: satu order hanya boleh punya satu klaim aktif.
      if (settled !== null || pendingBidId !== null) return;
      setError(null);
      setPendingBidId(bid.id);

      try {
        const auth = getFirebaseAuth();
        const user = auth?.currentUser ?? null;

        if (!gatewayConfigured || !user) {
          if (gatewayConfigured && !user) {
            throw new GatewayError(
              'Masuk dengan akun konsumen untuk menerima penawaran.',
              401,
              'AUTH_REQUIRED',
            );
          }
          // Mode demo: pratinjau lokal, bukan sumber kebenaran transaksi.
          setSettled({
            bid,
            finalPrice: bid.offeredPrice,
            commission: previewCommission(bid.offeredPrice),
            rejectedBids: Math.max(bids.length - 1, 0),
            driverBalanceAfter: null,
            source: 'demo',
          });
          return;
        }

        // ZERO-TRUST: hanya orderId + bidId yang dikirim. Harga, komisi, saldo
        // deposit, dan status order divalidasi ulang server secara atomik.
        const token = await user.getIdToken();
        const result = await postAuthed<AcceptBidResponse>(
          `/orders/${encodeURIComponent(order.id)}/bids/${encodeURIComponent(bid.id)}/accept`,
          token,
        );

        setSettled({
          bid,
          finalPrice: result.finalPrice,
          commission: result.commission,
          rejectedBids: result.rejectedBids,
          driverBalanceAfter: result.balanceAfter,
          source: 'server',
        });
      } catch (cause) {
        setError(describeAcceptError(cause));
      } finally {
        setPendingBidId(null);
      }
    },
    [bids.length, order.id, pendingBidId, settled],
  );

  const handleReset = useCallback(() => {
    setSettled(null);
    setError(null);
  }, []);

  return (
    <div className="space-y-4">
      <Panel>
        <div className="flex flex-wrap items-center gap-2">
          <Badge tone={settled ? 'mint' : 'info'}>
            {settled ? 'ACCEPTED' : order.status}
          </Badge>
          <Badge tone="lav">{order.type}</Badge>
          <Badge tone={live ? 'mint' : 'outline'}>
            <span
              className={`h-1.5 w-1.5 rounded-full ${
                live ? 'animate-pulse-soft bg-primary' : 'bg-text-muted'
              }`}
            />
            {live ? 'REALTIME' : 'MODE DEMO'}
          </Badge>
          <span className="font-mono text-mono text-text-muted">#{order.id}</span>
          <span className="ml-auto text-caption text-text-muted">
            {order.consumer} · {order.payment}
          </span>
        </div>

        <p aria-live="polite" className="sr-only">
          {bidCount} penawaran masuk. Status order{' '}
          {settled ? 'ACCEPTED' : order.status}.
        </p>

        <div className="mt-3 flex flex-wrap items-center gap-x-3 gap-y-1">
          <span className="inline-flex items-center gap-1.5 text-body-m font-semibold text-text-strong">
            <Icon name="location_on" size={18} className="text-primary" />
            {order.pickup}
          </span>
          <Icon name="arrow_forward" size={16} className="text-primary" />
          <span className="text-body-m font-semibold text-text-strong">
            {order.dropoff}
          </span>
        </div>

        <div className="mt-3 flex flex-wrap items-center gap-2">
          <Chip tone="mint" className="gap-1.5">
            <Icon name="my_location" size={14} />
            {formatRecommendationBadge(order.distanceMeters)}
          </Chip>
          <Chip tone="lav">Tier {recommendation.tier}</Chip>
          <Chip tone="outline" className="gap-1.5">
            <Icon name="group" size={14} />
            {bidCount} penawaran masuk
          </Chip>
          <Chip tone="outline" className="gap-1.5">
            <Icon name="verified_user" size={14} />
            COD maks Rp 200.000
          </Chip>
        </div>

        <div className="mt-2 flex flex-wrap items-center gap-2">
          <Chip tone="mint" className="gap-1.5">
            <Icon name="receipt_long" size={14} />
            Total harga {rupiah(headlinePrice)}
          </Chip>
          <Chip tone="lav" className="gap-1.5">
            <Icon name="tune" size={14} />
            Komisi 0,5% {rupiah(headlineCommission)}
          </Chip>
          <Chip tone="outline" className="gap-1.5">
            <Icon name="verified_user" size={14} />
            Driver terima {rupiah(Math.max(0, headlinePrice - headlineCommission))}
          </Chip>
        </div>
      </Panel>

      <div className="grid gap-4 lg:grid-cols-[1.35fr_1fr]">
        <div className="space-y-4">
          <MapPanel height={340} highlightId={highlightId} />
          <Panel>
            <PanelHeader
              icon="tune"
              title="Rentang harga acuan OSRM"
              description="Rekomendasi bukan batas transaksi; penawaran bebas mulai Rp 3.000."
            />
            <div className="grid grid-cols-3 gap-2 text-center">
              {[
                { label: 'Bawah', value: recommendation.minPrice },
                { label: 'Basis', value: recommendation.basePrice },
                { label: 'Atas', value: recommendation.maxPrice },
              ].map((item) => (
                <div key={item.label} className="rounded-md bg-lav-100 p-2">
                  <p className="text-caption text-text-muted">{item.label}</p>
                  <p className="font-display text-price text-primary">
                    {rupiah(item.value)}
                  </p>
                </div>
              ))}
            </div>
            <p className="mt-3 text-body-s text-text-muted">
              Tier 1 (0–1 km) Rp 5.000 · Tier 2 (1–2,5 km) Rp 7.000 · Tier 3
              (&gt;2,5 km) Rp 7.000 + Rp 2.000/km berikutnya.
            </p>
            <p className="mt-2 text-caption text-text-muted">
              Driver wajib memiliki saldo deposit minimal Rp 5.000 — diperiksa
              ulang server saat penawaran dikirim.
            </p>
          </Panel>
        </div>

        <div className="space-y-3">
          {settled ? (
            <Callout icon="check_circle">
              <strong>{settled.bid.driverName}</strong> dipilih. Harga final{' '}
              <strong>{rupiah(settled.finalPrice)}</strong>{' '}
              {settled.source === 'server'
                ? 'dikunci Gateway dalam satu transaksi atomik'
                : 'dikunci pada pratinjau demo'}
              , komisi platform <strong>{rupiah(settled.commission)}</strong>{' '}
              dipotong dari deposit driver, dan {settled.rejectedBids} penawaran
              lain otomatis ditolak.
            </Callout>
          ) : (
            <Callout icon="group">
              Pilih driver berdasarkan <strong>harga, ETA, dan rating</strong>.
              Setelah diterima, harga final terkunci dan komisi 0,5% dipotong
              dari deposit driver.
            </Callout>
          )}

          {error ? (
            <div
              role="alert"
              className="flex gap-2.5 rounded-md bg-danger-container p-3 text-body-s text-danger"
            >
              <Icon name="error" size={20} className="mt-0.5 shrink-0" />
              <p>{error}</p>
            </div>
          ) : null}

          {isBidding ? (
            bids.length > 0 ? (
              <ul className="space-y-3">
                {bids.map((bid) => (
                  <li key={bid.id}>
                    <BidCard
                      bid={bid}
                      accepted={false}
                      pending={pendingBidId === bid.id}
                      disabled={pendingBidId !== null}
                      commission={previewCommission(bid.offeredPrice)}
                      recommendation={recommendation}
                      onAccept={handleAccept}
                    />
                  </li>
                ))}
              </ul>
            ) : (
              <Panel>
                <div className="flex items-start gap-3">
                  <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-lav-300 text-primary">
                    <Icon name="sync" size={20} className="animate-pulse-soft" />
                  </span>
                  <div>
                    <p className="font-display text-web-card-title text-text-strong">
                      Menunggu penawaran driver…
                    </p>
                    <p className="mt-0.5 text-body-s text-text-muted">
                      Order #{order.id} berstatus SEARCHING_BIDS. Kartu penawaran
                      muncul otomatis tanpa memuat ulang halaman.
                    </p>
                  </div>
                </div>
              </Panel>
            )
          ) : null}

          {settled ? (
            <BidCard
              bid={settled.bid}
              accepted
              disabled
              commission={settled.commission}
              recommendation={recommendation}
              onAccept={handleAccept}
            />
          ) : null}

          {settled ? (
            <Panel>
              <PanelHeader
                icon="receipt_long"
                title="Transparansi harga final"
                description={
                  settled.source === 'server'
                    ? 'Angka di bawah adalah balikan Gateway setelah transaksi Firestore selesai.'
                    : 'Pratinjau mode demo; produksi menghitung ulang angka ini di server.'
                }
                badge={
                  <Badge tone={settled.source === 'server' ? 'mint' : 'outline'}>
                    {settled.source === 'server' ? 'SERVER' : 'DEMO'}
                  </Badge>
                }
              />
              <dl className="space-y-1.5 text-body-s">
                <div className="flex justify-between gap-3">
                  <dt className="text-text-muted">finalPrice</dt>
                  <dd className="font-mono font-bold text-text-strong">
                    {rupiah(settled.finalPrice)}
                  </dd>
                </div>
                <div className="flex justify-between gap-3">
                  <dt className="text-text-muted">Komisi platform 0,5%</dt>
                  <dd className="font-mono text-text-strong">
                    − {rupiah(settled.commission)}
                  </dd>
                </div>
                <div className="flex justify-between gap-3 border-t border-line-divider pt-1.5">
                  <dt className="text-text-muted">Diterima driver</dt>
                  <dd className="font-mono font-bold text-primary">
                    {rupiah(Math.max(0, settled.finalPrice - settled.commission))}
                  </dd>
                </div>
                {settled.driverBalanceAfter !== null ? (
                  <div className="flex justify-between gap-3">
                    <dt className="text-text-muted">Sisa deposit driver</dt>
                    <dd className="font-mono text-text-strong">
                      {rupiah(settled.driverBalanceAfter)}
                    </dd>
                  </div>
                ) : null}
                <div className="flex justify-between gap-3">
                  <dt className="text-text-muted">Penawaran lain ditolak</dt>
                  <dd className="font-mono text-text-strong">
                    {settled.rejectedBids}
                  </dd>
                </div>
              </dl>
              <p className="mt-3 rounded-sm bg-lav-100 p-2 font-mono text-caption text-text-body">
                komisi = max(50, round(finalPrice × 0,005))
              </p>
              <p className="mt-2 text-caption text-text-muted">
                Klien tidak pernah mengirim nominal harga atau status order.
                Server membaca penawaran, memeriksa saldo deposit ≥ Rp 5.000,
                lalu menulis order dan komisi dalam satu transaksi.
              </p>
              {settled.source === 'demo' ? (
                <button
                  type="button"
                  onClick={handleReset}
                  className="ce-focus mt-3 inline-flex h-9 w-full items-center justify-center gap-2 rounded-md bg-lav-300 font-display text-body-s font-bold text-text-strong transition duration-fast ease-emphasis hover:bg-lav-400"
                >
                  <Icon name="sync" size={16} />
                  Mulai ulang pratinjau
                </button>
              ) : null}
            </Panel>
          ) : null}
        </div>
      </div>
    </div>
  );
}