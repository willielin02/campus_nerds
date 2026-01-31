import 'package:equatable/equatable.dart';

/// Event category types
enum EventCategory {
  focusedStudy('focused_study', '專注讀書'),
  englishGames('english_games', '英文遊戲');

  final String value;
  final String displayName;

  const EventCategory(this.value, this.displayName);

  static EventCategory fromString(String value) {
    return EventCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EventCategory.focusedStudy,
    );
  }
}

/// Event status types
enum EventStatus {
  open('open', '報名中'),
  full('full', '已額滿'),
  closed('closed', '已截止'),
  cancelled('cancelled', '已取消'),
  completed('completed', '已結束');

  final String value;
  final String displayName;

  const EventStatus(this.value, this.displayName);

  static EventStatus fromString(String value) {
    return EventStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EventStatus.closed,
    );
  }
}

/// Time slot for events
enum TimeSlot {
  morning('morning', '早上', '09:00 - 12:00'),
  afternoon('afternoon', '下午', '14:00 - 17:00'),
  evening('evening', '晚上', '19:00 - 22:00');

  final String value;
  final String displayName;
  final String timeRange;

  const TimeSlot(this.value, this.displayName, this.timeRange);

  static TimeSlot fromString(String value) {
    return TimeSlot.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TimeSlot.afternoon,
    );
  }
}

/// Event entity representing a study or games event
class Event extends Equatable {
  final String id;
  final String? universityId;
  final String cityId;
  final EventCategory category;
  final DateTime eventDate;
  final TimeSlot timeSlot;
  final EventStatus status;
  final String locationDetail;
  final DateTime signupOpenAt;
  final DateTime signupDeadlineAt;
  final DateTime? notifyDeadlineAt;
  final bool hasConflictSameSlot;

  const Event({
    required this.id,
    this.universityId,
    required this.cityId,
    required this.category,
    required this.eventDate,
    required this.timeSlot,
    required this.status,
    required this.locationDetail,
    required this.signupOpenAt,
    required this.signupDeadlineAt,
    this.notifyDeadlineAt,
    this.hasConflictSameSlot = false,
  });

  /// Check if signup is currently open
  bool get isSignupOpen {
    final now = DateTime.now();
    return status == EventStatus.open &&
        now.isAfter(signupOpenAt) &&
        now.isBefore(signupDeadlineAt);
  }

  /// Check if this is a focused study event
  bool get isFocusedStudy => category == EventCategory.focusedStudy;

  /// Check if this is an english games event
  bool get isEnglishGames => category == EventCategory.englishGames;

  /// Get formatted date string (e.g., "1/30 週四")
  String get formattedDate {
    final weekdays = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
    final weekday = weekdays[eventDate.weekday - 1];
    return '${eventDate.month}/${eventDate.day} $weekday';
  }

  /// Get formatted time range string
  String get formattedTimeRange => timeSlot.timeRange;

  @override
  List<Object?> get props => [
        id,
        universityId,
        cityId,
        category,
        eventDate,
        timeSlot,
        status,
        locationDetail,
        signupOpenAt,
        signupDeadlineAt,
        notifyDeadlineAt,
        hasConflictSameSlot,
      ];
}
