import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String groupId;
  final String productId;
  final String productName;
  final String? productImageUrl;
  final String buyerId;
  final String buyerBusinessName;
  final String supplierId;
  final String supplierName;
  final int quantity;
  final double pricePerUnit;
  final double totalAmount;
  final double tokenAmount;
  final String status; // pending | confirmed | processing | shipped | delivered | cancelled
  final String paymentStatus; // pending | token_paid | full_paid | failed | refunded
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? trackingNumber;
  final String? trackingUrl;
  final DateTime? estimatedDelivery;
  final DateTime? deliveredAt;
  final String? cancellationReason;
  final String? supplierNotes;
  final String? buyerNotes;
  /// Snapshot of supplier payout details at order creation (for final payment UI).
  final String? supplierUpiId;
  final String? supplierBankAccountName;
  final String? supplierBankName;
  final String? supplierAccountNumber;
  final String? supplierIfscCode;

  const OrderModel({
    required this.id,
    required this.groupId,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.buyerId,
    required this.buyerBusinessName,
    required this.supplierId,
    required this.supplierName,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalAmount,
    required this.tokenAmount,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
    this.trackingNumber,
    this.trackingUrl,
    this.estimatedDelivery,
    this.deliveredAt,
    this.cancellationReason,
    this.supplierNotes,
    this.buyerNotes,
    this.supplierUpiId,
    this.supplierBankAccountName,
    this.supplierBankName,
    this.supplierAccountNumber,
    this.supplierIfscCode,
  });

  double get remainingAmount => totalAmount - tokenAmount;

  bool get isTokenPaid =>
      paymentStatus == 'token_paid' || paymentStatus == 'full_paid';

  bool get isFullyPaid => paymentStatus == 'full_paid';

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productImageUrl: data['productImageUrl'],
      buyerId: data['buyerId'] ?? '',
      buyerBusinessName: data['buyerBusinessName'] ?? '',
      supplierId: data['supplierId'] ?? '',
      supplierName: data['supplierName'] ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      pricePerUnit: (data['pricePerUnit'] as num?)?.toDouble() ?? 0,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      tokenAmount: (data['tokenAmount'] as num?)?.toDouble() ?? 0,
      status: data['status'] ?? 'pending',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      trackingNumber: data['trackingNumber'],
      trackingUrl: data['trackingUrl'],
      estimatedDelivery:
          (data['estimatedDelivery'] as Timestamp?)?.toDate(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      cancellationReason: data['cancellationReason'],
      supplierNotes: data['supplierNotes'],
      buyerNotes: data['buyerNotes'],
      supplierUpiId: data['supplierUpiId'],
      supplierBankAccountName: data['supplierBankAccountName'],
      supplierBankName: data['supplierBankName'],
      supplierAccountNumber: data['supplierAccountNumber'],
      supplierIfscCode: data['supplierIfscCode'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'buyerId': buyerId,
      'buyerBusinessName': buyerBusinessName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'quantity': quantity,
      'pricePerUnit': pricePerUnit,
      'totalAmount': totalAmount,
      'tokenAmount': tokenAmount,
      'status': status,
      'paymentStatus': paymentStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'trackingNumber': trackingNumber,
      'trackingUrl': trackingUrl,
      'estimatedDelivery': estimatedDelivery != null
          ? Timestamp.fromDate(estimatedDelivery!)
          : null,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'cancellationReason': cancellationReason,
      'supplierNotes': supplierNotes,
      'buyerNotes': buyerNotes,
      'supplierUpiId': supplierUpiId,
      'supplierBankAccountName': supplierBankAccountName,
      'supplierBankName': supplierBankName,
      'supplierAccountNumber': supplierAccountNumber,
      'supplierIfscCode': supplierIfscCode,
    };
  }

  OrderModel copyWith({
    String? id,
    String? groupId,
    String? productId,
    String? productName,
    String? productImageUrl,
    String? buyerId,
    String? buyerBusinessName,
    String? supplierId,
    String? supplierName,
    int? quantity,
    double? pricePerUnit,
    double? totalAmount,
    double? tokenAmount,
    String? status,
    String? paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? trackingNumber,
    String? trackingUrl,
    DateTime? estimatedDelivery,
    DateTime? deliveredAt,
    String? cancellationReason,
    String? supplierNotes,
    String? buyerNotes,
    String? supplierUpiId,
    String? supplierBankAccountName,
    String? supplierBankName,
    String? supplierAccountNumber,
    String? supplierIfscCode,
  }) {
    return OrderModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      buyerId: buyerId ?? this.buyerId,
      buyerBusinessName: buyerBusinessName ?? this.buyerBusinessName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalAmount: totalAmount ?? this.totalAmount,
      tokenAmount: tokenAmount ?? this.tokenAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      supplierNotes: supplierNotes ?? this.supplierNotes,
      buyerNotes: buyerNotes ?? this.buyerNotes,
      supplierUpiId: supplierUpiId ?? this.supplierUpiId,
      supplierBankAccountName:
          supplierBankAccountName ?? this.supplierBankAccountName,
      supplierBankName: supplierBankName ?? this.supplierBankName,
      supplierAccountNumber:
          supplierAccountNumber ?? this.supplierAccountNumber,
      supplierIfscCode: supplierIfscCode ?? this.supplierIfscCode,
    );
  }
}
