import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';
import '../../core/utils/app_clock.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';

/// Implementation of ChatRepository using Supabase
class ChatRepositoryImpl implements ChatRepository {
  RealtimeChannel? _channel;
  StreamController<List<ChatMessage>>? _messagesController;

  @override
  Future<ChatTimelinePage> fetchTimelinePage({
    required String groupId,
    DateTime? beforeSortTs,
    int limit = 20,
  }) async {
    try {
      final currentUserId = SupabaseService.currentUserId;

      final response = await SupabaseService.rpc(
        'chat_fetch_timeline_page',
        params: {
          'p_group_id': groupId,
          'p_before_sort_ts': beforeSortTs?.toIso8601String(),
          'p_limit': limit,
        },
      );

      final List<dynamic> data = response as List<dynamic>;

      final messages = data.map((item) {
        final map = item as Map<String, dynamic>;
        return _parseMessage(map, currentUserId);
      }).toList();

      // Sort by sortTs descending (newest first)
      messages.sort((a, b) => b.sortTs.compareTo(a.sortTs));

      final hasMore = messages.length >= limit;
      final oldestSortTs = messages.isNotEmpty ? messages.last.sortTs : null;

      return ChatTimelinePage(
        messages: messages,
        hasMore: hasMore,
        oldestSortTs: oldestSortTs,
      );
    } catch (e) {
      return const ChatTimelinePage(
        messages: [],
        hasMore: false,
      );
    }
  }

  @override
  Future<SendMessageResult> sendMessage({
    required String groupId,
    required String content,
  }) async {
    try {
      final response = await SupabaseService.rpc(
        'chat_send_message',
        params: {
          'p_group_id': groupId,
          'p_content': content,
        },
      );

      if (response != null) {
        final map = response as Map<String, dynamic>;
        return SendMessageResult(
          success: true,
          messageId: map['item_id'] as String?,
        );
      }

      return SendMessageResult.error('發送失敗');
    } catch (e) {
      return SendMessageResult.error('發送失敗，請稍後再試');
    }
  }

  @override
  Future<void> markJoined(String groupId) async {
    try {
      await SupabaseService.rpc(
        'chat_mark_joined',
        params: {
          'p_group_id': groupId,
        },
      );
    } catch (e) {
      // Silently fail - joining notification is not critical
    }
  }

  @override
  Stream<List<ChatMessage>> subscribeToTimeline(String groupId) {
    _messagesController?.close();
    _messagesController = StreamController<List<ChatMessage>>.broadcast();

    final currentUserId = SupabaseService.currentUserId;

    // Create realtime channel
    _channel = SupabaseService.channel('chat:$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'group_chat_timeline',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              final message = _parseMessage(newRecord, currentUserId);
              _messagesController?.add([message]);
            }
          },
        )
        .subscribe();

    return _messagesController!.stream;
  }

  @override
  void unsubscribe() {
    if (_channel != null) {
      SupabaseService.removeChannel(_channel!);
      _channel = null;
    }
    _messagesController?.close();
    _messagesController = null;
  }

  /// Parse a map into a ChatMessage
  ChatMessage _parseMessage(Map<String, dynamic> map, String? currentUserId) {
    final senderUserId = map['sender_user_id'] as String?;

    return ChatMessage(
      itemId: map['item_id'] as String? ?? '',
      groupId: map['group_id'] as String? ?? '',
      itemType: ChatItemType.fromString(map['item_type'] as String? ?? 'message'),
      content: map['content'] as String?,
      senderUserId: senderUserId,
      senderNickname: map['sender_nickname'] as String?,
      senderGender: map['sender_gender'] as String?,
      senderUniversityName: map['sender_university_name'] as String?,
      senderAge: map['sender_age'] as int?,
      sortTs: _parseDateTime(map['sort_ts']) ?? AppClock.now(),
      createdAt: _parseDateTime(map['created_at']) ?? AppClock.now(),
      isMe: senderUserId != null && senderUserId == currentUserId,
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
