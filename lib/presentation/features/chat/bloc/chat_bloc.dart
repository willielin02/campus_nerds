import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/chat.dart';
import '../../../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// Chat BLoC for managing chat messages
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription<List<ChatMessage>>? _subscription;

  ChatBloc({
    required ChatRepository chatRepository,
  })  : _chatRepository = chatRepository,
        super(const ChatState()) {
    on<ChatInitialize>(_onInitialize);
    on<ChatLoadHistory>(_onLoadHistory);
    on<ChatLoadMore>(_onLoadMore);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatMessagesReceived>(_onMessagesReceived);
    on<ChatClearError>(_onClearError);
    on<ChatMarkAsRead>(_onMarkAsRead);
    on<ChatDispose>(_onDispose);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _chatRepository.unsubscribe();
    return super.close();
  }

  /// Initialize chat for a group
  Future<void> _onInitialize(
    ChatInitialize event,
    Emitter<ChatState> emit,
  ) async {
    // Cancel previous subscription if exists
    _subscription?.cancel();
    _chatRepository.unsubscribe();

    emit(state.copyWith(
      status: ChatStatus.loading,
      groupId: event.groupId,
      messages: [],
      hasMore: false,
      clearOldestCreatedAt: true,
      clearOldestMessageId: true,
    ));

    try {
      // 1. 預載群組成員 profile，確保 Realtime 訊息能顯示正確名字
      await _chatRepository.loadMemberProfiles(event.groupId);

      // 2. Subscribe so we catch the join system message
      _subscription = _chatRepository.subscribeToMessages(event.groupId).listen(
        (messages) {
          add(ChatMessagesReceived(messages));
        },
      );

      // 3. Mark user as joined (inserts system message, caught by subscription)
      await _chatRepository.markJoined(event.groupId);

      // 4. Load initial messages
      final page = await _chatRepository.fetchPage(
        groupId: event.groupId,
      );

      emit(state.copyWith(
        status: ChatStatus.loaded,
        messages: page.messages,
        hasMore: page.hasMore,
        oldestCreatedAt: page.oldestCreatedAt,
        oldestMessageId: page.oldestMessageId,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: '載入聊天訊息失敗',
      ));
    }
  }

  /// Load chat history (refresh)
  Future<void> _onLoadHistory(
    ChatLoadHistory event,
    Emitter<ChatState> emit,
  ) async {
    if (state.groupId == null) return;

    emit(state.copyWith(status: ChatStatus.loading));

    try {
      final page = await _chatRepository.fetchPage(
        groupId: state.groupId!,
      );

      emit(state.copyWith(
        status: ChatStatus.loaded,
        messages: page.messages,
        hasMore: page.hasMore,
        oldestCreatedAt: page.oldestCreatedAt,
        oldestMessageId: page.oldestMessageId,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: '載入聊天訊息失敗',
      ));
    }
  }

  /// Load more (older) messages
  Future<void> _onLoadMore(
    ChatLoadMore event,
    Emitter<ChatState> emit,
  ) async {
    if (state.groupId == null ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.oldestCreatedAt == null) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final page = await _chatRepository.fetchPage(
        groupId: state.groupId!,
        beforeCreatedAt: state.oldestCreatedAt,
        beforeId: state.oldestMessageId,
      );

      // Merge messages (add older messages to the end)
      final mergedMessages = [...state.messages, ...page.messages];

      emit(state.copyWith(
        messages: mergedMessages,
        hasMore: page.hasMore,
        oldestCreatedAt: page.oldestCreatedAt,
        oldestMessageId: page.oldestMessageId,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: '載入更多訊息失敗',
      ));
    }
  }

  /// Send a message
  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state.groupId == null || state.isSending) return;

    final content = event.content.trim();
    if (content.isEmpty) return;

    emit(state.copyWith(isSending: true));

    try {
      final result = await _chatRepository.sendMessage(
        groupId: state.groupId!,
        content: content,
      );

      if (!result.success) {
        emit(state.copyWith(
          isSending: false,
          errorMessage: result.errorMessage ?? '發送失敗',
        ));
      } else {
        emit(state.copyWith(isSending: false));
        // 發送成功後更新已讀時間，避免離開時自己的訊息被算成未讀
        _chatRepository.updateLastRead(state.groupId!).ignore();
      }
    } catch (e) {
      emit(state.copyWith(
        isSending: false,
        errorMessage: '發送失敗，請稍後再試',
      ));
    }
  }

  /// Handle new messages from realtime subscription
  void _onMessagesReceived(
    ChatMessagesReceived event,
    Emitter<ChatState> emit,
  ) {
    final newMessages = event.messages;
    if (newMessages.isEmpty) return;

    // Filter out duplicates and add new messages at the beginning
    final existingIds = state.messages.map((m) => m.messageId).toSet();
    final filteredNew =
        newMessages.where((m) => !existingIds.contains(m.messageId)).toList();

    if (filteredNew.isNotEmpty) {
      final mergedMessages = [...filteredNew, ...state.messages];
      // Sort by createdAt descending (newest first)
      mergedMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      emit(state.copyWith(messages: mergedMessages));
    }
  }

  /// Clear error state
  void _onClearError(
    ChatClearError event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(errorMessage: null));
  }

  /// 標記已讀（使用者切換到聊天室 tab 時呼叫）
  Future<void> _onMarkAsRead(
    ChatMarkAsRead event,
    Emitter<ChatState> emit,
  ) async {
    if (state.groupId != null) {
      try {
        await _chatRepository.updateLastRead(state.groupId!);
      } catch (_) {}
    }
  }

  /// Dispose/cleanup chat
  Future<void> _onDispose(
    ChatDispose event,
    Emitter<ChatState> emit,
  ) async {
    _subscription?.cancel();
    _chatRepository.unsubscribe();

    emit(const ChatState());
  }
}
