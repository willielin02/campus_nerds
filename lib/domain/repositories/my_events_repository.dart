import '../entities/booking.dart';
import '../entities/event.dart';

/// Result wrapper for booking operations
class BookingResult {
  final bool success;
  final String? errorMessage;
  final String? bookingId;

  const BookingResult._({
    required this.success,
    this.errorMessage,
    this.bookingId,
  });

  factory BookingResult.success([String? bookingId]) => BookingResult._(
        success: true,
        bookingId: bookingId,
      );

  factory BookingResult.failure(String message) => BookingResult._(
        success: false,
        errorMessage: message,
      );
}

/// Abstract repository for my events operations
abstract class MyEventsRepository {
  /// Get user's upcoming events
  Future<List<MyEvent>> getUpcomingEvents();

  /// Get user's past events
  Future<List<MyEvent>> getPastEvents();

  /// Get a single event details by booking ID
  Future<MyEvent?> getEventByBookingId(String bookingId);

  /// Get group members for an event
  Future<List<GroupMember>> getGroupMembers(String groupId);

  /// Get user's ticket balance
  Future<TicketBalance> getTicketBalance();

  /// Create a booking for an event (uses RPC call)
  Future<BookingResult> createBooking({
    required String eventId,
    required EventCategory category,
  });

  /// Cancel a booking (uses RPC call)
  Future<BookingResult> cancelBooking({
    required String bookingId,
  });

  /// Check if user has already booked an event
  Future<bool> hasBookedEvent(String eventId);

  // ============================================
  // Study Plan Methods (Phase 7)
  // ============================================

  /// Get group focused study plans
  Future<List<GroupFocusedPlan>> getGroupFocusedStudyPlans(String groupId);

  /// Get own focused study plans by booking ID (pre-grouping)
  Future<List<GroupFocusedPlan>> getMyFocusedStudyPlans(String bookingId);

  /// Update a focused study plan
  Future<BookingResult> updateFocusedStudyPlan({
    required String planId,
    required String content,
    required bool isDone,
  });

  // ============================================
  // English Assignment Methods
  // ============================================

  /// Get group English assignments (post-grouping)
  Future<List<GroupEnglishAssignment>> getGroupEnglishAssignments(String groupId);

  /// Get own English assignment by booking ID (pre-grouping)
  Future<List<GroupEnglishAssignment>> getMyEnglishAssignment(String bookingId);
}
