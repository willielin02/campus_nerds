import 'package:equatable/equatable.dart';

/// Type of in-app notification
enum NotificationType {
  eventGroupResult('event_group_result'),
  chatOpen('chat_open');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.eventGroupResult,
    );
  }
}

/// In-app notification entity
class AppNotification extends Equatable {
  final String id;
  final String eventId;
  final String? bookingId;
  final String? groupId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.eventId,
    this.bookingId,
    this.groupId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.createdAt,
  });

  /// Whether this notification indicates the user was grouped
  bool get isGrouped => groupId != null;

  @override
  List<Object?> get props => [id, eventId, bookingId, groupId, type, title, body, createdAt];
}
