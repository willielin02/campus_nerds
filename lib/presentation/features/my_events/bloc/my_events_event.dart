import 'package:equatable/equatable.dart';

import '../../../../domain/entities/event.dart';

/// Base class for my events events
abstract class MyEventsEvent extends Equatable {
  const MyEventsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load my events data
class MyEventsLoadData extends MyEventsEvent {
  const MyEventsLoadData();
}

/// Event to refresh my events data
class MyEventsRefresh extends MyEventsEvent {
  const MyEventsRefresh();
}

/// Event to create a booking
class MyEventsCreateBooking extends MyEventsEvent {
  final String eventId;
  final EventCategory category;

  const MyEventsCreateBooking({
    required this.eventId,
    required this.category,
  });

  @override
  List<Object?> get props => [eventId, category];
}

/// Event to cancel a booking
class MyEventsCancelBooking extends MyEventsEvent {
  final String bookingId;

  const MyEventsCancelBooking(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

/// Event to load event details
class MyEventsLoadDetails extends MyEventsEvent {
  final String bookingId;

  const MyEventsLoadDetails(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

/// Event to clear any error state
class MyEventsClearError extends MyEventsEvent {
  const MyEventsClearError();
}

/// Event to clear success message
class MyEventsClearSuccess extends MyEventsEvent {
  const MyEventsClearSuccess();
}

// ============================================
// Study Plan Events (Phase 7)
// ============================================

/// Event to load group focused study plans (post-grouping)
class MyEventsLoadStudyPlans extends MyEventsEvent {
  final String groupId;

  const MyEventsLoadStudyPlans(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

/// Event to load own focused study plans (pre-grouping)
class MyEventsLoadMyStudyPlans extends MyEventsEvent {
  final String bookingId;

  const MyEventsLoadMyStudyPlans(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

/// Event to update a study plan
class MyEventsUpdateStudyPlan extends MyEventsEvent {
  final String planId;
  final String content;
  final bool isDone;
  final String? groupId; // To refresh group plans after update
  final String? bookingId; // To refresh own plans after update (pre-grouping)

  const MyEventsUpdateStudyPlan({
    required this.planId,
    required this.content,
    required this.isDone,
    this.groupId,
    this.bookingId,
  });

  @override
  List<Object?> get props => [planId, content, isDone, groupId, bookingId];
}
