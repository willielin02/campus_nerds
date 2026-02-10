import 'package:equatable/equatable.dart';

import '../../core/utils/app_clock.dart';
import 'event.dart';

/// Booking status types
enum BookingStatus {
  pending('pending', '等待配對'),
  matched('matched', '已配對'),
  cancelled('cancelled', '已取消'),
  completed('completed', '已完成'),
  noShow('no_show', '未出席');

  final String value;
  final String displayName;

  const BookingStatus(this.value, this.displayName);

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BookingStatus.pending,
    );
  }
}

/// Group status types
enum GroupStatus {
  pending('pending', '組隊中'),
  confirmed('confirmed', '已確認'),
  started('started', '活動中'),
  completed('completed', '已結束'),
  cancelled('cancelled', '已取消');

  final String value;
  final String displayName;

  const GroupStatus(this.value, this.displayName);

  static GroupStatus fromString(String value) {
    return GroupStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GroupStatus.pending,
    );
  }
}

/// Group member profile
class GroupMember extends Equatable {
  final String id;
  final String? nickname;
  final String? gender;
  final int? academicRank;
  final bool isCurrentUser;

  const GroupMember({
    required this.id,
    this.nickname,
    this.gender,
    this.academicRank,
    this.isCurrentUser = false,
  });

  /// Get display name (nickname or anonymous)
  String get displayName => nickname ?? '匿名';

  /// Get gender display
  String get genderDisplay {
    if (gender == 'male') return '男';
    if (gender == 'female') return '女';
    return '';
  }

  @override
  List<Object?> get props => [id, nickname, gender, academicRank, isCurrentUser];
}

/// My event entity representing a user's booked event
class MyEvent extends Equatable {
  final String bookingId;
  final String eventId;
  final String? groupId;
  final BookingStatus bookingStatus;
  final DateTime bookingCreatedAt;
  final DateTime? cancelledAt;

  // Event info
  final EventCategory eventCategory;
  final String? cityId;
  final String? universityId;
  final DateTime eventDate;
  final TimeSlot timeSlot;
  final String locationDetail;
  final EventStatus eventStatus;
  final DateTime? signupDeadlineAt;

  // Group info
  final GroupStatus? groupStatus;
  final DateTime? groupStartAt;
  final DateTime? chatOpenAt;

  // Venue info
  final String? venueId;
  final String? venueName;
  final String? venueAddress;
  final String? venueGoogleMapUrl;

  // Timing info
  final DateTime? goalCloseAt;
  final DateTime? feedbackSentAt;

  // Feedback flags
  final bool hasEventFeedback;
  final bool hasPeerFeedbackAll;
  final bool hasFilledFeedbackAll;

  // Group members (loaded separately)
  final List<GroupMember> groupMembers;

  const MyEvent({
    required this.bookingId,
    required this.eventId,
    this.groupId,
    required this.bookingStatus,
    required this.bookingCreatedAt,
    this.cancelledAt,
    required this.eventCategory,
    this.cityId,
    this.universityId,
    required this.eventDate,
    required this.timeSlot,
    required this.locationDetail,
    required this.eventStatus,
    this.signupDeadlineAt,
    this.groupStatus,
    this.groupStartAt,
    this.chatOpenAt,
    this.venueId,
    this.venueName,
    this.venueAddress,
    this.venueGoogleMapUrl,
    this.goalCloseAt,
    this.feedbackSentAt,
    this.hasEventFeedback = false,
    this.hasPeerFeedbackAll = false,
    this.hasFilledFeedbackAll = false,
    this.groupMembers = const [],
  });

  /// Check if this is a focused study event
  bool get isFocusedStudy => eventCategory == EventCategory.focusedStudy;

  /// Check if this is an english games event
  bool get isEnglishGames => eventCategory == EventCategory.englishGames;

  /// Check if booking is active (not cancelled)
  bool get isActive => bookingStatus != BookingStatus.cancelled;

  /// Check if booking can be cancelled
  bool get canCancel {
    if (!isActive) return false;
    if (signupDeadlineAt == null) return false;
    return AppClock.now().isBefore(signupDeadlineAt!);
  }

