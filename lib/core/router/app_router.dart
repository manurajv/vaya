import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/business_profile_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/groups/presentation/screens/group_detail_screen.dart';
import '../../features/groups/presentation/screens/create_group_screen.dart';
import '../../features/groups/presentation/screens/join_group_screen.dart';
import '../../features/groups/presentation/screens/group_chat_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/payments/presentation/screens/token_payment_screen.dart';
import '../../features/payments/presentation/screens/final_payment_screen.dart';
import '../../features/payments/presentation/screens/proforma_invoice_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/edit_profile_screen.dart';
import '../../features/products/presentation/screens/search_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/payments/presentation/screens/upload_payment_proof_screen.dart';
import '../../core/constants/app_constants.dart';
// Supplier screens (hidden in MVP)
import '../../features/supplier/presentation/screens/supplier_dashboard_screen.dart';
import '../../features/supplier/presentation/screens/supplier_profile_setup_screen.dart';
import '../../features/supplier/presentation/screens/add_product_screen.dart';
import '../../features/supplier/presentation/screens/discount_approvals_screen.dart';
import '../../features/supplier/presentation/screens/supplier_order_detail_screen.dart';
import '../../features/supplier/presentation/screens/set_group_target_screen.dart';
import '../../features/groups/presentation/screens/group_expired_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String businessProfile = '/business-profile';
  static const String home = '/home';
  static const String productDetail = '/product/:productId';
  static const String groupDetail = '/group/:groupId';
  static const String createGroup = '/create-group/:productId';
  static const String joinGroup = '/join-group/:groupId';
  static const String groupChat = '/group-chat/:groupId';
  static const String orders = '/orders';
  static const String orderDetail = '/order/:orderId';
  static const String tokenPayment = '/payment/token/:groupId';
  static const String finalPayment = '/payment/final/:orderId';
  static const String proformaInvoice = '/invoice/:orderId';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String notifications = '/notifications';
  static const String search = '/search';
  static const String groupExpired = '/group-expired/:groupId';
  static const String uploadPaymentProof = '/payment/proof/:groupId/:type';

  // Supplier routes
  static const String supplierDashboard = '/supplier';
  static const String supplierProfileSetup = '/supplier/setup';
  static const String supplierAddProduct = '/supplier/product/add';
  static const String supplierEditProduct = '/supplier/product/edit';
  static const String supplierApprovals = '/supplier/approvals';
  static const String supplierSetTarget = '/supplier/target';

  static String supplierOrderDetail(String orderId) =>
      '/supplier/order/$orderId';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      if (!AppConstants.kSupplierPanelEnabled &&
          state.uri.path.startsWith('/supplier')) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final phone = extra['phone'] as String? ?? '';
          final role = extra['role'] as String? ?? AppConstants.userTypeBuyer;
          return OtpScreen(phoneNumber: phone, role: role);
        },
      ),
      GoRoute(
        path: AppRoutes.businessProfile,
        builder: (context, state) => const BusinessProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return ProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(
        path: AppRoutes.groupDetail,
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return GroupDetailScreen(groupId: groupId);
        },
      ),
      GoRoute(
        path: AppRoutes.createGroup,
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return CreateGroupScreen(productId: productId);
        },
      ),
      GoRoute(
        path: AppRoutes.joinGroup,
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return JoinGroupScreen(groupId: groupId);
        },
      ),
      GoRoute(
        path: AppRoutes.groupChat,
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return GroupChatScreen(groupId: groupId);
        },
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderDetailScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppRoutes.tokenPayment,
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return TokenPaymentScreen(groupId: groupId);
        },
      ),
      GoRoute(
        path: AppRoutes.finalPayment,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return FinalPaymentScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppRoutes.proformaInvoice,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return ProformaInvoiceScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.groupExpired,
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return GroupExpiredScreen(groupId: groupId);
        },
      ),
      GoRoute(
        path: AppRoutes.uploadPaymentProof,
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          final type = state.pathParameters['type']!;
          final orderId = state.uri.queryParameters['orderId'];
          return UploadPaymentProofScreen(
            groupId: groupId,
            paymentType: type,
            orderId: orderId,
          );
        },
      ),

      // ── Supplier Panel ──────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.supplierDashboard,
        builder: (context, state) => const SupplierDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.supplierProfileSetup,
        builder: (context, state) => const SupplierProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.supplierAddProduct,
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.supplierEditProduct}/:productId',
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return AddProductScreen(editProductId: productId);
        },
      ),
      GoRoute(
        path: AppRoutes.supplierApprovals,
        builder: (context, state) => const DiscountApprovalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.supplierSetTarget,
        builder: (context, state) {
          final productId = state.uri.queryParameters['productId'];
          return SetGroupTargetScreen(preselectedProductId: productId);
        },
      ),
      GoRoute(
        path: '/supplier/order/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return SupplierOrderDetailScreen(orderId: orderId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
