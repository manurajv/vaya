import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/notification_model.dart';

final notificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(AppConstants.notificationsCollection)
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => NotificationModel.fromFirestore(d)).toList());
});

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (list) => list.where((n) => !n.isRead).length,
        orElse: () => 0,
      );
});

Future<void> markAllNotificationsRead(String uid) async {
  final snap = await FirebaseFirestore.instance
      .collection(AppConstants.notificationsCollection)
      .where('userId', isEqualTo: uid)
      .where('isRead', isEqualTo: false)
      .get();

  final batch = FirebaseFirestore.instance.batch();
  for (final doc in snap.docs) {
    batch.update(doc.reference, {'isRead': true});
  }
  await batch.commit();
}

Future<void> markNotificationRead(String notificationId) async {
  await FirebaseFirestore.instance
      .collection(AppConstants.notificationsCollection)
      .doc(notificationId)
      .update({'isRead': true});
}
