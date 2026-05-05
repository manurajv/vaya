import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/auth_provider.dart';

const List<String> _businessCategories = [
  'Agriculture & Farming',
  'Automotive Parts',
  'Building Materials',
  'Chemicals & Plastics',
  'Clothing & Textiles',
  'Electronics & Components',
  'Food & Beverages',
  'Furniture & Fixtures',
  'Hardware & Tools',
  'Healthcare & Pharma',
  'Industrial Equipment',
  'Packaging Materials',
  'Paper & Stationery',
  'Raw Materials',
  'Retail & FMCG',
  'Other',
];

const List<String> _indianStates = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
  'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
  'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
  'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  'Delhi', 'Jammu & Kashmir', 'Ladakh', 'Puducherry', 'Chandigarh',
];

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState
    extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _gstController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  String? _selectedCategory;
  String? _selectedState;
  bool _isLoading = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _gstController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a business category')),
      );
      return;
    }
    if (_selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your state')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).saveBusinessProfile(
            businessName: _businessNameController.text.trim(),
            gstNumber: _gstController.text.trim().isEmpty
                ? null
                : _gstController.text.trim(),
            businessCategory: _selectedCategory!,
            address: _addressController.text.trim(),
            city: _cityController.text.trim(),
            state_: _selectedState!,
            pincode: _pincodeController.text.trim(),
          );

      if (mounted) context.go(AppRoutes.home);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.business_outlined,
                        color: AppColors.primary, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tell us about your business to get started with group buying.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _SectionLabel(label: 'Business Information'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _businessNameController,
                validator: Validators.validateBusinessName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Business Name *',
                  hintText: 'e.g., Sharma Traders',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _gstController,
                validator: Validators.validateGstNumber,
                textCapitalization: TextCapitalization.characters,
                maxLength: 15,
                decoration: const InputDecoration(
                  labelText: 'GST Number (Optional)',
                  hintText: '22AAAAA0000A1Z5',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Business Category *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                hint: const Text('Select category'),
                items: _businessCategories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat,
                              style: const TextStyle(
                                  fontFamily: 'Poppins', fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (val) =>
                    val == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 24),

              _SectionLabel(label: 'Business Address'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                validator: Validators.validateAddress,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  hintText: 'Street, Area, Landmark',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      validator: Validators.validateCity,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        hintText: 'Mumbai',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      validator: Validators.validatePincode,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Pincode *',
                        hintText: '400001',
                        counterText: '',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedState,
                decoration: const InputDecoration(
                  labelText: 'State *',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                hint: const Text('Select state'),
                items: _indianStates
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s,
                              style: const TextStyle(
                                  fontFamily: 'Poppins', fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedState = val),
                validator: (val) =>
                    val == null ? 'Please select a state' : null,
              ),
              const SizedBox(height: 32),

              AppButton(
                label: 'Save & Continue',
                onPressed: _saveProfile,
                isLoading: _isLoading,
                suffixIcon: Icons.arrow_forward,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
