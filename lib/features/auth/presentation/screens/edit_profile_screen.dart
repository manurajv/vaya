import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/auth_provider.dart';

const List<String> _businessCategories = [
  'Agriculture & Farming', 'Automotive Parts', 'Building Materials',
  'Chemicals & Plastics', 'Clothing & Textiles', 'Electronics & Components',
  'Food & Beverages', 'Furniture & Fixtures', 'Hardware & Tools',
  'Healthcare & Pharma', 'Industrial Equipment', 'Packaging Materials',
  'Paper & Stationery', 'Raw Materials', 'Retail & FMCG', 'Other',
];

const List<String> _indianStates = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
  'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
  'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim',
  'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand',
  'West Bengal', 'Delhi', 'Jammu & Kashmir', 'Ladakh', 'Puducherry',
  'Chandigarh',
];

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessNameCtrl;
  late final TextEditingController _gstCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _pincodeCtrl;

  String? _selectedCategory;
  String? _selectedState;
  String? _localImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _businessNameCtrl =
        TextEditingController(text: user?.businessName ?? '');
    _gstCtrl = TextEditingController(text: user?.gstNumber ?? '');
    _addressCtrl = TextEditingController(text: user?.address ?? '');
    _cityCtrl = TextEditingController(text: user?.city ?? '');
    _pincodeCtrl = TextEditingController(text: user?.pincode ?? '');
    _selectedCategory = user?.businessCategory;
    _selectedState = user?.state;
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _gstCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _localImagePath = picked.path);
  }

  Future<String?> _uploadProfileImage(String uid) async {
    if (_localImagePath == null) return null;
    final file = File(_localImagePath!);
    final ref = FirebaseStorage.instance
        .ref()
        .child(AppConstants.profileImagesPath)
        .child('$uid.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select category and state')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final imageUrl = await _uploadProfileImage(uid);

      final updates = <String, dynamic>{
        'businessName': _businessNameCtrl.text.trim(),
        'gstNumber': _gstCtrl.text.trim().isEmpty
            ? null
            : _gstCtrl.text.trim(),
        'businessCategory': _selectedCategory,
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _selectedState,
        'pincode': _pincodeCtrl.text.trim(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      if (imageUrl != null) updates['profileImageUrl'] = imageUrl;

      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(updates);

      // Refresh auth state
      ref.invalidate(authProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar picker
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.surfaceVariant,
                    backgroundImage: _localImagePath != null
                        ? FileImage(File(_localImagePath!))
                        : (user?.profileImageUrl != null
                            ? NetworkImage(user!.profileImageUrl!)
                                as ImageProvider
                            : null),
                    child: (_localImagePath == null &&
                            user?.profileImageUrl == null)
                        ? Text(
                            user?.businessName.isNotEmpty == true
                                ? user!.businessName[0].toUpperCase()
                                : 'B',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _Label('Business Information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _businessNameCtrl,
              validator: Validators.validateBusinessName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Business Name *',
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
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Business Category *',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              hint: const Text('Select category'),
              items: _businessCategories
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c,
                          style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 14))))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedCategory = v),
              validator: (v) =>
                  v == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 24),

            _Label('Business Address'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              validator: Validators.validateAddress,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Address *',
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
                    decoration:
                        const InputDecoration(labelText: 'City *'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _pincodeCtrl,
                    validator: Validators.validatePincode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: const InputDecoration(
                        labelText: 'Pincode *', counterText: ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
                              fontFamily: 'Poppins', fontSize: 14))))
                  .toList(),
              onChanged: (v) => setState(() => _selectedState = v),
              validator: (v) =>
                  v == null ? 'Please select a state' : null,
            ),
            const SizedBox(height: 32),

            AppButton(
              label: 'Save Changes',
              onPressed: _save,
              isLoading: _isLoading,
              prefixIcon: Icons.check,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );
}
