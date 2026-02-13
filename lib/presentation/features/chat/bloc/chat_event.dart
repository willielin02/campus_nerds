import 'package:equatable/equatable.dart';

import '../../../../domain/entities/chat.dart';

/// Base class for chat events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize chat for a group
class ChatInitialize extends ChatEvent {
  final String groupId;

  const ChatInitialize(this.groupId);

  @override
  List<Object?> get props => [groupId];
}

/// Event to load chat history
class ChatLoadHistory extends ChatEvent {
  const ChatLoadHistory();
}

/// Event to load more (older) messages
class ChatLoadMore extends ChatEvent {
  const ChatLoadMore();
}

/// Event to send a message
class ChatSendMessage extends ChatEvent {
  final String content;

  const ChatSendMessage(this.content);

  @override
  List<Object?> get props => [content];
}

/// Event when new messages are received from realtime
class ChatMessagesReceived extends ChatEvent {
  final List<ChatMessage> messages;

  const ChatMessagesReceived(this.messages);

  @override
  List<Object?> get props => [messages];
}

/// Event to clear error state
class ChatClearError extends ChatEvent {
  const ChatClearError();
}

/// Event to mark messages as read (user switched to chat tab)
class ChatMarkAsRead extends ChatEvent {
  const ChatMarkAsRead();
}

/// Event to dispose/cleanup chat
class ChatDispose extends ChatEvent {
  const ChatDispose();
}
