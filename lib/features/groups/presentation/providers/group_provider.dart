import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/group_model.dart';
import '../../../../shared/models/pricing_tier_model.dart';

/// Result of increasing a member's quantity in a group (may be capped by target).
class MemberQuantityUpdateResult {
  final int quantityAdded;
  final int newGroupTotal;
  final bool wasCapped;

  const MemberQuantityUpdateResult({
    required this.quantityAdded,
    required this.newGroupTotal,
    required this.wasCapped,
  });
}

String _statusAfterQuantityChange(GroupModel before, GroupModel after) {
  if (after.isFulfillmentComplete) {
    return AppConstants.groupStatusCompleted;
  }
  if (before.status == AppConstants.groupStatusCompleted) {
    return AppConstants.groupStatusActive;
  }
  if (before.status == AppConstants.groupStatusPendingApproval) {
    return AppConstants.groupStatusPendingApproval;
  }
  return AppConstants.groupStatusActive;
}

// All open groups forming deals (active + awaiting supplier discount sign-off)
final activeGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(AppConstants.groupsCollection)
      .where('status', whereIn: [
        AppConstants.groupStatusActive,
        AppConstants.groupStatusPendingApproval,
      ])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => GroupModel.fromFirestore(doc)).toList());
});

// Groups for a specific product
final groupsByProductProvider =
    StreamProvider.family<List<GroupModel>, String>((ref, productId) {
  return FirebaseFirestore.instance
      .collection(AppConstants.groupsCollection)
      .where('productId', isEqualTo: productId)
      .where('status', whereIn: [
        AppConstants.groupStatusActive,
        AppConstants.groupStatusPendingApproval,
      ])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => GroupModel.fromFirestore(doc)).toList());
});

// Current user's groups — uses a flat memberIds array for reliable arrayContains
final myGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(AppConstants.groupsCollection)
      .where('memberIds', arrayContains: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => GroupModel.fromFirestore(doc)).toList());
});

// Single group by ID
final groupByIdProvider =
    StreamProvider.family<GroupModel?, String>((ref, groupId) {
  return FirebaseFirestore.instance
      .collection(AppConstants.groupsCollection)
      .doc(groupId)
      .snapshots()
      .map((doc) => doc.exists ? GroupModel.fromFirestore(doc) : null);
});

