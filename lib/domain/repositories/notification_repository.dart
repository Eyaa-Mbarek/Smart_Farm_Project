import 'package:smart_farm_test/domain/entities/notification_item.dart'; // Adjust import path

abstract class INotificationRepository {
  // Watch notifications for a user
  Stream<List<NotificationItem>> watchNotifications(String uid);
  // Add a new notification
  Future<void> addNotification(String uid, {
      required String title,
      required String body,
      String? blocId,
      String? deviceId, // Add deviceId
  });
   // Mark a notification as read
  Future<void> markNotificationAsRead(String uid, String notificationId);
  // Delete a notification
  Future<void> deleteNotification(String uid, String notificationId);
}