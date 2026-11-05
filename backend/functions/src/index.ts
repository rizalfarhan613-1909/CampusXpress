import { setGlobalOptions } from 'firebase-functions/v2';

setGlobalOptions({
  region: 'asia-southeast2',
  maxInstances: 10,
});

export { claimOrder } from './claimOrder';
export { completeOrder } from './completeOrder';
export { finalizeOrder } from './finalizeOrder';
export { cancelOrder } from './cancelOrder';
export { topUpWallet } from './topUpWallet';
export { expireOrders, expireOrdersCron } from './expireOrders';
// Fase 5 — Reverse Auction / Bidding Engine + OSRM.
export { submitBid } from './submitBid';
export { acceptBid } from './acceptBid';
export { estimateFare } from './estimateFare';
