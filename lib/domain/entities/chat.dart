import 'package:equatable/equatable.dart';

/// Chat message item types
enum ChatItemType {
  message('message'),
  systemJoined('system_joined'),
  systemStarted('system_started'),
  systemEnded('system_ended');

  final String value;
  const ChatItemType(this.value);

  static ChatItemType fromString(String value) {
    return ChatItemType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ChatItemType.message,
    );
  }
}

/// Chat message entity
class ChatMessage extends Equatable {
  final String messageId;
  final String groupId;
  final ChatItemType itemType;
  final String? content;
  final String? senderUserId;
  final String? senderNickname;
  final String? senderGender;
  final String? senderUniversityName;
  final int? senderAge;
  final DateTime createdAt;
  final bool isMe;

  const ChatMessage({
    required this.messageId,
    required this.groupId,
    required this.itemType,
    this.content,
    this.senderUserId,
    this.senderNickname,
    this.senderGender,
    this.senderUniversityName,
    this.senderAge,
    required this.createdAt,
    this.isMe = false,
  });

  /// Check if this is a system message
  bool get isSystemMessage => itemType != ChatItemType.message;

  /// Get display name for sender
  String get displaySender {
    if (isSystemMessage) return '系統';
    return (senderNickname != null && senderNickname!.isNotEmpty)
        ? senderNickname!
        : '匿名';
  }

  /// Get system message text (prefer DB content for consistency with FlutterFlow)
  String get systemMessageText {
    if (isSystemMessage && content != null) return content!;
    switch (itemType) {
      case ChatItemType.systemJoined:
        return '$displaySender 加入了聊天室';
      case ChatItemType.systemStarted:
        return '活動已開始';
      case ChatItemType.systemEnded:
        return '活動已結束';
      case ChatItemType.message:
        return content ?? '';
    }
  }

  @override
  List<Object?> get props => [
        messageId,
        groupId,
        itemType,
        content,
        senderUserId,
        senderNickname,
        senderGender,
        senderUniversityName,
        senderAge,
        createdAt,
        isMe,
      ];
}

/// Chat timeline page result
class ChatTimelinePage extends Equatable {
  final List<ChatMessage> messages;
  final bool hasMore;
  final DateTime? oldestCreatedAt;
  final String? oldestMessageId;

  const ChatTimelinePage({
    required this.messages,
    required this.hasMore,
    this.oldestCreatedAt,
    this.oldestMessageId,
  });

  @override
  List<Object?> get props => [messages, hasMore, oldestCreatedAt, oldestMessageId];
}

/// Send message result
class SendMessageResult extends Equatable {
  final bool success;
  final String? messageId;
  final String? errorMessage;

  const SendMessageResult({
    required this.success,
    this.messageId,
    this.errorMessage,
  });

  factory SendMessageResult.error(String message) {
    return SendMessageResult(
      success: false,
      errorMessage: message,
    );
  }

  @override
  List<Object?> get props => [success, messageId, errorMessage];
}
