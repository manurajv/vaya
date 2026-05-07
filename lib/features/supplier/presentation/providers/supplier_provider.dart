import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/models/pricing_tier_model.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/group_model.dart';

// ── Supplier's own products ──────────────────────────────────────────────────
final supplierProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(AppConstants.productsCollection)
      .where('supplierId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => ProductModel.fromFirestore(d)).toList());
});

// ── Orders for this supplier ─────────────────────────────────────────────────
final supplierOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(AppConstants.ordersCollection)
      .where('supplierId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => OrderModel.fromFirestore(d)).toList());
});

// ── Groups pending discount approval ────────────────────────────────────────
final pendingApprovalGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(AppConstants.groupsCollection)
      .where('supplierId', isEqualTo: uid)
      .where('status', isEqualTo: AppConstants.groupStatusPendingApproval)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => GroupModel.fromFirestore(d)).toList());
});

// ── All active groups for this supplier ─────────────────────────────────────
final supplierActiveGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(AppConstants.groupsCollection)
      .where('supplierId', isEqualTo: uid)
      .where('status', isEqualTo: AppConstants.groupStatusActive)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => GroupModel.fromFirestore(d)).toList());
});

// ── Supplier stats ───────────────────────────────────────────────────────────
class SupplierStats {
  final int totalProducts;
  final int activeGroups;
  final int pendingApprovals;
  final int totalOrders;
  final double totalRevenue;

  const SupplierStats({
    required this.totalProducts,
    required this.activeGroups,
    required this.pendingApprovals,
    required this.totalOrders,
    required this.totalRevenue,
  });
}

final supplierStatsProvider = Provider<SupplierStats>((ref) {
  final products = ref.watch(supplierProductsProvider).value ?? [];
  final groups = ref.watch(supplierActiveGroupsProvider).value ?? [];
  final pending = ref.watch(pendingApprovalGroupsProvider).value ?? [];
  final orders = ref.watch(supplierOrdersProvider).value ?? [];

  final revenue = orders
      .where((o) => o.paymentStatus == AppConstants.paymentStatusFullPaid)
      .fold<double>(0, (sum, o) => sum + o.totalAmount);

  return SupplierStats(
    totalProducts: products.length,
    activeGroups: groups.length,
    pendingApprovals: pending.length,
    totalOrders: orders.length,
    totalRevenue: revenue,
  );
});

// ── Product service ──────────────────────────────────────────────────────────
class SupplierProductService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<String> addProduct({
    required String supplierId,
    required String supplierName,
    required String name,
    required String description,
    required String category,
    required List<File> imageFiles,
    required List<PricingTierModel> pricingTiers,
    required int minimumOrderQuantity,
    required String unit,
    required Map<String, String> specifications,
    double? basePrice,
    String? location,
    int? availableStock,
  }) async {
    // Upload images
    final imageUrls = <String>[];
    for (final file in imageFiles) {
      final fileName = '${const Uuid().v4()}.jpg';
      final ref = _storage
          .ref()
          .child(AppConstants.productImagesPath)
          .child(supplierId)
          .child(fileName);
      await ref.putFile(file);
      imageUrls.add(await ref.getDownloadURL());
    }

    final now = DateTime.now();
    final product = ProductModel(
      id: '',
      supplierId: supplierId,
      supplierName: supplierName,
      name: name,
      description: description,
      category: category,
      imageUrls: imageUrls,
      pricingTiers: pricingTiers,
      minimumOrderQuantity: minimumOrderQuantity,
      unit: unit,
      specifications: specifications,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      basePrice: basePrice,
      location: location,
      availableStock: availableStock,
    );

    final docRef = await _db
        .collection(AppConstants.productsCollection)
        .add(product.toFirestore());
    return docRef.id;
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    await _db
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .update({...updates, 'updatedAt': Timestamp.fromDate(DateTime.now())});
  }

  Future<void> toggleProductActive(String productId, bool isActive) async {
    await updateProduct(productId, {'isActive': isActive});
  }

  Future<void> deleteProduct(String productId) async {
    await _db
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .delete();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update({
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> approveDiscount(
      String groupId, bool approved, String note) async {
    final docRef = _db.collection(AppConstants.groupsCollection).doc(groupId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
      if (!snap.exists) throw Exception('Group not found');

      final group = GroupModel.fromFirestore(snap);

      if (!approved) {
        transaction.update(docRef, {
          'discountApproved': false,
          'discountApprovalNote': note,
          'status': AppConstants.groupStatusCancelled,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
        return;
      }

      final after = group.copyWith(
        discountApproved: true,
        discountApprovalNote: note,
      );
      final newStatus = after.isFulfillmentComplete
          ? AppConstants.groupStatusCompleted
          : AppConstants.groupStatusActive;

      transaction.update(docRef, {
        'discountApproved': true,
        'discountApprovalNote': note,
        'status': newStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  /// Create a supplier-target group for a product
  Future<String> createSupplierTargetGroup({
    required String productId,
    required String productName,
    String? productImageUrl,
    required String supplierId,
    required String supplierName,
    required List<PricingTierModel> pricingTiers,
    required int minimumQuantity,
    required int targetQuantity,
    required DateTime deadline,
    double tokenPercentage = 10.0,
  }) async {
    final now = DateTime.now();
    final data = {
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'creatorId': supplierId,
      'creatorBusinessName': supplierName,
      'mode': AppConstants.groupModeSupplierTarget,
      'pricingTiers': pricingTiers.map((t) => t.toMap()).toList(),
      'minimumQuantity': minimumQuantity,
      'targetQuantity': targetQuantity,
      'totalQuantity': 0,
      'members': [],
      'status': AppConstants.groupStatusActive,
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'discountApproved': true,
      'tokenPercentage': tokenPercentage,
      'extensionCount': 0,
    };
    final ref = await _db.collection(AppConstants.groupsCollection).add(data);
    return ref.id;
  }
}

final supplierProductServiceProvider =
    Provider<SupplierProductService>((ref) => SupplierProductService());
