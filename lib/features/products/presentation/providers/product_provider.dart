import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/product_model.dart';

final productsProvider = StreamProvider<List<ProductModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.productsCollection)
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => ProductModel.fromFirestore(doc)).toList());
});

final productByIdProvider =
    StreamProvider.family<ProductModel?, String>((ref, productId) {
  return FirebaseFirestore.instance
      .collection(AppConstants.productsCollection)
      .doc(productId)
      .snapshots()
      .map((doc) => doc.exists ? ProductModel.fromFirestore(doc) : null);
});

final productsByCategoryProvider =
    StreamProvider.family<List<ProductModel>, String>((ref, category) {
  return FirebaseFirestore.instance
      .collection(AppConstants.productsCollection)
      .where('isActive', isEqualTo: true)
      .where('category', isEqualTo: category)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => ProductModel.fromFirestore(doc)).toList());
});
