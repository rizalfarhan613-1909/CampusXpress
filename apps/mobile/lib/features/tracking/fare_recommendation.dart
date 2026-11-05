import 'dart:math' as math;

import '../../core/utils/formatters.dart';

/// Rentang harga rekomendasi OSRM (identik dengan
/// `backend/functions/src/core/osrmRouting.ts`).
class FareRecommendation {
  const FareRecommendation({
    required this.tier,
    required this.basePrice,
    required this.minPrice,
    required this.maxPrice,
    required this.distanceKm,
    required this.estimatedArrivalMinutes,
    required this.label,
  });

  final int tier;
  final int basePrice;
  final int minPrice;
  final int maxPrice;
  final double distanceKm;
  final int estimatedArrivalMinutes;
  final String label;
}

int _roundTo(int value, int step) => (value / step).round() * step;

FareRecommendation recommendFare(double distanceMeters) {
  final meters = distanceMeters.isFinite && distanceMeters > 0
      ? distanceMeters
      : 0.0;
  final km = meters / 1000;

  late final int tier;
  late final int basePrice;
  if (km <= 1) {
    tier = 1;
    basePrice = 5000;
  } else if (km <= 2.5) {
    tier = 2;
    basePrice = 7000;
  } else {
    tier = 3;
    basePrice = 7000 + 2000 * (km - 2.5).ceil();
  }

  final minPrice = math.max(5000, _roundTo(basePrice - 1000, 500));
  final maxPrice = math.max(minPrice, _roundTo(basePrice + 1000, 500));
  final etaMinutes = math.max(1, (meters / 1000 / 20 * 60).round());

  return FareRecommendation(
    tier: tier,
    basePrice: basePrice,
    minPrice: minPrice,
    maxPrice: maxPrice,
    distanceKm: (km * 10).round() / 10,
    estimatedArrivalMinutes: etaMinutes,
    label:
        'Jarak ${km.toStringAsFixed(1)} km • Rekomendasi: '
        '${formatRupiah(minPrice)} - ${formatRupiah(maxPrice)}',
  );
}

String formatRecommendationBadge(double distanceMeters) =>
    recommendFare(distanceMeters).label;