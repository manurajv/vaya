import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/user_model.dart';

class OtpResult {
  final bool isNewUser;
  final UserModel? user;

  const OtpResult({required this.isNewUser, this.user});
}

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final String? verificationId;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.verificationId,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    String? verificationId,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      verificationId: verificationId ?? this.verificationId,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthNotifier(this._auth, this._firestore) : super(const AuthState()) {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _loadUser(user.uid);
      } else {
        state = const AuthState();
      }
    });
  }

  Future<void> _loadUser(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (doc.exists) {
        state = state.copyWith(user: UserModel.fromFirestore(doc));
      }
    } catch (_) {
      // User doc may not exist yet for new users
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);

    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber',
      timeout: const Duration(seconds: 120),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification on Android
        try {
          await _auth.signInWithCredential(credential);
        } catch (_) {}
      },
      verificationFailed: (FirebaseAuthException e) {
        state = state.copyWith(
          isLoading: false,
          error: e.message ?? 'Verification failed',
        );
        if (!completer.isCompleted) {
          completer.completeError(e.message ?? 'Verification failed');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        state = state.copyWith(
          isLoading: false,
          verificationId: verificationId,
        );
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        state = state.copyWith(verificationId: verificationId);
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    await completer.future;
  }

  Future<OtpResult> verifyOtp(String otp) async {
    if (state.verificationId == null) {
      throw Exception('Verification ID not found. Please request OTP again.');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefUserId, uid);

      if (!isNewUser) {
        await _loadUser(uid);
      }

      state = state.copyWith(isLoading: false);
      return OtpResult(isNewUser: isNewUser, user: state.user);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      throw Exception(e.message ?? 'OTP verification failed');
    }
  }

  Future<void> saveBusinessProfile({
    required String businessName,
    String? gstNumber,
    required String businessCategory,
    required String address,
    required String city,
    required String state_,
    required String pincode,
    String userType = AppConstants.userTypeBuyer,
    // Supplier-specific
    String? upiId,
    String? bankAccountName,
    String? bankName,
    String? bankAccountNumber,
    String? bankIfscCode,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    state = state.copyWith(isLoading: true);

    try {
      final now = DateTime.now();
      final user = UserModel(
        id: uid,
        phoneNumber: _auth.currentUser!.phoneNumber ?? '',
        businessName: businessName,
        gstNumber: gstNumber,
        businessCategory: businessCategory,
        address: address,
        city: city,
        state: state_,
        pincode: pincode,
        userType: userType,
        isProfileComplete: true,
        createdAt: now,
        updatedAt: now,
        upiId: upiId,
        bankAccountName: bankAccountName,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        bankIfscCode: bankIfscCode,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(user.toFirestore());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefUserId, uid);
      await prefs.setString(AppConstants.prefUserType, userType);

      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefUserId);
    await prefs.remove(AppConstants.prefUserType);
    state = const AuthState();
  }

  UserModel? get currentUser => state.user;
  String? get currentUserId => _auth.currentUser?.uid;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});
