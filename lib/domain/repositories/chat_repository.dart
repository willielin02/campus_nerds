import '../entities/chat.dart';

/// Repository interface for chat operations
abstract class ChatRepository {
  /// Fetch a page of chat messages
  ///
  /// [groupId] - The group ID to fetch messages for
  /// [beforeCreatedAt] - Fetch messages before this timestamp (cursor pagination)
  /// [beforeId] - Fetch messages before this ID (cursor pagination tiebreaker)
  /// [limit] - Maximum number of messages to fetch
  Future<ChatTimelinePage> fetchPage({
    required String groupId,
    DateTime? beforeCreatedAt,
    String? beforeId,
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

  /// Pre-load member profiles for a group into cache
  /// Ensures Realtime messages display correct nicknames
  Future<void> loadMemberProfiles(String groupId);

  /// Subscribe to real-time chat message inserts
  /// Returns a stream of new messages
  Stream<List<ChatMessage>> subscribeToMessages(String groupId);

  /// Update last read timestamp for the current user in a group
  Future<void> updateLastRead(String groupId);

  /// Unsubscribe from chat updates
  void unsubscribe();
}
