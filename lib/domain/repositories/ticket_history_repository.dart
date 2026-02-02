import '../entities/booking.dart';
import '../entities/ticket_history.dart';

/// Repository interface for ticket history operations
abstract class TicketHistoryRepository {
  /// Get ticket history entries for the current user
  /// Returns entries filtered by ticket type (study or games)
  /// Sorted by created_at descending (newest first)
  Future<List<TicketHistoryEntry>> getTicketHistory({
    required String ticketType,
  });

  /// Get user's current ticket balance
  Future<TicketBalance> getTicketBalance();
}
