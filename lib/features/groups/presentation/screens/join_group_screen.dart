import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/pricing_tier_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/countdown_timer_widget.dart';
import '../../../../shared/widgets/group_progress_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/group_provider.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  final String groupId;

  const JoinGroupScreen({super.key, required this.groupId});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Suppliers cannot join buyer groups
    if (user.userType == AppConstants.userTypeSupplier) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suppliers cannot join buyer groups.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quantity = int.parse(_quantityController.text.trim());

      await ref.read(groupServiceProvider).joinGroup(
            groupId: widget.groupId,
            userId: user.id,
            businessName: user.businessName,
            quantity: quantity,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You joined the group successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/group/${widget.groupId}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupByIdProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Join Group')),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Group not found'));
          }

          final qty = int.tryParse(_quantityController.text) ?? 0;
          final activeTier =
              PricingEngine.getActiveTier(group.pricingTiers, group.totalQuantity + qty);
          final estimatedTotal =
              (activeTier?.pricePerUnit ?? 0) * qty;
          final tokenAmount = estimatedTotal * ((group.tokenPercentage ?? 10) / 100);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Group summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.productName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.supplierName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Price',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),
                              Text(
                                Formatters.formatCurrency(
                                    group.currentPricePerUnit),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          CountdownTimerWidget(
                            deadline: group.deadline,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Group progress
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: GroupProgressWidget(
                      group: group, showTiers: true, compact: false),
                ),
                const SizedBox(height: 20),

                // Quantity input
                const Text(
                  'Enter Your Quantity',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => Validators.validateQuantity(
                    v,
                    min: group.minimumQuantity,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Enter quantity',
                    prefixIcon: Icon(Icons.inventory_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // Order summary
                if (qty > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          label: 'Quantity',
                          value: '$qty units',
                        ),
                        _SummaryRow(
                          label: 'Price per unit',
                          value: Formatters.formatCurrency(
                              activeTier?.pricePerUnit ?? 0),
                        ),
                        const Divider(height: 16),
                        _SummaryRow(
                          label: 'Total Amount',
                          value: Formatters.formatCurrency(estimatedTotal),
                          isBold: true,
                        ),
                        _SummaryRow(
                          label: 'Token Amount (${group.tokenPercentage ?? 10}%)',
                          value: Formatters.formatCurrency(tokenAmount),
                          valueColor: AppColors.accent,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '⚠️ Token amount is payable after group completion. Final payment goes directly to the supplier.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                AppButton(
                  label: 'Join Group',
                  onPressed: _joinGroup,
                  isLoading: _isLoading,
                  prefixIcon: Icons.group_add_outlined,
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ??
                  (isBold ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
