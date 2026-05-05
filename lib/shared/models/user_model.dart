import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String phoneNumber;
  final String businessName;
  final String? gstNumber;
  final String businessCategory;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String? profileImageUrl;
  final String userType; // buyer | supplier
  final bool isProfileComplete;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;
  // Supplier-specific
  final String? upiId;
  final String? bankAccountName;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankIfscCode;
  final bool isVerifiedSupplier;

  const UserModel({
    required this.id,
    required this.phoneNumber,
    required this.businessName,
    this.gstNumber,
    required this.businessCategory,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.profileImageUrl,
    required this.userType,
    required this.isProfileComplete,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
    this.upiId,
    this.bankAccountName,
    this.bankName,
    this.bankAccountNumber,
    this.bankIfscCode,
    this.isVerifiedSupplier = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      phoneNumber: data['phoneNumber'] ?? '',
      businessName: data['businessName'] ?? '',
      gstNumber: data['gstNumber'],
      businessCategory: data['businessCategory'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      pincode: data['pincode'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      userType: data['userType'] ?? 'buyer',
      isProfileComplete: data['isProfileComplete'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fcmToken: data['fcmToken'],
      upiId: data['upiId'],
      bankAccountName: data['bankAccountName'],
      bankName: data['bankName'],
      bankAccountNumber: data['bankAccountNumber'],
      bankIfscCode: data['bankIfscCode'],
      isVerifiedSupplier: data['isVerifiedSupplier'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'phoneNumber': phoneNumber,
      'businessName': businessName,
      'gstNumber': gstNumber,
      'businessCategory': businessCategory,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'profileImageUrl': profileImageUrl,
      'userType': userType,
      'isProfileComplete': isProfileComplete,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'fcmToken': fcmToken,
      'upiId': upiId,
      'bankAccountName': bankAccountName,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'bankIfscCode': bankIfscCode,
      'isVerifiedSupplier': isVerifiedSupplier,
    };
  }

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? businessName,
    String? gstNumber,
    String? businessCategory,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? profileImageUrl,
    String? userType,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
    String? upiId,
    String? bankAccountName,
    String? bankName,
    String? bankAccountNumber,
    String? bankIfscCode,
    bool? isVerifiedSupplier,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      businessName: businessName ?? this.businessName,
      gstNumber: gstNumber ?? this.gstNumber,
      businessCategory: businessCategory ?? this.businessCategory,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      userType: userType ?? this.userType,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      upiId: upiId ?? this.upiId,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfscCode: bankIfscCode ?? this.bankIfscCode,
      isVerifiedSupplier: isVerifiedSupplier ?? this.isVerifiedSupplier,
    );
  }
}
