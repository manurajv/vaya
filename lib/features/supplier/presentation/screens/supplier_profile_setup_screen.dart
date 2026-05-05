import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const List<String> _categories = [
  'Agriculture & Farming', 'Automotive Parts', 'Building Materials',
  'Chemicals & Plastics', 'Clothing & Textiles', 'Electronics & Components',
  'Food & Beverages', 'Furniture & Fixtures', 'Hardware & Tools',
  'Healthcare & Pharma', 'Industrial Equipment', 'Packaging Materials',
  'Paper & Stationery', 'Raw Materials', 'Retail & FMCG', 'Other',
];

const List<String> _states = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
  'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
  'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim',
  'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand',
  'West Bengal', 'Delhi', 'Jammu & Kashmir', 'Ladakh', 'Puducherry',
  'Chandigarh',
];

class SupplierProfileSetupScreen extends ConsumerStatefulWidget {
  const SupplierProfileSetupScreen({super.key});

  @override
  ConsumerState<SupplierProfileSetupScreen> createState() =>
      _SupplierProfileSetupScreenState();
}

class _SupplierProfileSetupScreenState
    extends ConsumerState<SupplierProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0; // 0 = business info, 1 = payment details

  // Step 1 controllers
  final _nameCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  String? _category;
  String? _state;

  // Step 2 controllers
  final _upiCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _gstCtrl, _addressCtrl, _cityCtrl, _pincodeCtrl,
      _upiCtrl, _bankNameCtrl, _accountNameCtrl, _accountNumberCtrl, _ifscCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).saveBusinessProfile(
            businessName: _nameCtrl.text.trim(),
            gstNumber: _gstCtrl.text.trim().isEmpty
                ? null
                : _gstCtrl.text.trim(),
            businessCategory: _category!,
            address: _addressCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            state_: _state!,
            pincode: _pincodeCtrl.text.trim(),
            userType: AppConstants.userTypeSupplier,
            upiId: _upiCtrl.text.trim().isEmpty ? null : _upiCtrl.text.trim(),
            bankAccountName: _accountNameCtrl.text.trim().isEmpty
                ? null
                : _accountNameCtrl.text.trim(),
            bankName: _bankNameCtrl.text.trim().isEmpty
                ? null
                : _bankNameCtrl.text.trim(),
            bankAccountNumber: _accountNumberCtrl.text.trim().isEmpty
                ? null
                : _accountNumberCtrl.text.trim(),
            bankIfscCode: _ifscCtrl.text.trim().isEmpty
                ? null
                : _ifscCtrl.text.trim(),
          );
      if (mounted) context.go(AppRoutes.supplierDashboard);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Setup'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Step indicator
          Container(
            color: AppColors.surface,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                _StepDot(number: 1, label: 'Business', isActive: _step == 0, isDone: _step > 0),
                Expanded(child: Container(height: 2, color: _step > 0 ? AppColors.primary : AppColors.border)),
                _StepDot(number: 2, label: 'Payment', isActive: _step == 1, isDone: false),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: _step == 0
                  ? _buildStep1()
                  : _buildStep2(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.store_outlined, color: AppColors.primary, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tell us about your business so buyers can find and trust you.',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _nameCtrl,
          validator: Validators.validateBusinessName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Business / Company Name *',
            prefixIcon: Icon(Icons.store_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _gstCtrl,
          validator: Validators.validateGstNumber,
          textCapitalization: TextCapitalization.characters,
          maxLength: 15,
          decoration: const InputDecoration(
            labelText: 'GST Number (Optional)',
            prefixIcon: Icon(Icons.receipt_long_outlined),
            counterText: '',
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _category,
          decoration: const InputDecoration(
            labelText: 'Product Category *',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          hint: const Text('Select your main category'),
          items: _categories
              .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14))))
              .toList(),
          onChanged: (v) => setState(() => _category = v),
          validator: (v) => v == null ? 'Please select a category' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _addressCtrl,
          validator: Validators.validateAddress,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Warehouse / Office Address *',
            prefixIcon: Icon(Icons.location_on_outlined),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityCtrl,
                validator: Validators.validateCity,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'City *'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _pincodeCtrl,
                validator: Validators.validatePincode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Pincode *', counterText: ''),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _state,
          decoration: const InputDecoration(
            labelText: 'State *',
            prefixIcon: Icon(Icons.map_outlined),
          ),
          hint: const Text('Select state'),
          items: _states
              .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14))))
              .toList(),
          onChanged: (v) => setState(() => _state = v),
          validator: (v) => v == null ? 'Please select a state' : null,
        ),
        const SizedBox(height: 28),
        AppButton(
          label: 'Next: Payment Details',
          onPressed: () {
            if (_formKey.currentState!.validate() &&
                _category != null &&
                _state != null) {
              setState(() => _step = 1);
            } else if (_category == null || _state == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all required fields')),
              );
            }
          },
          suffixIcon: Icons.arrow_forward,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStep2() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
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
                  'Buyers will pay the final amount directly to you using these details. Token amount goes to VAYA.',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.info, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _upiCtrl,
          decoration: const InputDecoration(
            labelText: 'UPI ID',
            hintText: 'yourname@upi',
            prefixIcon: Icon(Icons.qr_code_outlined),
          ),
        ),
        const SizedBox(height: 14),
        const _Divider(label: 'OR Bank Transfer'),
        const SizedBox(height: 14),
        TextFormField(
          controller: _accountNameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Account Holder Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _bankNameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Bank Name',
            prefixIcon: Icon(Icons.account_balance_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _accountNumberCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Account Number',
            prefixIcon: Icon(Icons.credit_card_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _ifscCtrl,
          textCapitalization: TextCapitalization.characters,
          maxLength: 11,
          decoration: const InputDecoration(
            labelText: 'IFSC Code',
            prefixIcon: Icon(Icons.code_outlined),
            counterText: '',
          ),
        ),
        const SizedBox(height: 28),
        AppButton(
          label: 'Complete Setup',
          onPressed: _save,
          isLoading: _isLoading,
          prefixIcon: Icons.check_circle_outline,
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Back',
          variant: AppButtonVariant.ghost,
          onPressed: () => setState(() => _step = 0),
          prefixIcon: Icons.arrow_back,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepDot({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = isDone
        ? AppColors.success
        : isActive
            ? AppColors.primary
            : AppColors.border;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive || isDone ? Colors.white : AppColors.textHint,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppColors.primary : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
