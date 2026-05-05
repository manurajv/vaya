import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/supplier_provider.dart';

class SetGroupTargetScreen extends ConsumerStatefulWidget {
  final String? preselectedProductId;
  const SetGroupTargetScreen({super.key, this.preselectedProductId});

  @override
  ConsumerState<SetGroupTargetScreen> createState() =>
      _SetGroupTargetScreenState();
}

class _SetGroupTargetScreenState
    extends ConsumerState<SetGroupTargetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetQtyCtrl = TextEditingController();
  final _minQtyCtrl = TextEditingController();
  final _tokenPctCtrl = TextEditingController(text: '10');

  String? _selectedProductId;
  int _durationHours = 48;
  bool _isLoading = false;

  static const _durations = [
    {'hours': 24, 'label': '1 Day'},
    {'hours': 48, 'label': '2 Days'},
    {'hours': 72, 'label': '3 Days'},
    {'hours': 168, 'label': '7 Days'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.preselectedProductId;
  }

  @override
  void dispose() {
    _targetQtyCtrl.dispose();
    _minQtyCtrl.dispose();
    _tokenPctCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')));
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final productsAsync = ref.read(supplierProductsProvider);
    final products = productsAsync.value ?? [];
    final product =
        products.firstWhere((p) => p.id == _selectedProductId);

    setState(() => _isLoading = true);
    try {
      final groupId = await ref
          .read(supplierProductServiceProvider)
          .createSupplierTargetGroup(
            productId: product.id,
            productName: product.name,
            productImageUrl: product.imageUrls.isNotEmpty
                ? product.imageUrls.first
                : null,
            supplierId: user.id,
            supplierName: user.businessName,
            pricingTiers: product.pricingTiers,
            minimumQuantity: int.parse(_minQtyCtrl.text.trim()),
            targetQuantity: int.parse(_targetQtyCtrl.text.trim()),
            deadline:
                DateTime.now().add(Duration(hours: _durationHours)),
            tokenPercentage:
                double.tryParse(_tokenPctCtrl.text.trim()) ?? 10.0,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Group target created! Buyers can now join.'),
              backgroundColor: AppColors.success));
        context.go('/group/$groupId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(supplierProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Set Group Target')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Set a quantity target for buyers to reach. Once the target is met, the discount is automatically unlocked.',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.info,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Product selector
            const Text('Select Product',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'No products yet. Add a product first.',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textSecondary),
                    ),
                  );
                }
                return DropdownButtonFormField<String>(
                  value: _selectedProductId,
                  decoration: const InputDecoration(
                      labelText: 'Product *',
                      prefixIcon: Icon(Icons.inventory_2_outlined)),
                  hint: const Text('Select a product'),
                  items: products
                      .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name,
                              style: const TextStyle(
                                  fontFamily: 'Poppins', fontSize: 14))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedProductId = v),
                  validator: (v) =>
                      v == null ? 'Please select a product' : null,
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 20),

            // Quantities
            const Text('Quantity Settings',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minQtyCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v == null || v.isEmpty
                        ? 'Required'
                        : int.tryParse(v) == null || int.parse(v) <= 0
                            ? 'Invalid'
                            : null,
                    decoration: const InputDecoration(
                      labelText: 'Min Quantity *',
                      hintText: 'e.g., 100',
                      prefixIcon: Icon(Icons.remove_circle_outline),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _targetQtyCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final qty = int.tryParse(v);
                      if (qty == null || qty <= 0) return 'Invalid';
                      final min = int.tryParse(_minQtyCtrl.text) ?? 0;
                      if (qty < min) return 'Must be ≥ min';
                      return null;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Target Quantity *',
                      hintText: 'e.g., 500',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _tokenPctCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final pct = double.tryParse(v);
                if (pct == null || pct < 0 || pct > 100) return 'Enter 0–100';
                return null;
              },
              decoration: const InputDecoration(
                labelText: 'Token Amount %',
                hintText: '10',
                prefixIcon: Icon(Icons.percent_outlined),
                suffixText: '%',
              ),
            ),
            const SizedBox(height: 20),

            // Duration
            const Text('Group Duration',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durations.map((d) {
                final hours = d['hours'] as int;
                final label = d['label'] as String;
                final isSelected = hours == _durationHours;
                return GestureDetector(
                  onTap: () => setState(() => _durationHours = hours),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            AppButton(
              label: 'Create Group Target',
              onPressed: _isLoading ? null : _create,
              isLoading: _isLoading,
              prefixIcon: Icons.flag_outlined,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
