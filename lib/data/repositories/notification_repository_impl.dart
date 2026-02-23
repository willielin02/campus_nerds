import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Implementation of NotificationRepository using Supabase
class NotificationRepositoryImpl implements NotificationRepository {
  RealtimeChannel? _channel;
  StreamController<AppNotification>? _notificationController;

  @override
  Future<List<AppNotification>> getUnreadNotifications() async {
    try {
      final response = await SupabaseService.rpc('get_unread_notifications');
      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => _parseNotification(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await SupabaseService.rpc(
      'mark_notification_read',
      params: {'p_notification_id': notificationId},
    );
  }

  @override
  Future<void> markGroupNotificationsAsRead(String groupId, {String type = 'chat_open'}) async {
    await SupabaseService.rpc(
      'mark_group_notifications_read',
      params: {'p_group_id': groupId, 'p_type': type},
    );
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await SupabaseService.rpc(
      'upsert_device_token',
      params: {
        'p_token': token,
        'p_platform': platform,
      },
    );
  }

  @override
  Future<void> removeDeviceToken(String token) async {
    await SupabaseService.rpc(
      'remove_device_token',
      params: {'p_token': token},
    );
  }

  @override
  Stream<AppNotification> subscribeToNotifications() {
    _notificationController?.close();
    _notificationController = StreamController<AppNotification>.broadcast();

    final currentUserId = SupabaseService.currentUserId;
    if (currentUserId == null) {
      return _notificationController!.stream;
    }

    _channel = SupabaseService.channel('notifications:$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              final notification = _parseNotification(newRecord);
              _notificationController?.add(notification);
            }
          },
        )
        .subscribe();

    return _notificationController!.stream;
  }

  @override
  void unsubscribe() {
    if (_channel != null) {
      SupabaseService.removeChannel(_channel!);
      _channel = null;
    }
    _notificationController?.close();
    _notificationController = null;
  }

  AppNotification _parseNotification(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      eventId: map['event_id'] as String,
      bookingId: map['booking_id'] as String?,
      groupId: map['group_id'] as String?,
      type: NotificationType.fromString(map['type'] as String? ?? ''),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      data: map['data'] as Map<String, dynamic>?,
      createdAt: _parseDateTime(map['created_at']) ?? DateTime.now(),
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
