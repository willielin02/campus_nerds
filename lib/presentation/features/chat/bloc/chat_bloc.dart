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
      clearOldestSortTs: true,
    ));

    try {
      // Mark user as joined
      await _chatRepository.markJoined(event.groupId);

      // Load initial messages
      final page = await _chatRepository.fetchTimelinePage(
        groupId: event.groupId,
      );

      // Subscribe to realtime updates
      _subscription = _chatRepository.subscribeToTimeline(event.groupId).listen(
        (messages) {
          add(ChatMessagesReceived(messages));
        },
      );

      emit(state.copyWith(
        status: ChatStatus.loaded,
        messages: page.messages,
        hasMore: page.hasMore,
        oldestSortTs: page.oldestSortTs,
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
      final page = await _chatRepository.fetchTimelinePage(
        groupId: state.groupId!,
      );

      emit(state.copyWith(
        status: ChatStatus.loaded,
        messages: page.messages,
        hasMore: page.hasMore,
        oldestSortTs: page.oldestSortTs,
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
        state.oldestSortTs == null) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    try {
      final page = await _chatRepository.fetchTimelinePage(
        groupId: state.groupId!,
        beforeSortTs: state.oldestSortTs,
      );

      // Merge messages (add older messages to the end)
      final mergedMessages = [...state.messages, ...page.messages];

      emit(state.copyWith(
        messages: mergedMessages,
        hasMore: page.hasMore,
        oldestSortTs: page.oldestSortTs,
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
    final existingIds = state.messages.map((m) => m.itemId).toSet();
    final filteredNew =
        newMessages.where((m) => !existingIds.contains(m.itemId)).toList();

    if (filteredNew.isNotEmpty) {
      final mergedMessages = [...filteredNew, ...state.messages];
      // Sort by sortTs descending (newest first)
      mergedMessages.sort((a, b) => b.sortTs.compareTo(a.sortTs));

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
