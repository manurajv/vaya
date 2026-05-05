import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../providers/group_provider.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  final String productId;

  const CreateGroupScreen({super.key, required this.productId});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  String _selectedMode = AppConstants.groupModeBuyerInitiated;
  int _durationHours = 48;
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final product = ref.read(productByIdProvider(widget.productId)).value;
    if (product == null) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final quantity = int.parse(_quantityController.text.trim());
      final deadline = DateTime.now().add(Duration(hours: _durationHours));

      final groupId = await ref.read(groupServiceProvider).createGroup(
            productId: product.id,
            productName: product.name,
            productImageUrl:
                product.imageUrls.isNotEmpty ? product.imageUrls.first : null,
            supplierId: product.supplierId,
            supplierName: product.supplierName,
            creatorId: user.id,
            creatorBusinessName: user.businessName,
            mode: _selectedMode,
            pricingTiers: product.pricingTiers,
            minimumQuantity: product.minimumOrderQuantity,
            targetQuantity: null,
            creatorQuantity: quantity,
            deadline: deadline,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/group/$groupId');
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
    final productAsync = ref.watch(productByIdProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Product not found'));
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Product summary
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 56,
                          height: 56,
                          color: AppColors.border,
                          child: product.imageUrls.isNotEmpty
                              ? Image.network(product.imageUrls.first,
                                  fit: BoxFit.cover)
                              : const Icon(Icons.inventory_2_outlined,
                                  color: AppColors.textHint),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name,
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            Text(product.supplierName,
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            Text(
                                'Min. ${product.minimumOrderQuantity} ${product.unit}',
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: AppColors.textHint)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Group Mode
                const Text(
                  'Group Mode',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _ModeSelector(
                  selected: _selectedMode,
                  onChanged: (mode) => setState(() => _selectedMode = mode),
                ),
                const SizedBox(height: 20),

                // Quantity
                const Text(
                  'Your Quantity',
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
                    min: product.minimumOrderQuantity,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter quantity',
                    suffixText: product.unit,
                    prefixIcon: const Icon(Icons.inventory_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // Duration
                const Text(
                  'Group Duration',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _DurationSelector(
                  selected: _durationHours,
                  onChanged: (h) => setState(() => _durationHours = h),
                ),
                const SizedBox(height: 20),

                // Pricing tiers info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: AppColors.info, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Pricing Tiers for this product',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...product.sortedTiers.map((tier) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${tier.minQuantity}+ units → ₹${tier.pricePerUnit.toStringAsFixed(0)}/unit',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.info,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                AppButton(
                  label: 'Create Group',
                  onPressed: _createGroup,
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

class _ModeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _ModeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModeOption(
          value: AppConstants.groupModeBuyerInitiated,
          selected: selected,
          onChanged: onChanged,
          title: 'Buyer Initiated',
          subtitle:
              'You form the group and request the supplier to approve the discount.',
          icon: Icons.people_outline,
        ),
        const SizedBox(height: 8),
        _ModeOption(
          value: AppConstants.groupModeSupplierTarget,
          selected: selected,
          onChanged: onChanged,
          title: 'Supplier Target',
          subtitle:
              'Join a group where the supplier has set a quantity target for discount.',
          icon: Icons.store_outlined,
        ),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String value;
  final String selected;
  final ValueChanged<String> onChanged;
  final String title;
  final String subtitle;
  final IconData icon;

  const _ModeOption({
    required this.value,
    required this.selected,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVariant : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: selected,
              onChanged: (v) => onChanged(v!),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _DurationSelector(
      {required this.selected, required this.onChanged});

  static const _options = [
    {'hours': 12, 'label': '12 Hours'},
    {'hours': 24, 'label': '1 Day'},
    {'hours': 48, 'label': '2 Days'},
    {'hours': 72, 'label': '3 Days'},
    {'hours': 168, 'label': '7 Days'},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((opt) {
        final hours = opt['hours'] as int;
        final label = opt['label'] as String;
        final isSelected = hours == selected;
        return GestureDetector(
          onTap: () => onChanged(hours),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
