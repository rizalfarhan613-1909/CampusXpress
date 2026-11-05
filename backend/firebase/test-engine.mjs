/**
 * Automated integration test — Campus Express Business Engine (Fase 2).
 *
 * Dijalankan di Firebase Firestore Emulator:
 *   npm run test:engine
 *
 * Yang diverifikasi:
 *  - seeder 11 landmark + matriks tarif,
 *  - saldo < Rp 5.000 gagal klaim, saldo >= Rp 5.000 berhasil,
 *  - dua driver klaim paralel -> hanya satu menang (atomic claiming),
 *  - maksimal 2 order aktif,
 *  - PIN salah 5x -> lock 10 menit + event PIN_LOCKED,
 *  - PIN benar -> COMPLETED, komisi max(50, round((subtotal+ongkir)*0,005)),
 *  - ledger COMMISSION_DEDUCTION idempoten,
 *  - top-up admin + ledger COMMISSION_TOPUP,
 *  - finalize harga tepercaya dari matriks zona + deteksi PRICE_MISMATCH,
 *  - pembatalan order + kuota gratis/strike (Rules.md §7),
 *  - cron expire: PLACED 5 mnt & AWAITING_DRIVER 10 mnt.
 */
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
process.env.GCLOUD_PROJECT ??= 'demo-campus-express';

// Gunakan instance firebase-admin milik backend/functions. Ini penting agar
// FieldValue.serverTimestamp() dan Firestore yang dipakai engine berasal dari
// modul yang sama (menghindari dua salinan @google-cloud/firestore).
const functionsRequire = createRequire(
  path.join(fileURLToPath(new URL('.', import.meta.url)), '../functions/package.json'),
);
const { initializeApp, getApps } = functionsRequire('firebase-admin/app');
const { getFirestore, Timestamp } = functionsRequire('firebase-admin/firestore');

const require = createRequire(import.meta.url);
const { claimOrderEngine } = require('../functions/lib/core/claimOrder.js');
const { completeOrderEngine } = require('../functions/lib/core/completeOrder.js');
const { topUpWalletEngine } = require('../functions/lib/core/topUpWallet.js');
const { finalizeOrderEngine } = require('../functions/lib/core/finalizeOrder.js');
const { cancelOrderEngine } = require('../functions/lib/core/cancelOrder.js');
const { expireOrdersEngine } = require('../functions/lib/core/expireOrders.js');
const { computeCommission } = require('../functions/lib/core/money.js');
const {
  SEED_LANDMARKS,
  seedLandmarks,
} = require('../functions/lib/core/landmarkSeed.js');
const {
  calculateDeliveryFee,
  ZONE_FARE_MATRIX,
} = require('../functions/lib/core/fareMatrix.js');
const { submitBidEngine } = require('../functions/lib/core/submitBid.js');
const { acceptBidEngine } = require('../functions/lib/core/acceptBid.js');
const {
  recommendFare,
  fetchOsrmRoute,
  estimateFare,
  FARE_TIERS,
} = require('../functions/lib/core/osrmRouting.js');
const {
  TUNTUNGAN_HUB_LANDMARKS,
  seedTuntunganHub,
} = require('../functions/lib/core/tuntunganHub.js');

const projectId = process.env.GCLOUD_PROJECT;
if (getApps().length === 0) initializeApp({ projectId });
const db = getFirestore();

const STATE = {
  passed: 0,
  failed: 0,
  failures: [],
};

async function test(name, fn) {
  try {
    await fn();
    STATE.passed += 1;
    console.log(`  PASS  ${name}`);
  } catch (error) {
    STATE.failed += 1;
    STATE.failures.push({ name, error });
    console.error(`  FAIL  ${name}`);
    console.error(
      error instanceof Error ? `        ${error.message}` : `        ${String(error)}`,
    );
  }
}

async function expectGatewayError(fn, code) {
  try {
    await fn();
  } catch (error) {
    assert.equal(
      error?.code,
      code,
      `Diharapkan ${code}, tetapi mendapat ${error?.code ?? error?.name}: ${error?.message}`,
    );
    return error;
  }
  assert.fail(`Diharapkan error ${code}, tetapi operasi berhasil.`);
}

async function resetDatabase() {
  for (const collectionName of [
    'orders',
    'users',
    'wallets',
    'driverProfiles',
    'wallet_ledger',
    'landmarks',
    'config',
  ]) {
    await db.recursiveDelete(db.collection(collectionName));
  }
}

async function createUser(uid, options = {}) {
  const {
    role = 'driver',
    verified = true,
    balance = 10_000,
    activeJobs = 0,
  } = options;
  await db.collection('users').doc(uid).set({
    id: uid,
    name: `User ${uid}`,
    phone: '+6281234567890',
    role,
    is_verified: verified,
    wallet_balance: balance,
    active_jobs: activeJobs,
    created_at: Timestamp.now(),
  });
}

