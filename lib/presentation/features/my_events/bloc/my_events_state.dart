import 'package:equatable/equatable.dart';

import '../../../../domain/entities/booking.dart';

/// Status for my events page loading
enum MyEventsStatus {
  initial,
  loading,
  loaded,
  error,
}

/// State for my events BLoC
class MyEventsState extends Equatable {
  final MyEventsStatus status;
  final List<MyEvent> upcomingEvents;
  final List<MyEvent> pastEvents;
  final TicketBalance ticketBalance;
  final MyEvent? selectedEvent;
  final String? errorMessage;
  final String? successMessage;
  final bool isRefreshing;
  final bool isBooking;

  // Study plans (Phase 7)
  final List<GroupFocusedPlan> studyPlans;
  final bool isLoadingStudyPlans;
  final bool isUpdatingStudyPlan;

  const MyEventsState({
    this.status = MyEventsStatus.initial,
    this.upcomingEvents = const [],
    this.pastEvents = const [],
    this.ticketBalance = const TicketBalance(),
    this.selectedEvent,
    this.errorMessage,
    this.successMessage,
    this.isRefreshing = false,
    this.isBooking = false,
    this.studyPlans = const [],
    this.isLoadingStudyPlans = false,
    this.isUpdatingStudyPlan = false,
  });

  /// Check if data is loaded
  bool get isLoaded => status == MyEventsStatus.loaded;

  /// Check if there are any events
  bool get hasEvents => upcomingEvents.isNotEmpty || pastEvents.isNotEmpty;

  /// Check if there are upcoming events
  bool get hasUpcomingEvents => upcomingEvents.isNotEmpty;

  MyEventsState copyWith({
    MyEventsStatus? status,
    List<MyEvent>? upcomingEvents,
    List<MyEvent>? pastEvents,
    TicketBalance? ticketBalance,
    MyEvent? selectedEvent,
    bool clearSelectedEvent = false,
    String? errorMessage,
    String? successMessage,
    bool? isRefreshing,
    bool? isBooking,
    List<GroupFocusedPlan>? studyPlans,
    bool? isLoadingStudyPlans,
    bool? isUpdatingStudyPlan,
  }) {
    return MyEventsState(
      status: status ?? this.status,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      pastEvents: pastEvents ?? this.pastEvents,
      ticketBalance: ticketBalance ?? this.ticketBalance,
      selectedEvent:
          clearSelectedEvent ? null : (selectedEvent ?? this.selectedEvent),
      errorMessage: errorMessage,
      successMessage: successMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isBooking: isBooking ?? this.isBooking,
      studyPlans: studyPlans ?? this.studyPlans,
      isLoadingStudyPlans: isLoadingStudyPlans ?? this.isLoadingStudyPlans,
      isUpdatingStudyPlan: isUpdatingStudyPlan ?? this.isUpdatingStudyPlan,
    );
  }

  @override
  List<Object?> get props => [
        status,
        upcomingEvents,
        pastEvents,
        ticketBalance,
        selectedEvent,
        errorMessage,
        successMessage,
        isRefreshing,
        isBooking,
        studyPlans,
        isLoadingStudyPlans,
        isUpdatingStudyPlan,
      ];
}
