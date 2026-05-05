import 'package:cloud_firestore/cloud_firestore.dart';
import 'pricing_tier_model.dart';

class ProductModel {
  final String id;
  final String supplierId;
  final String supplierName;
  final String name;
  final String description;
  final String category;
  final List<String> imageUrls;
  final List<PricingTierModel> pricingTiers;
  final int minimumOrderQuantity;
  final String unit; // kg, pieces, boxes, etc.
  final Map<String, String> specifications;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? basePrice; // Price before any group discount
  final String? location; // Supplier location
  final int? availableStock;

  const ProductModel({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrls,
    required this.pricingTiers,
    required this.minimumOrderQuantity,
    required this.unit,
    required this.specifications,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.basePrice,
    this.location,
    this.availableStock,
  });

  /// The lowest price available (best tier)
  double get lowestPrice {
    if (pricingTiers.isEmpty) return basePrice ?? 0;
    return pricingTiers
        .map((t) => t.pricePerUnit)
        .reduce((a, b) => a < b ? a : b);
  }

  /// The highest price (base/entry tier)
  double get highestPrice {
    if (pricingTiers.isEmpty) return basePrice ?? 0;
    return pricingTiers
        .map((t) => t.pricePerUnit)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Sorted tiers by minQuantity ascending
  List<PricingTierModel> get sortedTiers {
    final sorted = List<PricingTierModel>.from(pricingTiers);
    sorted.sort((a, b) => a.minQuantity.compareTo(b.minQuantity));
    return sorted;
  }

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      supplierId: data['supplierId'] ?? '',
      supplierName: data['supplierName'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      pricingTiers: (data['pricingTiers'] as List<dynamic>? ?? [])
          .map((t) => PricingTierModel.fromMap(t as Map<String, dynamic>))
          .toList(),
      minimumOrderQuantity:
          (data['minimumOrderQuantity'] as num?)?.toInt() ?? 1,
      unit: data['unit'] ?? 'pieces',
      specifications:
          Map<String, String>.from(data['specifications'] ?? {}),
      isActive: data['isActive'] ?? true,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      basePrice: (data['basePrice'] as num?)?.toDouble(),
      location: data['location'],
      availableStock: (data['availableStock'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'name': name,
      'description': description,
      'category': category,
      'imageUrls': imageUrls,
      'pricingTiers': pricingTiers.map((t) => t.toMap()).toList(),
      'minimumOrderQuantity': minimumOrderQuantity,
      'unit': unit,
      'specifications': specifications,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'basePrice': basePrice,
      'location': location,
      'availableStock': availableStock,
    };
  }

  ProductModel copyWith({
    String? id,
    String? supplierId,
    String? supplierName,
    String? name,
    String? description,
    String? category,
    List<String>? imageUrls,
    List<PricingTierModel>? pricingTiers,
    int? minimumOrderQuantity,
    String? unit,
    Map<String, String>? specifications,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? basePrice,
    String? location,
    int? availableStock,
  }) {
    return ProductModel(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      pricingTiers: pricingTiers ?? this.pricingTiers,
      minimumOrderQuantity: minimumOrderQuantity ?? this.minimumOrderQuantity,
      unit: unit ?? this.unit,
      specifications: specifications ?? this.specifications,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      basePrice: basePrice ?? this.basePrice,
      location: location ?? this.location,
      availableStock: availableStock ?? this.availableStock,
    );
  }
}
