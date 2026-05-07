import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/order_model.dart';

final myOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(AppConstants.ordersCollection)
      .where('buyerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
});

final orderByIdProvider =
    StreamProvider.family<OrderModel?, String>((ref, orderId) {
  return FirebaseFirestore.instance
      .collection(AppConstants.ordersCollection)
      .doc(orderId)
      .snapshots()
      .map((doc) => doc.exists ? OrderModel.fromFirestore(doc) : null);
});

/// The current user's order for a completed group (one doc per member after group completes).
final orderForGroupBuyerProvider =
    StreamProvider.family<OrderModel?, String>((ref, groupId) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection(AppConstants.ordersCollection)
      .where('groupId', isEqualTo: groupId)
      .where('buyerId', isEqualTo: uid)
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isEmpty
          ? null
          : OrderModel.fromFirestore(snap.docs.first));
});
