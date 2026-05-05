class AppConstants {
  AppConstants._();

  // Feature Flags
  static const bool kSupplierPanelEnabled = true; // Enabled
  static const bool kPartialPaymentEnabled = false; // Optional in MVP
  static const bool kAdvancedLogisticsEnabled = false;
  static const bool kAiRecommendationsEnabled = false;
  static const bool kCreditSystemEnabled = false;

  // App Config
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String supportEmail = 'support@vaya.in';
  static const String supportPhone = '+91-XXXXXXXXXX';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String groupsCollection = 'groups';
  static const String ordersCollection = 'orders';
  static const String chatsCollection = 'chats';
  static const String messagesSubCollection = 'messages';
  static const String notificationsCollection = 'notifications';
  static const String suppliersCollection = 'suppliers';
  static const String paymentsCollection = 'payments';
  static const String invoicesCollection = 'invoices';
  static const String categoriesCollection = 'categories';

  // Pagination
  static const int defaultPageSize = 20;
  static const int chatPageSize = 30;

  // Group Config
  static const int defaultGroupDurationHours = 48;
  static const int minGroupDurationHours = 12;
  static const int maxGroupDurationHours = 168; // 7 days
  static const int groupExtensionHours = 24;
  static const double defaultTokenPercentage = 10.0; // 10% token amount

  // OTP Config
  static const int otpLength = 6;
  static const int otpResendSeconds = 30;
  static const int otpTimeoutSeconds = 120;

  // Validation
  static const int minMobileLength = 10;
  static const int maxMobileLength = 10;
  static const int minBusinessNameLength = 3;
  static const int maxBusinessNameLength = 100;
  static const int minQuantity = 1;
  static const int maxQuantity = 999999;

  // Payment
  static const String companyUpiId = 'vaya@upi'; // Company UPI for token
  static const String companyAccountName = 'VAYA Technologies Pvt Ltd';
  static const String companyBankName = 'HDFC Bank';
  static const String companyAccountNumber = 'XXXXXXXXXXXX';
  static const String companyIfscCode = 'HDFC0XXXXXX';

  // Notification Channels
  static const String dealAlertChannel = 'deal_alerts';
  static const String groupUpdateChannel = 'group_updates';
  static const String paymentChannel = 'payment_updates';
  static const String orderChannel = 'order_updates';
  static const String chatChannel = 'chat_messages';

  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String productImagesPath = 'product_images';
  static const String chatMediaPath = 'chat_media';
  static const String paymentProofsPath = 'payment_proofs';
  static const String invoicesPath = 'invoices';

  // Shared Preferences Keys
  static const String prefUserId = 'user_id';
  static const String prefUserType = 'user_type';
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefFcmToken = 'fcm_token';
  static const String prefThemeMode = 'theme_mode';

  // User Types
  static const String userTypeBuyer = 'buyer';
  static const String userTypeSupplier = 'supplier';

  // Group Status
  static const String groupStatusActive = 'active';
  static const String groupStatusCompleted = 'completed';
  static const String groupStatusExpired = 'expired';
  static const String groupStatusCancelled = 'cancelled';
  static const String groupStatusPendingApproval = 'pending_approval';

  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusConfirmed = 'confirmed';
  static const String orderStatusProcessing = 'processing';
  static const String orderStatusShipped = 'shipped';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';

  // Payment Status
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusTokenPaid = 'token_paid';
  static const String paymentStatusFullPaid = 'full_paid';
  static const String paymentStatusFailed = 'failed';
  static const String paymentStatusRefunded = 'refunded';

  // Group Modes
  static const String groupModeBuyerInitiated = 'buyer_initiated';
  static const String groupModeSupplierTarget = 'supplier_target';

  // Message Types
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeVideo = 'video';
  static const String messageTypeAudio = 'audio';
  static const String messageTypeFile = 'file';
  static const String messageTypeSystem = 'system';
}