  /// Check if event is upcoming
  bool get isUpcoming {
    final now = AppClock.now();
    final eventDateTime = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
    );
    return eventDateTime.isAfter(now) ||
        eventDateTime.isAtSameMomentAs(DateTime(now.year, now.month, now.day));
  }

  /// Check if event is in the past
  bool get isPast => !isUpcoming;

  /// Check if chat is open
  bool get isChatOpen {
    if (chatOpenAt == null) return false;
    return AppClock.now().isAfter(chatOpenAt!);
  }

  /// Check if goal content can still be edited (before goalCloseAt)
  /// Pre-grouping (goalCloseAt null): always editable
  /// Post-grouping: editable until goalCloseAt (venue start + 1hr)
  bool get canEditGoalContent {
    if (goalCloseAt == null) return true;
    return AppClock.now().isBefore(goalCloseAt!);
  }

  /// Check if goal completion can still be toggled
  /// Requires: after groupStartAt (venue start) AND event still in Upcoming
  /// (event_date >= today). Closes when the event moves to History.
  bool get canCheckGoal {
    if (groupStartAt == null) return false;
    final now = AppClock.now();
    if (now.isBefore(groupStartAt!)) return false;
    return isUpcoming;
  }

  /// Check if feedback window is open
  bool get isFeedbackOpen {
    if (feedbackSentAt == null) return false;
    return AppClock.now().isAfter(feedbackSentAt!) && !hasFilledFeedbackAll;
  }

  /// Check if user has matched group
  bool get hasGroup => groupId != null && groupStatus != null;

  /// Get formatted date string (e.g., "1/30 週四")
  String get formattedDate {
    final weekdays = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
    final weekday = weekdays[eventDate.weekday - 1];
    return '${eventDate.month}/${eventDate.day} $weekday';
  }

  /// Get formatted time range string
  String get formattedTimeRange => timeSlot.timeRange;

  /// Copy with new group members
  MyEvent copyWithGroupMembers(List<GroupMember> members) {
    return MyEvent(
      bookingId: bookingId,
      eventId: eventId,
      groupId: groupId,
      bookingStatus: bookingStatus,
      bookingCreatedAt: bookingCreatedAt,
      cancelledAt: cancelledAt,
      eventCategory: eventCategory,
      cityId: cityId,
      universityId: universityId,
      eventDate: eventDate,
      timeSlot: timeSlot,
      locationDetail: locationDetail,
      eventStatus: eventStatus,
      signupDeadlineAt: signupDeadlineAt,
      groupStatus: groupStatus,
      groupStartAt: groupStartAt,
      chatOpenAt: chatOpenAt,
      venueId: venueId,
      venueName: venueName,
      venueAddress: venueAddress,
      venueGoogleMapUrl: venueGoogleMapUrl,
      goalCloseAt: goalCloseAt,
      feedbackSentAt: feedbackSentAt,
      hasEventFeedback: hasEventFeedback,
      hasPeerFeedbackAll: hasPeerFeedbackAll,
      hasFilledFeedbackAll: hasFilledFeedbackAll,
      groupMembers: members,
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        eventId,
        groupId,
        bookingStatus,
        bookingCreatedAt,
        cancelledAt,
        eventCategory,
        cityId,
        universityId,
        eventDate,
        timeSlot,
        locationDetail,
        eventStatus,
        signupDeadlineAt,
        groupStatus,
        groupStartAt,
        chatOpenAt,
        venueId,
        venueName,
        venueAddress,
        venueGoogleMapUrl,
        goalCloseAt,
        feedbackSentAt,
        hasEventFeedback,
        hasPeerFeedbackAll,
        hasFilledFeedbackAll,
        groupMembers,
      ];
}

/// User's ticket balance
class TicketBalance extends Equatable {
  final int studyBalance;
  final int gamesBalance;

  const TicketBalance({
    this.studyBalance = 0,
    this.gamesBalance = 0,
  });

  @override
  List<Object?> get props => [studyBalance, gamesBalance];
}

/// Individual study plan goal
class StudyPlan extends Equatable {
  final String id;
  final String bookingId;
  final int slot; // 1, 2, or 3
  final String content;
  final bool isDone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyPlan({
    required this.id,
    required this.bookingId,
    required this.slot,
    required this.content,
    required this.isDone,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, bookingId, slot, content, isDone, createdAt, updatedAt];
}

/// Group member's focused study plans
/// groupId is nullable for pre-grouping plans (user has booked but no group yet)
class GroupFocusedPlan extends Equatable {
  final String? groupId;
  final String? userId;
  final String displayName;
  final bool isMe;
  final String? gender;
  final String? universityName;
  final int? age;

  // Plan 1
  final String? plan1Id;
  final String? plan1Content;
  final bool plan1Done;

  // Plan 2
  final String? plan2Id;
  final String? plan2Content;
  final bool plan2Done;

  // Plan 3
  final String? plan3Id;
  final String? plan3Content;
  final bool plan3Done;

  const GroupFocusedPlan({
    this.groupId,
    this.userId,
    required this.displayName,
    required this.isMe,
    this.gender,
    this.universityName,
    this.age,
    this.plan1Id,
    this.plan1Content,
    this.plan1Done = false,
    this.plan2Id,
    this.plan2Content,
    this.plan2Done = false,
    this.plan3Id,
    this.plan3Content,
    this.plan3Done = false,
  });

  /// Check if all goals are completed
  bool get allDone => plan1Done && plan2Done && plan3Done;

  /// Get number of completed goals
  int get completedCount {
    int count = 0;
    if (plan1Done) count++;
    if (plan2Done) count++;
    if (plan3Done) count++;
    return count;
  }

  /// Get total number of goals with content
  int get totalGoals {
    int count = 0;
    if (plan1Content != null && plan1Content!.isNotEmpty) count++;
    if (plan2Content != null && plan2Content!.isNotEmpty) count++;
    if (plan3Content != null && plan3Content!.isNotEmpty) count++;
    return count;
  }

  /// Age display string
  String get ageDisplay => age != null ? '$age 歲' : '';

  @override
  List<Object?> get props => [
        groupId,
        userId,
        displayName,
        isMe,
        gender,
        universityName,
        age,
        plan1Id,
        plan1Content,
        plan1Done,
        plan2Id,
        plan2Content,
        plan2Done,
        plan3Id,
        plan3Content,
        plan3Done,
      ];
}
