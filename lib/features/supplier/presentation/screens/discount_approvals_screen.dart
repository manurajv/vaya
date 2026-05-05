import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/group_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/supplier_provider.dart';

class DiscountApprovalsScreen extends ConsumerWidget {
  const DiscountApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(pendingApprovalGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Discount Approvals')),
      body: groupsAsync.when(
        data: (groups) => groups.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 64, color: AppColors.success),
                    const SizedBox(height: 16),
                    const Text('All caught up!',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    const Text('No pending discount requests.',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.textHint)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groups.length,
                itemBuilder: (ctx, i) =>
                    _ApprovalCard(group: groups[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ApprovalCard extends ConsumerStatefulWidget {
  final GroupModel group;
  const _ApprovalCard({required this.group});

  @override
  ConsumerState<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends ConsumerState<_ApprovalCard> {
  final _noteCtrl = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _decide(bool approve) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(supplierProductServiceProvider).approveDiscount(
            widget.group.id,
            approve,
            _noteCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve
                ? 'Discount approved! Group is now active.'
                : 'Discount request rejected.'),
            backgroundColor:
                approve ? AppColors.success : AppColors.error,
          ),
        );
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.warningLight,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_outlined,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.productName,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/group/${group.id}'),
                  child: const Text('View Group',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group stats
                Row(
                  children: [
                    _InfoChip(
                        icon: Icons.people_outline,
                        label: '${group.memberCount} buyers'),
                    const SizedBox(width: 10),
                    _InfoChip(
                        icon: Icons.inventory_outlined,
                        label: '${group.totalQuantity} units'),
                    const SizedBox(width: 10),
                    _InfoChip(
                        icon: Icons.currency_rupee,
                        label: Formatters.formatCurrency(
                            group.currentPricePerUnit) +
                            '/unit'),
                  ],
                ),
                const SizedBox(height: 12),

                // Total order value
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Order Value',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                      Text(
                        Formatters.formatCurrency(group.totalOrderValue),
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Pricing tiers requested
                const Text('Requested Pricing Tiers',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                ...group.pricingTiers.map((tier) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_right,
                              size: 16, color: AppColors.textHint),
                          Text(
                            '${tier.minQuantity}+ units → ${Formatters.formatCurrency(tier.pricePerUnit)}/unit',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 14),

                // Note field
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Note to buyers (optional)',
                    hintText: 'e.g., Approved for this batch only',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Reject',
                        variant: AppButtonVariant.danger,
                        onPressed: _isProcessing
                            ? null
                            : () => _decide(false),
                        isLoading: _isProcessing,
                        prefixIcon: Icons.close,
                        height: 44,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: 'Approve Discount',
                        onPressed: _isProcessing
                            ? null
                            : () => _decide(true),
                        isLoading: _isProcessing,
                        prefixIcon: Icons.check_circle_outline,
                        height: 44,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
