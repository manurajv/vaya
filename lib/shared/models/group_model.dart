import 'package:cloud_firestore/cloud_firestore.dart';
import 'pricing_tier_model.dart';

class GroupMember {
  final String userId;
  final String businessName;
  final int quantity;
  final String paymentStatus; // pending | token_paid | full_paid
  final DateTime joinedAt;

  const GroupMember({
    required this.userId,
    required this.businessName,
    required this.quantity,
    required this.paymentStatus,
    required this.joinedAt,
  });

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      userId: map['userId'] ?? '',
      businessName: map['businessName'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      paymentStatus: map['paymentStatus'] ?? 'pending',
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'businessName': businessName,
      'quantity': quantity,
      'paymentStatus': paymentStatus,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  GroupMember copyWith({
    String? userId,
    String? businessName,
    int? quantity,
    String? paymentStatus,
    DateTime? joinedAt,
  }) {
    return GroupMember(
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      quantity: quantity ?? this.quantity,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class GroupModel {
  final String id;
  final String productId;
  final String productName;
  final String? productImageUrl;
  final String supplierId;
  final String supplierName;
  final String creatorId;
  final String creatorBusinessName;
  final String mode; // buyer_initiated | supplier_target
  final List<PricingTierModel> pricingTiers;
  final int minimumQuantity;
  final int? targetQuantity; // For supplier_target mode
  final int totalQuantity; // Real-time total
  final List<GroupMember> members;
  final String status; // active | completed | expired | cancelled | pending_approval
  final DateTime deadline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool discountApproved; // Supplier approval for buyer_initiated mode
  final String? discountApprovalNote;
  final double? tokenPercentage; // % of total as token amount
  final int? extensionCount; // How many times deadline was extended
  final String? cancellationReason;

  const GroupModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.supplierId,
    required this.supplierName,
    required this.creatorId,
    required this.creatorBusinessName,
    required this.mode,
    required this.pricingTiers,
    required this.minimumQuantity,
    this.targetQuantity,
    required this.totalQuantity,
    required this.members,
    required this.status,
    required this.deadline,
    required this.createdAt,
    required this.updatedAt,
    required this.discountApproved,
    this.discountApprovalNote,
    this.tokenPercentage,
    this.extensionCount,
    this.cancellationReason,
  });

  /// Current price per unit based on total quantity
  double get currentPricePerUnit {
    final tier = PricingEngine.getActiveTier(pricingTiers, totalQuantity);
    return tier?.pricePerUnit ?? 0;
  }

  /// Total value of the group order
  double get totalOrderValue => currentPricePerUnit * totalQuantity;

  /// Token amount (10% by default)
  double get tokenAmount {
    final pct = tokenPercentage ?? 10.0;
    return totalOrderValue * (pct / 100);
  }

  /// Whether the group has met minimum quantity
  bool get isMinimumMet => totalQuantity >= minimumQuantity;

  /// Whether the group has met the supplier target (if applicable)
  bool get isTargetMet =>
      targetQuantity == null || totalQuantity >= targetQuantity!;

  /// Whether the deadline has passed
  bool get isExpired => DateTime.now().isAfter(deadline);

  /// Time remaining until deadline
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(deadline)) return Duration.zero;
    return deadline.difference(now);
  }

  /// Progress toward minimum quantity (0.0 to 1.0)
  double get progressToMinimum {
    if (minimumQuantity == 0) return 1.0;
    return (totalQuantity / minimumQuantity).clamp(0.0, 1.0);
  }

  /// Progress toward target quantity (0.0 to 1.0)
  double get progressToTarget {
    final target = targetQuantity ?? minimumQuantity;
    if (target == 0) return 1.0;
    return (totalQuantity / target).clamp(0.0, 1.0);
  }

  /// Number of members
  int get memberCount => members.length;

  /// Check if a user is already a member
  bool isMember(String userId) =>
      members.any((m) => m.userId == userId);

  /// Get a specific member
  GroupMember? getMember(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (_) {
      return null;
    }
  }

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productImageUrl: data['productImageUrl'],
      supplierId: data['supplierId'] ?? '',
      supplierName: data['supplierName'] ?? '',
      creatorId: data['creatorId'] ?? '',
      creatorBusinessName: data['creatorBusinessName'] ?? '',
      mode: data['mode'] ?? 'buyer_initiated',
      pricingTiers: (data['pricingTiers'] as List<dynamic>? ?? [])
          .map((t) => PricingTierModel.fromMap(t as Map<String, dynamic>))
          .toList(),
      minimumQuantity: (data['minimumQuantity'] as num?)?.toInt() ?? 0,
      targetQuantity: (data['targetQuantity'] as num?)?.toInt(),
      totalQuantity: (data['totalQuantity'] as num?)?.toInt() ?? 0,
      members: (data['members'] as List<dynamic>? ?? [])
          .map((m) => GroupMember.fromMap(m as Map<String, dynamic>))
          .toList(),
      status: data['status'] ?? 'active',
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      discountApproved: data['discountApproved'] ?? false,
      discountApprovalNote: data['discountApprovalNote'],
      tokenPercentage: (data['tokenPercentage'] as num?)?.toDouble(),
      extensionCount: (data['extensionCount'] as num?)?.toInt(),
      cancellationReason: data['cancellationReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'creatorId': creatorId,
      'creatorBusinessName': creatorBusinessName,
      'mode': mode,
      'pricingTiers': pricingTiers.map((t) => t.toMap()).toList(),
      'minimumQuantity': minimumQuantity,
      'targetQuantity': targetQuantity,
      'totalQuantity': totalQuantity,
      'members': members.map((m) => m.toMap()).toList(),
      'status': status,
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'discountApproved': discountApproved,
      'discountApprovalNote': discountApprovalNote,
      'tokenPercentage': tokenPercentage,
      'extensionCount': extensionCount,
      'cancellationReason': cancellationReason,
    };
  }

  GroupModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImageUrl,
    String? supplierId,
    String? supplierName,
    String? creatorId,
    String? creatorBusinessName,
    String? mode,
    List<PricingTierModel>? pricingTiers,
    int? minimumQuantity,
    int? targetQuantity,
    int? totalQuantity,
    List<GroupMember>? members,
    String? status,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? discountApproved,
    String? discountApprovalNote,
    double? tokenPercentage,
    int? extensionCount,
    String? cancellationReason,
  }) {
    return GroupModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      creatorId: creatorId ?? this.creatorId,
      creatorBusinessName: creatorBusinessName ?? this.creatorBusinessName,
      mode: mode ?? this.mode,
      pricingTiers: pricingTiers ?? this.pricingTiers,
      minimumQuantity: minimumQuantity ?? this.minimumQuantity,
      targetQuantity: targetQuantity ?? this.targetQuantity,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      members: members ?? this.members,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      discountApproved: discountApproved ?? this.discountApproved,
      discountApprovalNote: discountApprovalNote ?? this.discountApprovalNote,
      tokenPercentage: tokenPercentage ?? this.tokenPercentage,
      extensionCount: extensionCount ?? this.extensionCount,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
