import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';

// Top-level handler required by Firebase for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this runs
  NotificationService._showLocalNotification(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Android notification channels
  static const _dealAlertChannel = AndroidNotificationChannel(
    AppConstants.dealAlertChannel,
    'Deal Alerts',
    description: 'Notifications about expiring deals',
    importance: Importance.high,
  );

  static const _groupUpdateChannel = AndroidNotificationChannel(
    AppConstants.groupUpdateChannel,
    'Group Updates',
    description: 'Notifications about your group orders',
    importance: Importance.high,
  );

  static const _paymentChannel = AndroidNotificationChannel(
    AppConstants.paymentChannel,
    'Payment Updates',
    description: 'Payment reminders and confirmations',
    importance: Importance.max,
  );

  static const _orderChannel = AndroidNotificationChannel(
    AppConstants.orderChannel,
    'Order Updates',
    description: 'Order status updates',
    importance: Importance.defaultImportance,
  );

  static const _chatChannel = AndroidNotificationChannel(
    AppConstants.chatChannel,
    'Chat Messages',
    description: 'New messages in your group chats',
    importance: Importance.high,
  );

  /// Initialize everything — call once from main()
  static Future<void> initialize() async {
    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request permissions
    await _requestPermissions();

    // 3. Set up local notifications
    await _initLocalNotifications();

    // 4. Create Android channels
    await _createAndroidChannels();

    // 5. Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 7. Handle notification tap when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // 8. Save FCM token to Firestore
    await _saveFcmToken();

    // 9. Listen for token refresh
    _messaging.onTokenRefresh.listen(_updateFcmToken);
  }

  static Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        // Handle local notification tap — navigate based on payload
        _handleLocalNotificationTap(details.payload);
      },
    );
  }

  static Future<void> _createAndroidChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    for (final channel in [
      _dealAlertChannel,
      _groupUpdateChannel,
      _paymentChannel,
      _orderChannel,
      _chatChannel,
    ]) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(message);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    // Navigation is handled by the router based on data payload
    // The app's GoRouter will read the notification data on next build
    final data = message.data;
    // Store the route to navigate to
    if (data['route'] != null) {
      _pendingRoute = data['route'] as String;
    }
  }

  static void _handleLocalNotificationTap(String? payload) {
    if (payload != null) {
      _pendingRoute = payload;
    }
  }

  // Pending route from notification tap — consumed by router
  static String? _pendingRoute;
  static String? consumePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final channelId = _channelIdFromData(message.data);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelNameFromId(channelId),
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['route'],
    );
  }

  static String _channelIdFromData(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'deal_alert':
        return AppConstants.dealAlertChannel;
      case 'group_update':
        return AppConstants.groupUpdateChannel;
      case 'payment':
        return AppConstants.paymentChannel;
      case 'order':
        return AppConstants.orderChannel;
      case 'chat':
        return AppConstants.chatChannel;
      default:
        return AppConstants.groupUpdateChannel;
    }
  }

  static String _channelNameFromId(String id) {
    switch (id) {
      case AppConstants.dealAlertChannel:
        return 'Deal Alerts';
      case AppConstants.groupUpdateChannel:
        return 'Group Updates';
      case AppConstants.paymentChannel:
        return 'Payment Updates';
      case AppConstants.orderChannel:
        return 'Order Updates';
      case AppConstants.chatChannel:
        return 'Chat Messages';
      default:
        return 'VAYA';
    }
  }

  static Future<void> _saveFcmToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefFcmToken, token);

    await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'fcmToken': token});
  }

  static Future<void> _updateFcmToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'fcmToken': token});
  }

  /// Show a local notification directly (for in-app events)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String channelId = AppConstants.groupUpdateChannel,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelNameFromId(channelId),
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
