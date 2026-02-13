import 'package:equatable/equatable.dart';

import '../../../../domain/entities/chat.dart';

/// Status for chat loading
enum ChatStatus {
  initial,
  loading,
  loaded,
  error,
}

/// State for chat BLoC
class ChatState extends Equatable {
  final ChatStatus status;
  final String? groupId;
  final List<ChatMessage> messages;
  final bool hasMore;
  final DateTime? oldestCreatedAt;
  final String? oldestMessageId;
  final bool isLoadingMore;
  final bool isSending;
  final String? errorMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.groupId,
    this.messages = const [],
    this.hasMore = false,
    this.oldestCreatedAt,
    this.oldestMessageId,
    this.isLoadingMore = false,
    this.isSending = false,
    this.errorMessage,
  });

  /// Check if chat is loaded
  bool get isLoaded => status == ChatStatus.loaded;

  /// Check if there are any messages
  bool get hasMessages => messages.isNotEmpty;

  ChatState copyWith({
    ChatStatus? status,
    String? groupId,
    List<ChatMessage>? messages,
    bool? hasMore,
    DateTime? oldestCreatedAt,
    bool clearOldestCreatedAt = false,
    String? oldestMessageId,
    bool clearOldestMessageId = false,
    bool? isLoadingMore,
    bool? isSending,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      groupId: groupId ?? this.groupId,
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      oldestCreatedAt:
          clearOldestCreatedAt ? null : (oldestCreatedAt ?? this.oldestCreatedAt),
      oldestMessageId:
          clearOldestMessageId ? null : (oldestMessageId ?? this.oldestMessageId),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        groupId,
        messages,
        hasMore,
        oldestCreatedAt,
        oldestMessageId,
        isLoadingMore,
        isSending,
        errorMessage,
      ];
}
