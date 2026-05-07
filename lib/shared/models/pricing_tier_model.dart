class PricingTierModel {
  final int minQuantity;
  final int? maxQuantity; // null means unlimited
  final double pricePerUnit;
  final String? label; // e.g., "Bronze", "Silver", "Gold"

  const PricingTierModel({
    required this.minQuantity,
    this.maxQuantity,
    required this.pricePerUnit,
    this.label,
  });

  factory PricingTierModel.fromMap(Map<String, dynamic> map) {
    return PricingTierModel(
      minQuantity: (map['minQuantity'] as num).toInt(),
      maxQuantity: map['maxQuantity'] != null
          ? (map['maxQuantity'] as num).toInt()
          : null,
      pricePerUnit: (map['pricePerUnit'] as num).toDouble(),
      label: map['label'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minQuantity': minQuantity,
      'maxQuantity': maxQuantity,
      'pricePerUnit': pricePerUnit,
      'label': label,
    };
  }

  /// Returns true if the given quantity qualifies for this tier
  bool qualifies(int quantity) {
    if (quantity < minQuantity) return false;
    if (maxQuantity != null && quantity > maxQuantity!) return false;
    return true;
  }

  PricingTierModel copyWith({
    int? minQuantity,
    int? maxQuantity,
    double? pricePerUnit,
    String? label,
  }) {
    return PricingTierModel(
      minQuantity: minQuantity ?? this.minQuantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      label: label ?? this.label,
    );
  }

  @override
  String toString() =>
      'PricingTier(min: $minQuantity, max: $maxQuantity, price: $pricePerUnit)';
}

/// Utility to compute current price based on total quantity and tiers
class PricingEngine {
  /// Returns the applicable tier for the given quantity.
  /// Picks the best (highest [minQuantity]) tier that [qualifies] for [totalQuantity].
  static PricingTierModel? getActiveTier(
    List<PricingTierModel> tiers,
    int totalQuantity,
  ) {
    if (tiers.isEmpty) return null;

    final sorted = List<PricingTierModel>.from(tiers)
      ..sort((a, b) => b.minQuantity.compareTo(a.minQuantity));

    for (final tier in sorted) {
      if (tier.qualifies(totalQuantity)) return tier;
    }

    // Below all bracket mins — show list price from the entry tier
    final entry = tiers.reduce(
      (a, b) => a.minQuantity < b.minQuantity ? a : b,
    );
    return entry;
  }

  /// Returns the next tier that hasn't been unlocked yet
  static PricingTierModel? getNextTier(
    List<PricingTierModel> tiers,
    int totalQuantity,
  ) {
    if (tiers.isEmpty) return null;

    final sorted = List<PricingTierModel>.from(tiers)
      ..sort((a, b) => a.minQuantity.compareTo(b.minQuantity));

    for (final tier in sorted) {
      if (totalQuantity < tier.minQuantity) {
        return tier;
      }
    }
    return null;
  }

  /// Returns units needed to reach the next tier
  static int unitsToNextTier(
    List<PricingTierModel> tiers,
    int totalQuantity,
  ) {
    final next = getNextTier(tiers, totalQuantity);
    if (next == null) return 0;
    return next.minQuantity - totalQuantity;
  }

  /// Returns total price for a given quantity
  static double calculateTotal(
    List<PricingTierModel> tiers,
    int quantity,
  ) {
    final tier = getActiveTier(tiers, quantity);
    if (tier == null) return 0;
    return tier.pricePerUnit * quantity;
  }

  /// Returns progress percentage toward the next tier (0.0 to 1.0)
  static double progressToNextTier(
    List<PricingTierModel> tiers,
    int totalQuantity,
  ) {
    if (tiers.isEmpty) return 1.0;

    final sorted = List<PricingTierModel>.from(tiers)
      ..sort((a, b) => a.minQuantity.compareTo(b.minQuantity));

    // Find current and next tier
    PricingTierModel? currentTier;
    PricingTierModel? nextTier;

    for (int i = 0; i < sorted.length; i++) {
      if (totalQuantity >= sorted[i].minQuantity) {
        currentTier = sorted[i];
        if (i + 1 < sorted.length) {
          nextTier = sorted[i + 1];
        }
      }
    }

    if (nextTier == null) return 1.0; // All tiers unlocked

    final start = currentTier?.minQuantity ?? 0;
    final end = nextTier.minQuantity;
    if (end <= start) return 1.0;

    return ((totalQuantity - start) / (end - start)).clamp(0.0, 1.0);
  }
}
