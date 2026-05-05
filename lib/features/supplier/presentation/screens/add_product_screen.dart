import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/pricing_tier_model.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/supplier_provider.dart';

const List<String> _categories = [
  'Agriculture & Farming', 'Automotive Parts', 'Building Materials',
  'Chemicals & Plastics', 'Clothing & Textiles', 'Electronics & Components',
  'Food & Beverages', 'Furniture & Fixtures', 'Hardware & Tools',
  'Healthcare & Pharma', 'Industrial Equipment', 'Packaging Materials',
  'Paper & Stationery', 'Raw Materials', 'Retail & FMCG', 'Other',
];

const List<String> _units = [
  'pieces', 'kg', 'grams', 'litres', 'ml', 'boxes', 'bags', 'bundles',
  'rolls', 'sheets', 'metres', 'pairs', 'sets', 'tons',
];

class AddProductScreen extends ConsumerStatefulWidget {
  final String? editProductId; // null = add, non-null = edit
  const AddProductScreen({super.key, this.editProductId});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _moqCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String? _category;
  String _unit = 'pieces';
  final List<File> _imageFiles = [];
  final List<PricingTierModel> _tiers = [];
  final Map<String, TextEditingController> _specKeys = {};
  final Map<String, TextEditingController> _specValues = {};
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _descCtrl, _moqCtrl, _stockCtrl, _locationCtrl]) {
      c.dispose();
    }
    for (final c in [..._specKeys.values, ..._specValues.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80, limit: 5);
    if (picked.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  void _addTier() {
    setState(() {
      _tiers.add(const PricingTierModel(minQuantity: 0, pricePerUnit: 0));
    });
  }

  void _removeTier(int index) => setState(() => _tiers.removeAt(index));

  void _addSpec() {
    final key = UniqueKey().toString();
    setState(() {
      _specKeys[key] = TextEditingController();
      _specValues[key] = TextEditingController();
    });
  }

  void _removeSpec(String key) {
    setState(() {
      _specKeys[key]?.dispose();
      _specValues[key]?.dispose();
      _specKeys.remove(key);
      _specValues.remove(key);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_tiers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one pricing tier')));
      return;
    }
    if (_tiers.any((t) => t.minQuantity <= 0 || t.pricePerUnit <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All tiers must have valid quantity and price')));
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final specs = <String, String>{};
      for (final key in _specKeys.keys) {
        final k = _specKeys[key]!.text.trim();
        final v = _specValues[key]!.text.trim();
        if (k.isNotEmpty && v.isNotEmpty) specs[k] = v;
      }

      await ref.read(supplierProductServiceProvider).addProduct(
            supplierId: user.id,
            supplierName: user.businessName,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            category: _category!,
            imageFiles: _imageFiles,
            pricingTiers: _tiers,
            minimumOrderQuantity: int.parse(_moqCtrl.text.trim()),
            unit: _unit,
            specifications: specs,
            location: _locationCtrl.text.trim().isEmpty
                ? null
                : _locationCtrl.text.trim(),
            availableStock: _stockCtrl.text.trim().isEmpty
                ? null
                : int.tryParse(_stockCtrl.text.trim()),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Product added successfully!'),
              backgroundColor: AppColors.success));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editProductId == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Images ──────────────────────────────────────────────
            _Section('Product Images'),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._imageFiles.map((f) => _ImageThumb(
                        file: f,
                        onRemove: () => setState(() => _imageFiles.remove(f)),
                      )),
                  if (_imageFiles.length < 5)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 90,
                        height: 90,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.border,
                              style: BorderStyle.solid),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.primary, size: 28),
                            SizedBox(height: 4),
                            Text('Add Photo',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Basic Info ───────────────────────────────────────────
            _Section('Basic Information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Product name is required'
                  : null,
              decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  prefixIcon: Icon(Icons.inventory_2_outlined)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Description is required'
                  : null,
              decoration: const InputDecoration(
                  labelText: 'Description *',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category_outlined)),
              hint: const Text('Select category'),
              items: _categories
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c,
                          style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 14))))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _moqCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v == null || v.isEmpty
                        ? 'Required'
                        : int.tryParse(v) == null || int.parse(v) <= 0
                            ? 'Invalid'
                            : null,
                    decoration: const InputDecoration(
                        labelText: 'Min Order Qty *',
                        prefixIcon: Icon(Icons.production_quantity_limits)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: _units
                        .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u,
                                style: const TextStyle(
                                    fontFamily: 'Poppins', fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v ?? 'pieces'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        labelText: 'Available Stock',
                        prefixIcon: Icon(Icons.warehouse_outlined)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _locationCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(Icons.location_on_outlined)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Pricing Tiers ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Section('Pricing Tiers *'),
                TextButton.icon(
                  onPressed: _addTier,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Tier',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                ),
              ],
            ),
            if (_tiers.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Add pricing tiers to define bulk discounts.\nExample: 100+ units → ₹100/unit, 500+ units → ₹80/unit',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary),
                ),
              ),
            ..._tiers.asMap().entries.map((entry) {
              final i = entry.key;
              final tier = entry.value;
              return _TierEditor(
                index: i,
                tier: tier,
                unit: _unit,
                onChanged: (updated) {
                  setState(() => _tiers[i] = updated);
                },
                onRemove: () => _removeTier(i),
              );
            }),
            const SizedBox(height: 24),

            // ── Specifications ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Section('Specifications'),
                TextButton.icon(
                  onPressed: _addSpec,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                ),
              ],
            ),
            ..._specKeys.keys.map((key) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _specKeys[key],
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                              labelText: 'Property',
                              isDense: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _specValues[key],
                          decoration: const InputDecoration(
                              labelText: 'Value',
                              isDense: true),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.error, size: 18),
                        onPressed: () => _removeSpec(key),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 32),

            AppButton(
              label: widget.editProductId == null
                  ? 'Publish Product'
                  : 'Save Changes',
              onPressed: _save,
              isLoading: _isLoading,
              prefixIcon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
      );
}

class _ImageThumb extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _ImageThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
                image: FileImage(file), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 2,
          right: 12,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: AppColors.error, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _TierEditor extends StatefulWidget {
  final int index;
  final PricingTierModel tier;
  final String unit;
  final ValueChanged<PricingTierModel> onChanged;
  final VoidCallback onRemove;

  const _TierEditor({
    required this.index,
    required this.tier,
    required this.unit,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_TierEditor> createState() => _TierEditorState();
}

class _TierEditorState extends State<_TierEditor> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
        text: widget.tier.minQuantity > 0
            ? '${widget.tier.minQuantity}'
            : '');
    _priceCtrl = TextEditingController(
        text: widget.tier.pricePerUnit > 0
            ? '${widget.tier.pricePerUnit.toStringAsFixed(0)}'
            : '');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    widget.onChanged(PricingTierModel(minQuantity: qty, pricePerUnit: price));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            child: Center(
              child: Text('T${widget.index + 1}',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _notify(),
              decoration: InputDecoration(
                  labelText: 'Min Qty (${widget.unit})',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _notify(),
              decoration: const InputDecoration(
                  labelText: '₹ per unit',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 20),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}
