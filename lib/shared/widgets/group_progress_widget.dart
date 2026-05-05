import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/group_model.dart';
import '../../shared/models/pricing_tier_model.dart';

class GroupProgressWidget extends StatelessWidget {
  final GroupModel group;
  final bool showTiers;
  final bool compact;

  const GroupProgressWidget({
    super.key,
    required this.group,
    this.showTiers = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeTier =
        PricingEngine.getActiveTier(group.pricingTiers, group.totalQuantity);
    final nextTier =
        PricingEngine.getNextTier(group.pricingTiers, group.totalQuantity);
    final progress =
        PricingEngine.progressToNextTier(group.pricingTiers, group.totalQuantity);
    final unitsToNext =
        PricingEngine.unitsToNextTier(group.pricingTiers, group.totalQuantity);

    if (compact) {
      return _buildCompact(context, activeTier, nextTier, progress, unitsToNext);
    }

    return _buildFull(context, activeTier, nextTier, progress, unitsToNext);
  }

  Widget _buildCompact(
    BuildContext context,
    PricingTierModel? activeTier,
    PricingTierModel? nextTier,
    double progress,
    int unitsToNext,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${group.totalQuantity} units ordered',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (activeTier != null)
              Text(
                Formatters.formatCurrency(activeTier.pricePerUnit),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        LinearPercentIndicator(
          percent: progress.clamp(0.0, 1.0),
          lineHeight: 8,
          backgroundColor: AppColors.surfaceVariant,
          progressColor: nextTier == null ? AppColors.success : AppColors.primary,
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
          animation: true,
          animationDuration: 500,
        ),
        if (nextTier != null) ...[
          const SizedBox(height: 4),
          Text(
            '$unitsToNext more units → ${Formatters.formatCurrency(nextTier.pricePerUnit)}/unit',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFull(
    BuildContext context,
    PricingTierModel? activeTier,
    PricingTierModel? nextTier,
    double progress,
    int unitsToNext,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current stats row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Ordered',
                value: '${group.totalQuantity}',
                subtitle: 'units',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Current Price',
                value: activeTier != null
                    ? Formatters.formatCurrency(activeTier.pricePerUnit)
                    : '—',
                subtitle: 'per unit',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Members',
                value: '${group.memberCount}',
                subtitle: 'buyers',
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Progress bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Group Progress',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (nextTier != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unitsToNext units to next tier',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Best Price Unlocked!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              percent: progress.clamp(0.0, 1.0),
              lineHeight: 12,
              backgroundColor: AppColors.surfaceVariant,
              progressColor:
                  nextTier == null ? AppColors.success : AppColors.primary,
              barRadius: const Radius.circular(6),
              padding: EdgeInsets.zero,
              animation: true,
              animationDuration: 800,
            ),
          ],
        ),

        // Pricing tiers
        if (showTiers && group.pricingTiers.isNotEmpty) ...[
          const SizedBox(height: 16),
          _PricingTiersRow(
            tiers: group.pricingTiers,
            currentQuantity: group.totalQuantity,
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingTiersRow extends StatelessWidget {
  final List<PricingTierModel> tiers;
  final int currentQuantity;

  const _PricingTiersRow({
    required this.tiers,
    required this.currentQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = List<PricingTierModel>.from(tiers)
      ..sort((a, b) => a.minQuantity.compareTo(b.minQuantity));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing Tiers',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: sorted.asMap().entries.map((entry) {
            final index = entry.key;
            final tier = entry.value;
            final isUnlocked = currentQuantity >= tier.minQuantity;
            final isActive = PricingEngine.getActiveTier(tiers, currentQuantity)
                    ?.minQuantity ==
                tier.minQuantity;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _TierChip(
                      tier: tier,
                      isUnlocked: isUnlocked,
                      isActive: isActive,
                    ),
                  ),
                  if (index < sorted.length - 1)
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: AppColors.textHint,
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TierChip extends StatelessWidget {
  final PricingTierModel tier;
  final bool isUnlocked;
  final bool isActive;

  const _TierChip({
    required this.tier,
    required this.isUnlocked,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    if (isActive) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
      borderColor = AppColors.primary;
    } else if (isUnlocked) {
      bgColor = AppColors.successLight;
      textColor = AppColors.success;
      borderColor = AppColors.success;
    } else {
      bgColor = AppColors.surfaceVariant;
      textColor = AppColors.textSecondary;
      borderColor = AppColors.border;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            '${tier.minQuantity}+',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.8),
            ),
          ),
          Text(
            Formatters.formatCurrency(tier.pricePerUnit),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          if (isUnlocked && !isActive)
            Icon(Icons.check_circle, size: 10, color: AppColors.success),
        ],
      ),
    );
  }
}