async function createOrder(orderId, options = {}) {
  const {
    status = 'AWAITING_DRIVER',
    driverId = null,
    consumerId = 'consumer_test',
    total = 30_000,
    deliveryFee = 4_000,
    paymentMethod = 'QRIS_STATIC',
    orderType = 'numpang',
    pickup = 'gate-utama',
    destination = 'masjid-kampus',
  } = options;

  await db.collection('orders').doc(orderId).set({
    id: orderId,
    consumer_id: consumerId,
    driver_id: driverId,
    merchant_id: null,
    order_type: orderType,
    pickup_landmark_id: pickup,
    destination_landmark_id: destination,
    total_price: total,
    delivery_fee: deliveryFee,
    commission_fee: computeCommission(total),
    payment_method: paymentMethod,
    status,
    created_at: Timestamp.now(),
  });
}

async function getDoc(path) {
  return db.doc(path).get();
}

async function main() {
  console.log('\nCampus Express — Business Engine Integration Test');
  console.log(`Firestore emulator: ${process.env.FIRESTORE_EMULATOR_HOST}`);
  console.log(`Project: ${projectId}\n`);

  await resetDatabase();

  // ---------------------------------------------------------------- seeder
  await test('Seeder landmark mengisi 11 landmark + matriks tarif', async () => {
    const result = await seedLandmarks(db);
    assert.equal(result.landmarkCount, 11);
    assert.equal(result.zone1Count, 6);
    assert.equal(result.zone2Count, 5);

    const snapshot = await db.collection('landmarks').get();
    assert.equal(snapshot.size, 11);

    const names = new Set(snapshot.docs.map((doc) => doc.get('name')));
    for (const landmark of SEED_LANDMARKS) {
      assert.ok(names.has(landmark.name), `Landmark ${landmark.name} tidak tersimpan`);
      assert.equal(docZone(snapshot, landmark.id), landmark.zone_group);
    }

    const fareConfig = await getDoc('config/fare_matrix');
    assert.equal(fareConfig.exists, true);
    assert.deepEqual(fareConfig.get('zone_rates'), ZONE_FARE_MATRIX);

    assert.equal(calculateDeliveryFee('Zona 1', 'Zona 1'), 4_000);
    assert.equal(calculateDeliveryFee('Zona 1', 'Zona 2'), 6_000);
    assert.equal(calculateDeliveryFee('Zona 2', 'Zona 1'), 6_000);
    assert.equal(calculateDeliveryFee('Zona 2', 'Zona 2'), 5_000);
  });

  // ------------------------------------------------------- saldo & claiming
  await test('Driver saldo Rp 4.999 gagal klaim (ambang Rp 5.000)', async () => {
    await createUser('driver_low', { balance: 4_999 });
    await createOrder('order_low');

    const error = await expectGatewayError(
      () => claimOrderEngine(db, { driverId: 'driver_low', orderId: 'order_low' }),
      'INSUFFICIENT_BALANCE',
    );
    assert.match(error.message, /5\.000/);

    const order = await getDoc('orders/order_low');
    assert.equal(order.get('status'), 'AWAITING_DRIVER');
    assert.equal((await getDoc('orders/order_low/secrets/handover')).exists, false);
  });

  await test('Driver belum terverifikasi tidak bisa klaim order', async () => {
    await createUser('driver_unverified', {
      balance: 10_000,
      verified: false,
    });
    await createOrder('order_unverified');

    await expectGatewayError(
      () =>
        claimOrderEngine(db, {
          driverId: 'driver_unverified',
          orderId: 'order_unverified',
        }),
      'DRIVER_NOT_VERIFIED',
    );
    assert.equal(
      (await getDoc('orders/order_unverified')).get('status'),
      'AWAITING_DRIVER',
    );
  });

  await test('Driver saldo Rp 5.000 berhasil klaim + secret PIN 4 digit', async () => {
    await createUser('driver_ok', { balance: 5_000 });
    await createOrder('order_ok');

    const result = await claimOrderEngine(db, {
      driverId: 'driver_ok',
      orderId: 'order_ok',
    });
    assert.equal(result.status, 'CLAIMED');
    assert.equal(result.commissionEstimate, 150);

    const order = await getDoc('orders/order_ok');
    assert.equal(order.get('status'), 'CLAIMED');
    assert.equal(order.get('driver_id'), 'driver_ok');
    assert.equal(order.get('dropoff_pin'), undefined, 'PIN tidak boleh ada di dokumen order');

    const secret = await getDoc('orders/order_ok/secrets/handover');
    assert.equal(secret.exists, true);
    assert.match(String(secret.get('dropoff_pin')), /^\d{4}$/);
    assert.equal(secret.get('failed_attempts'), 0);
    assert.equal(secret.get('locked_until'), null);

    const driver = await getDoc('users/driver_ok');
    assert.equal(driver.get('active_jobs'), 1);
  });

  await test('Dua driver klaim paralel: hanya 1 berhasil (atomic claiming)', async () => {
    await createUser('driver_race_a', { balance: 10_000 });
    await createUser('driver_race_b', { balance: 10_000 });
    await createOrder('order_race');

    const results = await Promise.allSettled([
      claimOrderEngine(db, { driverId: 'driver_race_a', orderId: 'order_race' }),
      claimOrderEngine(db, { driverId: 'driver_race_b', orderId: 'order_race' }),
    ]);

    const fulfilled = results.filter((item) => item.status === 'fulfilled');
    const rejected = results.filter((item) => item.status === 'rejected');
    assert.equal(fulfilled.length, 1, 'Harus tepat satu klaim berhasil');
    assert.equal(rejected.length, 1, 'Harus tepat satu klaim ditolak');
    assert.equal(rejected[0].reason.code, 'ORDER_TAKEN');

    const order = await getDoc('orders/order_race');
    const winner = order.get('driver_id');
    assert.ok(['driver_race_a', 'driver_race_b'].includes(winner));
    assert.equal(order.get('status'), 'CLAIMED');

    const loser = winner === 'driver_race_a' ? 'driver_race_b' : 'driver_race_a';
    assert.equal((await getDoc(`users/${winner}`)).get('active_jobs'), 1);
    assert.equal((await getDoc(`users/${loser}`)).get('active_jobs'), 0);
  });

  await test('Driver dengan 2 order aktif tidak bisa klaim order ketiga', async () => {
    await createUser('driver_busy', { balance: 10_000, activeJobs: 2 });
    await createOrder('order_busy');

    await expectGatewayError(
      () => claimOrderEngine(db, { driverId: 'driver_busy', orderId: 'order_busy' }),
      'TOO_MANY_JOBS',
    );
  });

  await test('COD > Rp 200.000 ditolak (wajib QRIS_STATIC)', async () => {
    await createUser('driver_cod', { balance: 10_000 });
    await createOrder('order_cod', {
      total: 250_000,
      deliveryFee: 6_000,
      paymentMethod: 'COD',
    });

    await expectGatewayError(
      () => claimOrderEngine(db, { driverId: 'driver_cod', orderId: 'order_cod' }),
      'COD_LIMIT_EXCEEDED',
    );
    assert.equal((await getDoc('orders/order_cod')).get('status'), 'AWAITING_DRIVER');
  });

  await test('Transisi ilegal: complete dari CLAIMED ditolak', async () => {
    await createUser('driver_step', { balance: 10_000 });
    await createOrder('order_step');
    await claimOrderEngine(db, { driverId: 'driver_step', orderId: 'order_step' });
    const pin = (await getDoc('orders/order_step/secrets/handover')).get('dropoff_pin');

    await expectGatewayError(
      () =>
        completeOrderEngine(db, {
          driverId: 'driver_step',
          orderId: 'order_step',
          inputPin: pin,
        }),
      'INVALID_ORDER_STATE',
    );
  });

  // --------------------------------------------------------------- PIN lock
  await test('PIN salah 5x mengunci 10 menit + event PIN_LOCKED', async () => {
    await createUser('driver_pinlock', { balance: 10_000 });
    await createOrder('order_pinlock');
    await claimOrderEngine(db, {
      driverId: 'driver_pinlock',
      orderId: 'order_pinlock',
    });
    await db.doc('orders/order_pinlock').update({ status: 'ARRIVED' });

    const pin = String(
      (await getDoc('orders/order_pinlock/secrets/handover')).get('dropoff_pin'),
    );
    const wrongPin = pin === '0000' ? '1111' : '0000';

    for (let attempt = 1; attempt <= 4; attempt += 1) {
      const error = await expectGatewayError(
        () =>
          completeOrderEngine(db, {
            driverId: 'driver_pinlock',
            orderId: 'order_pinlock',
            inputPin: wrongPin,
          }),
        'PIN_WRONG',
      );
      assert.match(error.message, new RegExp(String(5 - attempt)));
    }

    const fifth = await expectGatewayError(
      () =>
        completeOrderEngine(db, {
          driverId: 'driver_pinlock',
          orderId: 'order_pinlock',
          inputPin: wrongPin,
        }),
      'PIN_LOCKED',
    );
    assert.match(fifth.message, /terkunci 10 menit akibat salah 5 kali/);

    const secret = await getDoc('orders/order_pinlock/secrets/handover');
    assert.equal(secret.get('failed_attempts'), 5);
    const lockedUntil = secret.get('locked_until');
    assert.ok(lockedUntil, 'locked_until harus terisi');
    const lockMs = lockedUntil.toDate().getTime() - Date.now();
    assert.ok(lockMs > 9 * 60 * 1000, 'Lock harus mendekati 10 menit');

    const lockedEvent = await getDoc('orders/order_pinlock/events/pin_locked');
    assert.equal(lockedEvent.exists, true);
    assert.equal(lockedEvent.get('type'), 'PIN_LOCKED');

    const stillLocked = await expectGatewayError(
      () =>
        completeOrderEngine(db, {
          driverId: 'driver_pinlock',
          orderId: 'order_pinlock',
          inputPin: pin,
        }),
      'PIN_LOCKED',
    );
    assert.match(stillLocked.message, /terkunci 10 menit/);
  });

  // ----------------------------------------------------- complete + komisi
  await test('PIN benar -> COMPLETED, komisi max(50, round(total*0,005)) dipotong', async () => {
    await createUser('driver_complete', { balance: 5_000 });
    await createOrder('order_complete', { total: 30_000, deliveryFee: 4_000 });
    await claimOrderEngine(db, {
      driverId: 'driver_complete',
      orderId: 'order_complete',
    });
    await db.doc('orders/order_complete').update({ status: 'ARRIVED' });

    const pin = String(
      (await getDoc('orders/order_complete/secrets/handover')).get('dropoff_pin'),
    );
    // total_price (30.000) sudah termasuk ongkir 4.000, sehingga
    // subtotal + ongkir = 30.000 -> komisi = max(50, round(150)) = 150.
    assert.equal(computeCommission(30_000), 150);

    const result = await completeOrderEngine(db, {
      driverId: 'driver_complete',
      orderId: 'order_complete',
      inputPin: pin,
    });
    assert.equal(result.status, 'COMPLETED');
    assert.equal(result.alreadyCompleted, false);
    assert.equal(result.commission, 150);
    assert.equal(result.balanceAfter, 4_850);

    const order = await getDoc('orders/order_complete');
    assert.equal(order.get('status'), 'COMPLETED');
    assert.equal(order.get('commission_fee'), 150);
    assert.ok(order.get('completed_at'));

    const driver = await getDoc('users/driver_complete');
    assert.equal(driver.get('wallet_balance'), 4_850);
    assert.equal(driver.get('active_jobs'), 0);

    const ledger = await getDoc('wallet_ledger/commission_order_complete');
    assert.equal(ledger.exists, true);
    assert.equal(ledger.get('type'), 'COMMISSION_DEDUCTION');
    assert.equal(ledger.get('amount'), -150);
    assert.equal(ledger.get('balance_after'), 4_850);
    assert.equal(ledger.get('driver_id'), 'driver_complete');

    const completedEvent = await getDoc('orders/order_complete/events/completed');
    assert.equal(completedEvent.exists, true);
    assert.equal(completedEvent.get('type'), 'COMPLETED');

    // Idempoten: kirim ulang tidak memotong saldo dua kali.
    const retry = await completeOrderEngine(db, {
      driverId: 'driver_complete',
      orderId: 'order_complete',
      inputPin: pin,
    });
    assert.equal(retry.alreadyCompleted, true);
    assert.equal((await getDoc('users/driver_complete')).get('wallet_balance'), 4_850);

    const ledgerRows = await db
      .collection('wallet_ledger')
      .where('order_id', '==', 'order_complete')
      .get();
    assert.equal(ledgerRows.size, 1, 'Ledger komisi harus idempoten');
  });

  await test('Rumus komisi minimum Rp 50 dan round-half-up', async () => {
    assert.equal(computeCommission(0), 50);
    assert.equal(computeCommission(5_000), 50);
    assert.equal(computeCommission(17_500), 88);
    assert.equal(computeCommission(30_000), 150);
    assert.equal(computeCommission(500_000), 2_500);
  });

  // ------------------------------------------------------------------ topup
  await test('Top-up admin menambah saldo + ledger COMMISSION_TOPUP', async () => {
    await createUser('driver_topup', { balance: 1_000 });

    const first = await topUpWalletEngine(db, {
      adminClaims: { role: 'admin' },
      adminId: 'admin_test',
      driverId: 'driver_topup',
      amount: 20_000,
      adminNotes: 'Setoran QRIS statis',
      idempotencyKey: 'topup-test-1',
    });
    assert.equal(first.alreadyProcessed, false);
    assert.equal(first.balanceAfter, 21_000);
    assert.equal((await getDoc('users/driver_topup')).get('wallet_balance'), 21_000);

    const ledger = await getDoc(`wallet_ledger/${first.ledgerId}`);
    assert.equal(ledger.exists, true);
    assert.equal(ledger.get('type'), 'COMMISSION_TOPUP');
    assert.equal(ledger.get('amount'), 20_000);
    assert.equal(ledger.get('balance_after'), 21_000);

    const second = await topUpWalletEngine(db, {
      adminClaims: { role: 'admin' },
      adminId: 'admin_test',
      driverId: 'driver_topup',
      amount: 20_000,
      idempotencyKey: 'topup-test-1',
    });
    assert.equal(second.alreadyProcessed, true);
    assert.equal((await getDoc('users/driver_topup')).get('wallet_balance'), 21_000);

    await expectGatewayError(
      () =>
        topUpWalletEngine(db, {
          adminClaims: { role: 'driver' },
          adminId: 'driver_topup',
          driverId: 'driver_topup',
          amount: 1_000,
        }),
      'PERMISSION_DENIED',
    );
  });

  // ------------------------------------------------------------ finalize
  await test('Finalize menghitung ongkir dari matriks zona + komisi (X3)', async () => {
    await createUser('consumer_finalize', { role: 'consumer', balance: 0 });
    await createOrder('order_finalize', {
      consumerId: 'consumer_finalize',
      pickup: 'masjid-kampus',
      destination: 'perpustakaan-pusat',
      total: 4_000,
      deliveryFee: 4_000,
    });

    const result = await finalizeOrderEngine(db, {
      orderId: 'order_finalize',
      actorId: 'consumer_finalize',
    });
    assert.equal(result.finalized, true);
    assert.equal(result.reason, null);
    assert.deepEqual(result.pricing, {
      subtotal: 0,
      deliveryFee: 4_000,
      total: 4_000,
      commission: 50,
    });

    const order = await getDoc('orders/order_finalize');
    assert.equal(order.get('finalized'), true);
    assert.equal(order.get('delivery_fee'), 4_000);
    assert.equal(order.get('total_price'), 4_000);
    assert.equal(order.get('commission_fee'), 50);
    assert.equal((await getDoc('orders/order_finalize/events/finalized')).exists, true);
  });

  await test('Finalize memvalidasi subtotal item terhadap total klien', async () => {
    await createOrder('order_finalize_items', {
      consumerId: 'consumer_finalize',
      pickup: 'masjid-kampus',
      destination: 'perpustakaan-pusat',
      total: 14_000,
      deliveryFee: 4_000,
    });
    await db.doc('orders/order_finalize_items').update({
      items: [{ price: 10_000, qty: 1, options: [{ priceDelta: 0 }] }],
      subtotal: 10_000,
    });

    const result = await finalizeOrderEngine(db, { orderId: 'order_finalize_items' });
    assert.deepEqual(result.pricing, {
      subtotal: 10_000,
      deliveryFee: 4_000,
      total: 14_000,
      commission: 70,
    });
  });

  await test('Finalize menolak ongkir palsu -> EXPIRED PRICE_MISMATCH', async () => {
    await createOrder('order_price_tamper', {
      consumerId: 'consumer_finalize',
      pickup: 'masjid-kampus',
      destination: 'perpustakaan-pusat',
      total: 4_000,
      deliveryFee: 2_000,
    });

    const result = await finalizeOrderEngine(db, { orderId: 'order_price_tamper' });
    assert.equal(result.finalized, false);
    assert.equal(result.status, 'EXPIRED');
    assert.equal(result.reason, 'PRICE_MISMATCH');

    const order = await getDoc('orders/order_price_tamper');
    assert.equal(order.get('status'), 'EXPIRED');
    assert.equal(order.get('expire_reason'), 'PRICE_MISMATCH');
  });

  await test('Finalize hanya untuk konsumen pemilik order', async () => {
    await expectGatewayError(
      () =>
        finalizeOrderEngine(db, {
          orderId: 'order_finalize_items',
          actorId: 'orang_lain',
        }),
      'PERMISSION_DENIED',
    );
  });

// -------------------------------------------------------------- cancel
  await test('Batal sebelum klaim gratis tanpa strike', async () => {
    await createUser('consumer_cancel', { role: 'consumer', balance: 0 });
    await createOrder('order_cancel_placed', {
      consumerId: 'consumer_cancel',
      status: 'PLACED',
      pickup: 'masjid-kampus',
      destination: 'perpustakaan-pusat',
      total: 4_000,
      deliveryFee: 4_000,
    });

    const result = await cancelOrderEngine(db, {
      orderId: 'order_cancel_placed',
      actorId: 'consumer_cancel',
      actorRole: 'consumer',
    });
    assert.equal(result.status, 'CANCELLED');
    assert.equal(result.strikeApplied, false);
    assert.equal((await getDoc('orders/order_cancel_placed')).get('status'), 'CANCELLED');
  });

  await test('Batal setelah klaim memakai kuota gratis + melepas driver', async () => {
    await createUser('driver_cancel_release', { balance: 10_000 });
    await createOrder('order_cancel_claimed', {
      consumerId: 'consumer_cancel',
      pickup: 'masjid-kampus',
      destination: 'perpustakaan-pusat',
      total: 4_000,
      deliveryFee: 4_000,
    });
    await claimOrderEngine(db, {
      driverId: 'driver_cancel_release',
      orderId: 'order_cancel_claimed',
    });

    const result = await cancelOrderEngine(db, {
      orderId: 'order_cancel_claimed',
      actorId: 'consumer_cancel',
      actorRole: 'consumer',
    });
    assert.equal(result.status, 'CANCELLED');
    assert.equal(result.strikeApplied, false);
    assert.equal(result.freeCancelRemaining, 1);
    assert.equal((await getDoc('users/driver_cancel_release')).get('active_jobs'), 0);
    assert.equal(
      (await getDoc('orders/order_cancel_claimed/secrets/handover')).exists,
      false,
    );
  });

  await test('Kuota gratis habis -> pembatalan konsumen kena strike', async () => {
    await createUser('consumer_strike', { role: 'consumer', balance: 0 });
    const today = new Date().toISOString().slice(0, 10);
    await db.doc('users/consumer_strike').update({
      free_cancel_date: today,
      free_cancel_count: 2,
    });
    await createUser('driver_strike_release', { balance: 10_000 });
    await createOrder('order_cancel_strike', {
      consumerId: 'consumer_strike',
      pickup: 'masjid-kampus',
      destination: 'perpustakaan-pusat',
      total: 4_000,
      deliveryFee: 4_000,
    });
    await claimOrderEngine(db, {
      driverId: 'driver_strike_release',
      orderId: 'order_cancel_strike',
    });

    const result = await cancelOrderEngine(db, {
      orderId: 'order_cancel_strike',
      actorId: 'consumer_strike',
      actorRole: 'consumer',
    });
    assert.equal(result.strikeApplied, true);
    assert.equal((await getDoc('users/consumer_strike')).get('strikes').count, 1);
  });

  await test('Setelah AT_PICKUP konsumen tidak dapat membatalkan', async () => {
    await createUser('driver_after_pickup', { balance: 10_000 });
    await createOrder('order_cancel_pickup', {
      consumerId: 'consumer_cancel',
      pickup: 'masjid-kampus',
      destination: 'perpustakaan-pusat',
      total: 4_000,
      deliveryFee: 4_000,
    });
    await claimOrderEngine(db, {
      driverId: 'driver_after_pickup',
      orderId: 'order_cancel_pickup',
    });
    await db.doc('orders/order_cancel_pickup').update({ status: 'AT_PICKUP' });

    await expectGatewayError(
      () =>
        cancelOrderEngine(db, {
          orderId: 'order_cancel_pickup',
          actorId: 'consumer_cancel',
          actorRole: 'consumer',
        }),
      'INVALID_ORDER_STATE',
    );
    assert.equal(
      (await getDoc('orders/order_cancel_pickup')).get('status'),
      'AT_PICKUP',
    );
  });

  await test('Driver batal -> order kembali AWAITING_DRIVER + strike', async () => {
    await createUser('driver_cancel_self', { balance: 10_000 });
    await createOrder('order_cancel_driver', {
      consumerId: 'consumer_cancel',
      pickup: 'masjid-kampus',
      destination: 'perpustakaan-pusat',
      total: 4_000,
      deliveryFee: 4_000,
    });
    await claimOrderEngine(db, {
      driverId: 'driver_cancel_self',
      orderId: 'order_cancel_driver',
    });

    const result = await cancelOrderEngine(db, {
      orderId: 'order_cancel_driver',
      actorId: 'driver_cancel_self',
      actorRole: 'driver',
    });
    assert.equal(result.status, 'AWAITING_DRIVER');
    assert.equal(result.strikeApplied, true);

    const order = await getDoc('orders/order_cancel_driver');
    assert.equal(order.get('status'), 'AWAITING_DRIVER');
    assert.equal(order.get('driver_id'), null);

    const driver = await getDoc('users/driver_cancel_self');
    assert.equal(driver.get('active_jobs'), 0);
    assert.equal(driver.get('strikes').count, 1);
    assert.equal(
      (await getDoc('orders/order_cancel_driver/secrets/handover')).exists,
      false,
    );
  });

// --------------------------------------------------------------- expire
  await test('Cron expire: PLACED 5 mnt & AWAITING_DRIVER 10 mnt -> EXPIRED', async () => {
    await createOrder('order_expire_placed', {
      status: 'PLACED',
      pickup: 'masjid-kampus',
      destination: 'perpustakaan-pusat',
      total: 4_000,
      deliveryFee: 4_000,
    });
    await db.doc('orders/order_expire_placed').update({
      created_at: Timestamp.fromMillis(Date.now() - 6 * 60 * 1000),
    });

    await createOrder('order_expire_awaiting', {
      status: 'AWAITING_DRIVER',
      pickup: 'masjid-kampus',
      destination: 'perpustakaan-pusat',
      total: 4_000,
      deliveryFee: 4_000,
    });
    await db.doc('orders/order_expire_awaiting').update({
      created_at: Timestamp.fromMillis(Date.now() - 11 * 60 * 1000),
    });

    await createOrder('order_expire_fresh', {
      status: 'PLACED',
      pickup: 'masjid-kampus',
      destination: 'perpustakaan-pusat',
      total: 4_000,
      deliveryFee: 4_000,
    });

    const result = await expireOrdersEngine(db, { now: new Date() });
    assert.ok(result.expiredPlaced >= 1, 'Minimal satu PLACED kedaluwarsa');
    assert.ok(
      result.expiredAwaiting >= 1,
      'Minimal satu AWAITING_DRIVER kedaluwarsa',
    );

    assert.equal(
      (await getDoc('orders/order_expire_placed')).get('status'),
      'EXPIRED',
    );
    assert.equal(
      (await getDoc('orders/order_expire_awaiting')).get('status'),
      'EXPIRED',
    );
    assert.equal(
      (await getDoc('orders/order_expire_fresh')).get('status'),
      'PLACED',
    );
    assert.equal(
      (await getDoc('orders/order_expire_placed/events/expired_merchant_timeout'))
        .exists,
      true,
    );
  });

  // ------------------------------------------------- Fase 5: OSRM & tarif
  await test('OSRM tier: rekomendasi harga sesuai radius Tuntungan', async () => {
    const tier1 = recommendFare(800);
    assert.equal(tier1.tier, 1);
    assert.equal(tier1.basePrice, 5_000);
    assert.equal(tier1.minPrice, 5_000);
    assert.equal(tier1.maxPrice, 6_000);

    const tier2 = recommendFare(2_100);
    assert.equal(tier2.tier, 2);
    assert.equal(tier2.minPrice, 6_000);
    assert.equal(tier2.maxPrice, 8_000);
    assert.equal(
      tier2.label,
      'Jarak 2.1 km • Rekomendasi: Rp 6.000 - Rp 8.000',
    );

    const tier3 = recommendFare(3_000);
    assert.equal(tier3.tier, 3);
    assert.equal(tier3.basePrice, 9_000);
    assert.equal(tier3.minPrice, 8_000);
    assert.equal(tier3.maxPrice, 10_000);

    assert.equal(FARE_TIERS.length, 3);
  });

  await test('OSRM: fallback haversine saat jaringan gagal + parsing respons', async () => {
    const from = { latitude: 3.5479, longitude: 98.6469 };
    const to = { latitude: 3.5523, longitude: 98.6542 };

    const offline = await fetchOsrmRoute(from, to, {
      fetcher: async () => {
        throw new Error('offline');
      },
    });
    assert.equal(offline.source, 'HAVERSINE');
    assert.ok(offline.distanceMeters > 0);

    const online = await fetchOsrmRoute(from, to, {
      fetcher: async () => ({
        ok: true,
        json: async () => ({
          code: 'Ok',
          routes: [{ distance: 2_100, duration: 378 }],
        }),
      }),
    });
    assert.equal(online.source, 'OSRM');
    assert.equal(online.distanceMeters, 2_100);
    assert.equal(online.durationSeconds, 378);

    const estimate = await estimateFare(from, to, {
      fetcher: async () => ({
        ok: true,
        json: async () => ({
          code: 'Ok',
          routes: [{ distance: 2_100, duration: 378 }],
        }),
      }),
    });
    assert.equal(estimate.tier, 2);
    assert.equal(estimate.minPrice, 6_000);
    assert.equal(estimate.maxPrice, 8_000);
  });

  await test('Seeder hub UINSU Tuntungan: 6 landmark + config tier', async () => {
    const result = await seedTuntunganHub(db);
    assert.equal(result.landmarkCount, 6);
    assert.equal(result.zone1Count, 3);
    assert.equal(result.zone2Count, 1);
    assert.equal(result.zone3Count, 2);

    const snapshot = await db.collection('landmarks').get();
    for (const landmark of TUNTUNGAN_HUB_LANDMARKS) {
      assert.equal(docZone(snapshot, landmark.id), landmark.zone_group);
    }

    const config = await getDoc('config/tuntungan_hub');
    assert.equal(config.exists, true);
    assert.equal(config.get('hub_id'), 'uinsu-tuntungan');
    assert.equal(config.get('fare_tiers').length, 3);
  });

  // --------------------------------------------- Fase 5: Bidding Engine
  await test('submitBid: saldo < Rp 5.000 gagal, saldo cukup sukses', async () => {
    await createUser('driver_bid_low', { balance: 4_999 });
    await createOrder('order_bid_low', { status: 'AWAITING_DRIVER' });
    await expectGatewayError(
      () =>
        submitBidEngine(db, {
          driverId: 'driver_bid_low',
          orderId: 'order_bid_low',
          offeredPrice: 7_000,
        }),
      'INSUFFICIENT_BALANCE',
    );
    assert.equal(
      (await getDoc('orders/order_bid_low/bids/bid_driver_bid_low')).exists,
      false,
    );

    await createUser('driver_bid_ok', { balance: 10_000 });
    await createOrder('order_bid_ok', { status: 'AWAITING_DRIVER' });

    const result = await submitBidEngine(db, {
      driverId: 'driver_bid_ok',
      orderId: 'order_bid_ok',
      offeredPrice: 7_000,
      estimatedArrivalMinutes: 8,
      platNumber: 'BK 1234 AB',
      vehicleModel: 'Honda Beat',
    });
    assert.equal(result.offeredPrice, 7_000);
    assert.equal(result.commissionEstimate, 50);
    assert.equal(result.updated, false);

    const order = await getDoc('orders/order_bid_ok');
    assert.equal(order.get('status'), 'SEARCHING_BIDS');
    assert.equal(order.get('bid_count'), 1);

    const bid = await getDoc('orders/order_bid_ok/bids/bid_driver_bid_ok');
    assert.equal(bid.exists, true);
    assert.equal(bid.get('offeredPrice'), 7_000);
    assert.equal(bid.get('status'), 'PENDING');
    assert.equal(bid.get('platNumber'), 'BK 1234 AB');
    assert.equal(bid.get('estimatedArrivalMinutes'), 8);
    assert.equal(bid.get('driverId'), 'driver_bid_ok');
  });

  await test('submitBid: offeredPrice < Rp 3.000 ditolak', async () => {
    await createUser('driver_bid_cheap', { balance: 10_000 });
    await createOrder('order_bid_cheap', { status: 'AWAITING_DRIVER' });

    await expectGatewayError(
      () =>
        submitBidEngine(db, {
          driverId: 'driver_bid_cheap',
          orderId: 'order_bid_cheap',
          offeredPrice: 2_999,
        }),
      'BID_TOO_LOW',
    );
    assert.equal(
      (await getDoc('orders/order_bid_cheap/bids/bid_driver_bid_cheap')).exists,
      false,
    );
  });

  await test('acceptBid: atomik kunci order + komisi 0,5% + bid lain REJECTED', async () => {
    await createUser('driver_accept_a', { balance: 10_000 });
    await createUser('driver_accept_b', { balance: 10_000 });
    await createOrder('order_accept', { status: 'AWAITING_DRIVER' });

    await submitBidEngine(db, {
      driverId: 'driver_accept_a',
      orderId: 'order_accept',
      offeredPrice: 7_000,
      estimatedArrivalMinutes: 6,
    });
    await submitBidEngine(db, {
      driverId: 'driver_accept_b',
      orderId: 'order_accept',
      offeredPrice: 8_500,
      estimatedArrivalMinutes: 9,
    });

    // Bukan pemilik order -> ORDER_NOT_OWNER.
    await expectGatewayError(
      () =>
        acceptBidEngine(db, {
          consumerId: 'intruder',
          orderId: 'order_accept',
          bidId: 'bid_driver_accept_a',
        }),
      'ORDER_NOT_OWNER',
    );

    const result = await acceptBidEngine(db, {
      consumerId: 'consumer_test',
      orderId: 'order_accept',
      bidId: 'bid_driver_accept_a',
    });
    assert.equal(result.finalPrice, 7_000);
    assert.equal(result.commission, 50);
    assert.equal(result.balanceAfter, 9_950);
    assert.equal(result.rejectedBids, 1);

    const order = await getDoc('orders/order_accept');
    assert.equal(order.get('status'), 'ACCEPTED');
    assert.equal(order.get('driver_id'), 'driver_accept_a');
    assert.equal(order.get('final_price'), 7_000);
    assert.equal(order.get('total_price'), 7_000);
    assert.equal(order.get('commission_fee'), 50);

    const winnerBid = await getDoc('orders/order_accept/bids/bid_driver_accept_a');
    assert.equal(winnerBid.get('status'), 'ACCEPTED');
    const loserBid = await getDoc('orders/order_accept/bids/bid_driver_accept_b');
    assert.equal(loserBid.get('status'), 'REJECTED');
    assert.equal(loserBid.get('rejected_reason'), 'BID_NOT_SELECTED');

    const driver = await getDoc('users/driver_accept_a');
    assert.equal(driver.get('wallet_balance'), 9_950);
    assert.equal(driver.get('active_jobs'), 1);

    const ledger = await getDoc('wallet_ledger/commission_order_accept');
    assert.equal(ledger.exists, true);
    assert.equal(ledger.get('amount'), -50);
    assert.equal(ledger.get('balance_after'), 9_950);
    assert.equal(ledger.get('idempotency_key'), 'commission:order_accept');

    // Order sudah terkunci -> penawaran kedua tidak bisa diterima.
    await expectGatewayError(
      () =>
        acceptBidEngine(db, {
          consumerId: 'consumer_test',
          orderId: 'order_accept',
          bidId: 'bid_driver_accept_b',
        }),
      'ORDER_NOT_BIDDING',
    );
  });

  console.log(
    `\nHasil: ${STATE.passed} passed, ${STATE.failed} failed (${STATE.passed + STATE.failed} test).`,
  );
  if (STATE.failed > 0) {
    console.error('\nDetail kegagalan:');
    for (const failure of STATE.failures) {
      console.error(`- ${failure.name}`);
      console.error(failure.error);
    }
    process.exitCode = 1;
  }
}

function docZone(snapshot, id) {
  const doc = snapshot.docs.find((item) => item.id === id);
  return doc ? doc.get('zone_group') : undefined;
}

main().catch((error) => {
  console.error('\nTest engine gagal dijalankan:');
  console.error(error);
  process.exitCode = 1;
});
