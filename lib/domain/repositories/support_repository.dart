import '../entities/support.dart';

/// Repository interface for support ticket operations
abstract class SupportRepository {
  /// Get all tickets for the current user
  Future<List<SupportTicket>> getMyTickets();

  /// Create a new ticket with initial message
  Future<SupportTicket> createTicket({
    required TicketCategory category,
    required String subject,
    required String message,
    String? imagePath,
  });

  /// Get all messages for a ticket
  Future<List<SupportMessage>> getTicketMessages(String ticketId);

  /// Send a message in a ticket
  Future<SupportMessage> sendMessage({
    required String ticketId,
    String? content,
    String? imagePath,
  });

  /// Upload an attachment and return the storage path
  Future<String> uploadAttachment({
    required String ticketId,
    required String filePath,
  });

  /// Get a signed URL for an image
  Future<String?> getImageUrl(String imagePath);
}
