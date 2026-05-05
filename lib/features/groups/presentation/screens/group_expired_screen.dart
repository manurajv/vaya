import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';

class GroupExpiredScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupExpiredScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupExpiredScreen> createState() => _GroupExpiredScreenState();
}

class _GroupExpiredScreenState extends ConsumerState<GroupExpiredScreen> {
  bool _isExtending = false;

  Future<void> _extendDeadline() async {
    setState(() => _isExtending = true);
    try {
      await ref.read(groupServiceProvider).extendDeadline(
            widget.groupId,
            AppConstants.groupExtensionHours,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Deadline extended by ${AppConstants.groupExtensionHours} hours. Awaiting supplier approval.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExtending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupByIdProvider(widget.groupId));

    return groupAsync.when(
      data: (group) {
        if (group == null) {
          return Scaffold(
              appBar: AppBar(), body: const Center(child: Text('Not found')));
        }

        final otherGroupsAsync =
            ref.watch(groupsByProductProvider(group.productId));

        return Scaffold(
          appBar: AppBar(title: const Text('Group Expired')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Status banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.timer_off_outlined,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    const Text(
                      'This group has expired',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The group for "${group.productName}" did not reach its target in time.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatChip(
                          label: 'Reached',
                          value: '${group.totalQuantity} units',
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          label: 'Target',
                          value:
                              '${group.targetQuantity ?? group.minimumQuantity} units',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Options
              const Text(
                'What would you like to do?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Option 1: Join another group
              otherGroupsAsync.when(
                data: (otherGroups) {
                  // Exclude current group
                  final available = otherGroups
                      .where((g) => g.id != widget.groupId)
                      .toList();

                  if (available.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _OptionCard(
                          icon: Icons.group_add_outlined,
                          title: 'Join Another Group',
                          subtitle:
                              '${available.length} active group(s) available for this product',
                          color: AppColors.primary,
                          onTap: () => context
                              .push('/join-group/${available.first.id}'),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Option 2: Fulfill demand yourself
              _OptionCard(
                icon: Icons.person_outlined,
                title: 'Fulfill Demand Yourself',
                subtitle:
                    'Place an individual order for the remaining ${(group.targetQuantity ?? group.minimumQuantity) - group.totalQuantity} units',
                color: AppColors.accent,
                onTap: () => context.push('/product/${group.productId}'),
              ),
              const SizedBox(height: 12),

              // Option 3: Extend deadline (creator only)
              if (ref.watch(currentUserIdProvider) == group.creatorId &&
                  (group.extensionCount ?? 0) < 2) ...[
                _OptionCard(
                  icon: Icons.schedule_outlined,
                  title: 'Request Time Extension',
                  subtitle:
                      'Extend the deadline by ${AppConstants.groupExtensionHours} hours (subject to supplier approval). ${2 - (group.extensionCount ?? 0)} extension(s) remaining.',
                  color: AppColors.info,
                  onTap: _isExtending ? null : _extendDeadline,
                  isLoading: _isExtending,
                ),
                const SizedBox(height: 12),
              ],

              // Option 4: Browse products
              _OptionCard(
                icon: Icons.search_outlined,
                title: 'Browse Other Products',
                subtitle: 'Find similar products with active group deals',
                color: AppColors.success,
                onTap: () => context.go('/home'),
              ),

              const SizedBox(height: 24),

              // Note about token refund
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.info, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'If you paid a token amount, it will be refunded within 5-7 business days. Contact support if you have any issues.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.info,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: AppBar(), body: Center(child: Text('Error: $e'))),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: color),
                    )
                  : Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: onTap != null
                              ? AppColors.textPrimary
                              : AppColors.textHint)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: onTap != null ? color : AppColors.border, size: 20),
          ],
        ),
      ),
    );
  }
}
