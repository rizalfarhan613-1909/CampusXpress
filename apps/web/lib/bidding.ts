/** Data demo untuk papan bidding web (sebelum Gateway terhubung). */

export interface BidOffer {
  id: string;
  driverName: string;
  rating: number;
  platNumber: string;
  vehicleModel: string;
  offeredPrice: number;
  etaMinutes: number;
  trips: number;
}

export interface TrackingOrder {
  id: string;
  type: string;
  consumer: string;
  pickup: string;
  dropoff: string;
  distanceMeters: number;
  status: 'SEARCHING_BIDS' | 'ACCEPTED';
  payment: string;
}

export const DEMO_TRACKING_ORDER: TrackingOrder = {
  id: 'CX-2048',
  type: 'Numpang Kampus',
  consumer: 'Rani Mahasiswa',
  pickup: 'Gedung FST UINSU Tuntungan',
  dropoff: 'Area Kos Jl. Lapangan Golf',
  distanceMeters: 2100,
  status: 'SEARCHING_BIDS',
  payment: 'COD',
};

export const DEMO_BIDS: readonly BidOffer[] = [
  {
    id: 'bid_driver_1',
    driverName: 'Dimas Pratama',
    rating: 4.9,
    platNumber: 'BK 1234 AB',
    vehicleModel: 'Honda Beat',
    offeredPrice: 7000,
    etaMinutes: 6,
    trips: 128,
  },
  {
    id: 'bid_driver_2',
    driverName: 'Sari Lubis',
    rating: 4.8,
    platNumber: 'BK 5621 QA',
    vehicleModel: 'Yamaha Mio',
    offeredPrice: 8500,
    etaMinutes: 4,
    trips: 96,
  },
  {
    id: 'bid_driver_3',
    driverName: 'Fajar Nasution',
    rating: 4.7,
    platNumber: 'BK 8820 CD',
    vehicleModel: 'Suzuki Nex',
    offeredPrice: 6500,
    etaMinutes: 11,
    trips: 74,
  },
];