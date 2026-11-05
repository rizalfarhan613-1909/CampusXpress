import 'package:campus_express/features/tracking/fare_recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rekomendasi harga OSRM (Fase 5)', () {
    test('Tier 1: 800 m -> Rp 5.000 - Rp 6.000', () {
      final recommendation = recommendFare(800);
      expect(recommendation.tier, 1);
      expect(recommendation.basePrice, 5000);
      expect(recommendation.minPrice, 5000);
      expect(recommendation.maxPrice, 6000);
    });

    test('Tier 2: 2.100 m -> Rp 6.000 - Rp 8.000', () {
      final recommendation = recommendFare(2100);
      expect(recommendation.tier, 2);
      expect(recommendation.basePrice, 7000);
      expect(recommendation.minPrice, 6000);
      expect(recommendation.maxPrice, 8000);
      expect(recommendation.label, contains('Jarak 2.1 km'));
      expect(recommendation.label, contains('Rekomendasi'));
    });

    test('Tier 3: 3.000 m -> basis Rp 9.000', () {
      final recommendation = recommendFare(3000);
      expect(recommendation.tier, 3);
      expect(recommendation.basePrice, 9000);
      expect(recommendation.minPrice, 8000);
      expect(recommendation.maxPrice, 10000);
    });
  });
}