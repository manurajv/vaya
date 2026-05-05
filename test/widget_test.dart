// VAYA – Widget Tests
// Run: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:vaya/shared/models/pricing_tier_model.dart';

void main() {
  group('PricingEngine', () {
    final tiers = [
      const PricingTierModel(minQuantity: 100, pricePerUnit: 1200),
      const PricingTierModel(minQuantity: 500, pricePerUnit: 1100),
      const PricingTierModel(minQuantity: 1000, pricePerUnit: 1000),
    ];

    test('returns base tier for quantity below first tier', () {
      final tier = PricingEngine.getActiveTier(tiers, 50);
      expect(tier?.pricePerUnit, 1200);
    });

    test('returns correct tier for exact match', () {
      final tier = PricingEngine.getActiveTier(tiers, 500);
      expect(tier?.pricePerUnit, 1100);
    });

    test('returns best tier for quantity above all tiers', () {
      final tier = PricingEngine.getActiveTier(tiers, 2000);
      expect(tier?.pricePerUnit, 1000);
    });

    test('returns next tier correctly', () {
      final next = PricingEngine.getNextTier(tiers, 300);
      expect(next?.minQuantity, 500);
    });

    test('returns null next tier when all unlocked', () {
      final next = PricingEngine.getNextTier(tiers, 1000);
      expect(next, isNull);
    });

    test('calculates units to next tier', () {
      final units = PricingEngine.unitsToNextTier(tiers, 300);
      expect(units, 200); // 500 - 300
    });

    test('calculates total correctly', () {
      final total = PricingEngine.calculateTotal(tiers, 500);
      expect(total, 500 * 1100);
    });

    test('progress to next tier is between 0 and 1', () {
      final progress = PricingEngine.progressToNextTier(tiers, 300);
      expect(progress, greaterThanOrEqualTo(0.0));
      expect(progress, lessThanOrEqualTo(1.0));
    });
  });
}
