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

  // English assignments
  final List<GroupEnglishAssignment> englishAssignments;
  final bool isLoadingEnglishAssignments;

  /// 從外部導航過來時指定要切到哪個 tab（0=Upcoming, 1=History）
  final int? pendingTabIndex;

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
    this.englishAssignments = const [],
    this.isLoadingEnglishAssignments = false,
    this.pendingTabIndex,
  });

  /// Check if data is loaded
  bool get isLoaded => status == MyEventsStatus.loaded;

  /// Check if there are any events
  bool get hasEvents => upcomingEvents.isNotEmpty || pastEvents.isNotEmpty;

  /// Check if there are upcoming events
  bool get hasUpcomingEvents => upcomingEvents.isNotEmpty;

  /// Total unread message count across all upcoming events
  int get totalUnreadMessageCount =>
      upcomingEvents.fold(0, (sum, e) => sum + e.unreadMessageCount);

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
    List<GroupEnglishAssignment>? englishAssignments,
    bool? isLoadingEnglishAssignments,
    int? pendingTabIndex,
    bool clearPendingTabIndex = false,
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
      englishAssignments: englishAssignments ?? this.englishAssignments,
      isLoadingEnglishAssignments: isLoadingEnglishAssignments ?? this.isLoadingEnglishAssignments,
      pendingTabIndex: clearPendingTabIndex ? null : (pendingTabIndex ?? this.pendingTabIndex),
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
        englishAssignments,
        isLoadingEnglishAssignments,
        pendingTabIndex,
      ];
}
