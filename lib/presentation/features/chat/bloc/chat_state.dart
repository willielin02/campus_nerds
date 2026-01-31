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
  final DateTime? oldestSortTs;
  final bool isLoadingMore;
  final bool isSending;
  final String? errorMessage;

  const ChatState({
    this.status = ChatStatus.initial,
    this.groupId,
    this.messages = const [],
    this.hasMore = false,
    this.oldestSortTs,
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
    DateTime? oldestSortTs,
    bool clearOldestSortTs = false,
    bool? isLoadingMore,
    bool? isSending,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      groupId: groupId ?? this.groupId,
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      oldestSortTs: clearOldestSortTs ? null : (oldestSortTs ?? this.oldestSortTs),
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
        oldestSortTs,
        isLoadingMore,
        isSending,
        errorMessage,
      ];
}
