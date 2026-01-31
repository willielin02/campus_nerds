import '../entities/chat.dart';

/// Repository interface for chat operations
abstract class ChatRepository {
  /// Fetch a page of chat timeline messages
  ///
  /// [groupId] - The group ID to fetch messages for
  /// [beforeSortTs] - Fetch messages before this timestamp (for pagination)
  /// [limit] - Maximum number of messages to fetch
  Future<ChatTimelinePage> fetchTimelinePage({
    required String groupId,
    DateTime? beforeSortTs,
    int limit = 20,
  });

  /// Send a message to the group chat
  Future<SendMessageResult> sendMessage({
    required String groupId,
    required String content,
  });

  /// Mark user as joined in the chat
  /// This records a system message showing user joined
  Future<void> markJoined(String groupId);

  /// Subscribe to real-time chat updates
  /// Returns a stream of new messages
  Stream<List<ChatMessage>> subscribeToTimeline(String groupId);

  /// Unsubscribe from chat updates
  void unsubscribe();
}
