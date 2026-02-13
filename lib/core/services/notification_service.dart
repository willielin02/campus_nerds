import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Handles background FCM messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the system notification tray.
  // No additional processing needed here.
  debugPrint('Background FCM message: ${message.messageId}');
}

/// Singleton service for managing push notifications and realtime subscriptions
///
/// Responsibilities:
/// - Request notification permissions (iOS + Android 13+)
/// - Register/unregister FCM device tokens
/// - Subscribe to Supabase Realtime for in-app notifications
/// - Emit unread notifications for the UI to display
class NotificationService {
  NotificationService._();

  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();

  NotificationRepository? _repository;
  StreamSubscription<AppNotification>? _realtimeSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _currentFcmToken;

  /// Currently active chat group ID (for foreground push suppression)
  String? _activeGroupId;

  /// Set the active chat group ID to suppress push notifications for that group.
  /// Also clears all displayed notifications when entering a chat.
  void setActiveGroupId(String? groupId) {
    _activeGroupId = groupId;
    if (groupId != null) {
      _localNotifications.cancelAll();
    }
  }

  /// Local notifications plugin for showing foreground push notifications
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'campus_nerds_notifications',
    '校園書呆子通知',
    description: '活動分組與系統通知',
    importance: Importance.high,
  );

  /// Stream of new notifications (from Realtime + FCM foreground)
  final _notificationController = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get onNotification => _notificationController.stream;

  /// Stream of unread notifications fetched on init
  final _unreadController = StreamController<List<AppNotification>>.broadcast();
  Stream<List<AppNotification>> get onUnreadNotifications => _unreadController.stream;

  /// Initialize the notification service
  ///
  /// Call this after the user is authenticated.
  Future<void> initialize(NotificationRepository repository) async {
    _repository = repository;

    // 1. Request permissions
    await _requestPermissions();

    // 2. Set up local notifications (for foreground display)
    try {
      await _setupLocalNotifications();
    } catch (e) {
      debugPrint('Error setting up local notifications: $e');
    }

    // 3. Set up FCM
    await _setupFcm();

    // 4. Subscribe to Realtime
    _subscribeRealtime();

    // 5. Fetch existing unread notifications
    await checkUnreadNotifications();
  }

  /// Check for unread notifications and emit them
  Future<void> checkUnreadNotifications() async {
    if (_repository == null) return;

    try {
      final unread = await _repository!.getUnreadNotifications();
      if (unread.isNotEmpty) {
        _unreadController.add(unread);
      }
    } catch (e) {
      debugPrint('Error checking unread notifications: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository?.markAsRead(notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Clean up on logout
  Future<void> dispose() async {
    // Remove FCM token from server
    if (_currentFcmToken != null) {
      try {
        await _repository?.removeDeviceToken(_currentFcmToken!);
      } catch (e) {
        debugPrint('Error removing device token: $e');
      }
    }

    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _repository?.unsubscribe();
    _repository = null;
    _currentFcmToken = null;
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  /// Set up flutter_local_notifications for foreground display
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);

    // Create the notification channel on Android
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  /// Show a local notification (used for foreground FCM messages)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails),
    );
  }

  /// Set up FCM token registration and foreground message handling
  Future<void> _setupFcm() async {
    final messaging = FirebaseMessaging.instance;

    // Get current token and register
    try {
      final token = await messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // Listen for token refreshes
    _tokenRefreshSubscription = messaging.onTokenRefresh.listen((newToken) {
      _registerToken(newToken);
    });

    // Handle foreground messages — show as local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground FCM message: ${message.messageId}');

      // Suppress push for the chat group currently being viewed
      final messageGroupId = message.data['group_id'] as String?;
      if (messageGroupId != null && messageGroupId == _activeGroupId) {
        debugPrint('Suppressed chat notification for active group');
        return;
      }

      _showLocalNotification(message);
    });

    // Handle message tap (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('User tapped notification: ${message.data}');
      // Navigation is handled by the notification dialog flow
    });
  }

  /// Register FCM token with the server
  Future<void> _registerToken(String token) async {
    _currentFcmToken = token;

    final platform = Platform.isIOS ? 'ios' : 'android';

    try {
      await _repository?.registerDeviceToken(
        token: token,
        platform: platform,
      );
      debugPrint('FCM token registered ($platform)');
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  /// Subscribe to Supabase Realtime for instant in-app notifications
  void _subscribeRealtime() {
    if (_repository == null) return;

    _realtimeSubscription?.cancel();
    final stream = _repository!.subscribeToNotifications();
    _realtimeSubscription = stream.listen(
      (notification) {
        _notificationController.add(notification);
      },
      onError: (error) {
        debugPrint('Realtime notification error: $error');
      },
    );
  }
}
