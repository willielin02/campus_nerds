import '../entities/app_notification.dart';

/// Repository interface for notification operations
abstract class NotificationRepository {
  /// Fetch all unread notifications for the current user
  Future<List<AppNotification>> getUnreadNotifications();

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications of a given type for a group as read
  Future<void> markGroupNotificationsAsRead(String groupId, {String type = 'chat_open'});

  /// Register a device token for push notifications
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  });

  /// Remove a device token (on logout)
  Future<void> removeDeviceToken(String token);

  /// Subscribe to real-time notification inserts for the current user
  Stream<AppNotification> subscribeToNotifications();

  /// Unsubscribe from real-time notifications
  void unsubscribe();
}
