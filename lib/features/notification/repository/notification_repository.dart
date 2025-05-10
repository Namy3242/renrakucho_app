import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/notification_model.dart';

class NotificationRepository {
  final _notificationsRef = FirebaseFirestore.instance.collection('notifications');

  Future<void> createNotification(NotificationModel notification) async {
    await _notificationsRef.add(notification.toJson());
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _notificationsRef
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromJson(doc.data(), doc.id))
            .toList());
  }
}