// Group operations
class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createGroup({
    required String productId,
    required String productName,
    String? productImageUrl,
    required String supplierId,
    required String supplierName,
    required String creatorId,
    required String creatorBusinessName,
    required String mode,
    required List<PricingTierModel> pricingTiers,
    required int minimumQuantity,
    int? targetQuantity,
    required int creatorQuantity,
    required DateTime deadline,
    double tokenPercentage = 10.0,
  }) async {
    final now = DateTime.now();

    final member = GroupMember(
      userId: creatorId,
      businessName: creatorBusinessName,
      quantity: creatorQuantity,
      paymentStatus: AppConstants.paymentStatusPending,
      joinedAt: now,
    );

    final group = GroupModel(
      id: '',
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      supplierId: supplierId,
      supplierName: supplierName,
      creatorId: creatorId,
      creatorBusinessName: creatorBusinessName,
      mode: mode,
      pricingTiers: pricingTiers,
      minimumQuantity: minimumQuantity,
      targetQuantity: targetQuantity,
      totalQuantity: creatorQuantity,
      members: [member],
      status: AppConstants.groupStatusActive,
      deadline: deadline,
      createdAt: now,
      updatedAt: now,
      discountApproved: mode == AppConstants.groupModeSupplierTarget,
      tokenPercentage: tokenPercentage,
      extensionCount: 0,
    );

    final docRef = await _firestore
        .collection(AppConstants.groupsCollection)
        .add(group.toFirestore());

    return docRef.id;
  }

  Future<void> joinGroup({
    required String groupId,
    required String userId,
    required String businessName,
    required int quantity,
  }) async {
    final groupRef = _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId);

    await _firestore.runTransaction((transaction) async {
      final groupDoc = await transaction.get(groupRef);
      if (!groupDoc.exists) throw Exception('Group not found');

      final group = GroupModel.fromFirestore(groupDoc);

      if (group.status != AppConstants.groupStatusActive &&
          group.status != AppConstants.groupStatusPendingApproval) {
        throw Exception('This group is no longer open for joining');
      }
      if (group.isExpired) {
        throw Exception('This group has expired');
      }
      if (group.isMember(userId)) {
        throw Exception('You are already a member of this group');
      }

      final target = group.targetQuantity;
      if (target != null) {
        final remaining = target - group.totalQuantity;
        if (remaining <= 0) {
          throw Exception(
            'This group is full — the target quantity has been reached',
          );
        }
        if (quantity > remaining) {
          throw Exception(
            'Only $remaining units left in this group. Reduce your quantity or try another group.',
          );
        }
      }

      final newMember = GroupMember(
        userId: userId,
        businessName: businessName,
        quantity: quantity,
        paymentStatus: AppConstants.paymentStatusPending,
        joinedAt: DateTime.now(),
      );

      final updatedMembers = [...group.members, newMember];
      final newTotal = group.totalQuantity + quantity;

      final nextSnapshot = group.copyWith(
        members: updatedMembers,
        totalQuantity: newTotal,
      );
      final newStatus = _statusAfterQuantityChange(group, nextSnapshot);

      transaction.update(groupRef, {
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'memberIds': updatedMembers.map((m) => m.userId).toList(),
        'totalQuantity': newTotal,
        'status': newStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  Future<void> requestDiscountApproval(String groupId) async {
    final groupRef =
        _firestore.collection(AppConstants.groupsCollection).doc(groupId);

    await _firestore.runTransaction((transaction) async {
      final groupDoc = await transaction.get(groupRef);
      if (!groupDoc.exists) throw Exception('Group not found');

      final group = GroupModel.fromFirestore(groupDoc);
      if (group.mode != AppConstants.groupModeBuyerInitiated) {
        throw Exception(
          'Only buyer-initiated groups use supplier discount approval',
        );
      }
      if (!group.isMinimumMet) {
        throw Exception(
          'Reach at least ${group.minimumQuantity} pooled units before requesting supplier approval',
        );
      }
      if (group.discountApproved) {
        throw Exception('This discount is already approved');
      }
      if (group.status != AppConstants.groupStatusActive) {
        throw Exception('Cannot request approval in the current group state');
      }

      transaction.update(groupRef, {
        'status': AppConstants.groupStatusPendingApproval,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  Future<void> extendDeadline(String groupId, int additionalHours) async {
    final groupDoc = await _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .get();

    if (!groupDoc.exists) throw Exception('Group not found');
    final group = GroupModel.fromFirestore(groupDoc);

    final newDeadline =
        group.deadline.add(Duration(hours: additionalHours));
    final newExtensionCount = (group.extensionCount ?? 0) + 1;

    await _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId)
        .update({
      'deadline': Timestamp.fromDate(newDeadline),
      'extensionCount': newExtensionCount,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> updateMemberPaymentStatus(
    String groupId,
    String userId,
    String paymentStatus,
  ) async {
    final groupRef = _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId);

    await _firestore.runTransaction((transaction) async {
      final groupDoc = await transaction.get(groupRef);
      if (!groupDoc.exists) throw Exception('Group not found');

      final group = GroupModel.fromFirestore(groupDoc);
      final updatedMembers = group.members.map((m) {
        if (m.userId == userId) {
          return m.copyWith(paymentStatus: paymentStatus);
        }
        return m;
      }).toList();

      transaction.update(groupRef, {
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  /// Check and mark expired groups — call periodically from the app
  Future<void> checkAndExpireGroups() async {
    final now = Timestamp.fromDate(DateTime.now());
    for (final status in [
      AppConstants.groupStatusActive,
      AppConstants.groupStatusPendingApproval,
    ]) {
      final snapshot = await _firestore
          .collection(AppConstants.groupsCollection)
          .where('status', isEqualTo: status)
          .where('deadline', isLessThan: now)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({
          'status': AppConstants.groupStatusExpired,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    }
  }

  /// Buyer increases their quantity. Optional cap when [targetQuantity] is set.
  /// Returns how much was actually added (never rolls back a successful cap).
  Future<MemberQuantityUpdateResult> updateMemberQuantity({
    required String groupId,
    required String userId,
    required int additionalQuantity,
  }) async {
    if (additionalQuantity <= 0) {
      throw Exception('Additional quantity must be greater than 0');
    }

    final groupRef = _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId);

    MemberQuantityUpdateResult? result;

    await _firestore.runTransaction((transaction) async {
      final groupDoc = await transaction.get(groupRef);
      if (!groupDoc.exists) throw Exception('Group not found');

      final group = GroupModel.fromFirestore(groupDoc);

      if (group.status != AppConstants.groupStatusActive &&
          group.status != AppConstants.groupStatusPendingApproval) {
        throw Exception(
            'Quantity can only be changed while the group is open');
      }
      if (group.isExpired) {
        throw Exception('This group has expired');
      }

      final member = group.getMember(userId);
      if (member == null) {
        throw Exception('You are not a member of this group');
      }

      if (member.paymentStatus != AppConstants.paymentStatusPending) {
        throw Exception('Quantity cannot be changed after payment is made');
      }

      final target = group.targetQuantity;
      var allowedAdditional = additionalQuantity;
      if (target != null) {
        final remainingCapacity = target - group.totalQuantity;
        if (remainingCapacity <= 0) {
          throw Exception(
            'Group has already reached its target quantity of $target units',
          );
        }
        if (additionalQuantity > remainingCapacity) {
          allowedAdditional = remainingCapacity;
        }
      }

      final updatedMembers = group.members.map((m) {
        if (m.userId == userId) {
          return m.copyWith(quantity: m.quantity + allowedAdditional);
        }
        return m;
      }).toList();

      final newTotal = group.totalQuantity + allowedAdditional;

      final nextSnapshot = group.copyWith(
        members: updatedMembers,
        totalQuantity: newTotal,
      );
      final newStatus = _statusAfterQuantityChange(group, nextSnapshot);

      transaction.update(groupRef, {
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'totalQuantity': newTotal,
        'status': newStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      result = MemberQuantityUpdateResult(
        quantityAdded: allowedAdditional,
        newGroupTotal: newTotal,
        wasCapped: allowedAdditional < additionalQuantity,
      );
    });

    return result!;
  }

  /// Remove a member who failed to pay and redistribute their quantity
  Future<void> removeMemberForNonPayment(
    String groupId,
    String userId,
    String reason,
  ) async {
    final groupRef = _firestore
        .collection(AppConstants.groupsCollection)
        .doc(groupId);

    await _firestore.runTransaction((transaction) async {
      final groupDoc = await transaction.get(groupRef);
      if (!groupDoc.exists) throw Exception('Group not found');

      final group = GroupModel.fromFirestore(groupDoc);
      final member = group.getMember(userId);
      if (member == null) return;

      final updatedMembers =
          group.members.where((m) => m.userId != userId).toList();
      final newTotal = group.totalQuantity - member.quantity;

      final nextSnapshot = group.copyWith(
        members: updatedMembers,
        totalQuantity: newTotal,
      );
      final newStatus = _statusAfterQuantityChange(group, nextSnapshot);

      transaction.update(groupRef, {
        'members': updatedMembers.map((m) => m.toMap()).toList(),
        'memberIds': updatedMembers.map((m) => m.userId).toList(),
        'totalQuantity': newTotal,
        'status': newStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'cancellationReason': reason,
      });
    });
  }
}

final groupServiceProvider = Provider<GroupService>((ref) => GroupService());
