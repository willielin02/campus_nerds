import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';
import '../../core/utils/app_clock.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';

/// Cached member profile for enriching Realtime messages
class _MemberProfile {
  final String? nickname;
  final String? gender;
  final String? universityName;
  final int? age;

  const _MemberProfile({
    this.nickname,
    this.gender,
    this.universityName,
    this.age,
  });
}

/// Implementation of ChatRepository using Supabase
class ChatRepositoryImpl implements ChatRepository {
  RealtimeChannel? _channel;
  StreamController<List<ChatMessage>>? _messagesController;
  final Map<String, _MemberProfile> _memberProfileCache = {};

  @override
  Future<ChatTimelinePage> fetchPage({
    required String groupId,
    DateTime? beforeCreatedAt,
    String? beforeId,
    int limit = 20,
  }) async {
    final currentUserId = SupabaseService.currentUserId;

    final response = await SupabaseService.rpc(
      'chat_fetch_page',
      params: {
        'p_group_id': groupId,
        'p_before_created_at': beforeCreatedAt?.toIso8601String(),
        'p_before_id': beforeId,
        'p_limit': limit,
      },
    );

    final List<dynamic> data = response as List<dynamic>;

    final messages = data.map((item) {
      final map = item as Map<String, dynamic>;
      return _parseRpcMessage(map, currentUserId);
    }).toList();

    // Sort by createdAt descending (newest first)
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final hasMore = messages.length >= limit;
    final oldestCreatedAt =
        messages.isNotEmpty ? messages.last.createdAt : null;
    final oldestMessageId =
        messages.isNotEmpty ? messages.last.messageId : null;

    return ChatTimelinePage(
      messages: messages,
      hasMore: hasMore,
      oldestCreatedAt: oldestCreatedAt,
      oldestMessageId: oldestMessageId,
    );
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

      if (response is List && response.isNotEmpty) {
        final map = response.first as Map<String, dynamic>;
        return SendMessageResult(
          success: true,
          messageId: map['message_id'] as String?,
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
  Future<void> loadMemberProfiles(String groupId) async {
    try {
      // 透過 SECURITY DEFINER RPC 取得群組成員 profile（繞過 RLS）
      final response = await SupabaseService.rpc(
        'chat_get_member_profiles',
        params: {'p_group_id': groupId},
      );

      final List<dynamic> data = response as List<dynamic>;
      for (final row in data) {
        final map = row as Map<String, dynamic>;
        final userId = map['user_id'] as String?;
        if (userId != null) {
          _memberProfileCache[userId] = _MemberProfile(
            nickname: map['nickname'] as String?,
            gender: map['gender'] as String?,
            universityName: map['university_name'] as String?,
            age: map['age'] as int?,
          );
        }
      }
    } catch (_) {
      // 非關鍵操作，失敗不影響聊天功能
    }
  }

  @override
  Stream<List<ChatMessage>> subscribeToMessages(String groupId) {
    _messagesController?.close();
    _messagesController = StreamController<List<ChatMessage>>.broadcast();

    final currentUserId = SupabaseService.currentUserId;

    // Subscribe to group_messages table directly (not group_chat_timeline)
    _channel = SupabaseService.channel('chat:$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'group_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              final message =
                  _parseRealtimeMessage(newRecord, currentUserId);
              _messagesController?.add([message]);
            }
          },
        )
        .subscribe();

    return _messagesController!.stream;
  }

  @override
  Future<void> updateLastRead(String groupId) async {
    try {
      await SupabaseService.rpc(
        'chat_update_last_read',
        params: {'p_group_id': groupId},
      );
    } catch (e) {
      // Silently fail - updating last read is not critical
    }
  }

  @override
  void unsubscribe() {
    if (_channel != null) {
      SupabaseService.removeChannel(_channel!);
      _channel = null;
    }
    _messagesController?.close();
    _messagesController = null;
    _memberProfileCache.clear();
  }

  /// Parse a message from RPC response (has full profile data)
  ChatMessage _parseRpcMessage(
      Map<String, dynamic> map, String? currentUserId) {
    final senderUserId = map['sender_user_id'] as String?;

    // Cache profile data for Realtime enrichment
    if (senderUserId != null &&
        !_memberProfileCache.containsKey(senderUserId)) {
      _memberProfileCache[senderUserId] = _MemberProfile(
        nickname: map['sender_nickname'] as String?,
        gender: map['sender_gender'] as String?,
        universityName: map['sender_university_name'] as String?,
        age: map['sender_age'] as int?,
      );
    }

    return ChatMessage(
      messageId: (map['message_id'] as String?) ?? '',
      groupId: (map['group_id'] as String?) ?? '',
      itemType: _resolveItemType(map),
      content: map['content'] as String?,
      senderUserId: senderUserId,
      senderNickname: map['sender_nickname'] as String?,
      senderGender: map['sender_gender'] as String?,
      senderUniversityName: map['sender_university_name'] as String?,
      senderAge: map['sender_age'] as int?,
      createdAt: _parseDateTime(map['created_at']) ?? AppClock.now(),
      isMe: senderUserId != null && senderUserId == currentUserId,
    );
  }

  /// Parse a message from Realtime payload (lacks profile data, use cache)
  ChatMessage _parseRealtimeMessage(
      Map<String, dynamic> record, String? currentUserId) {
    final senderUserId = record['user_id'] as String?;
    final isMe = senderUserId != null && senderUserId == currentUserId;

    // Look up profile from cache
    final profile =
        senderUserId != null ? _memberProfileCache[senderUserId] : null;

    return ChatMessage(
      messageId: (record['id'] as String?) ?? '',
      groupId: (record['group_id'] as String?) ?? '',
      itemType: _resolveItemType(record),
      content: record['content'] as String?,
      senderUserId: senderUserId,
      senderNickname: profile?.nickname,
      senderGender: profile?.gender,
      senderUniversityName: profile?.universityName,
      senderAge: profile?.age,
      createdAt: _parseDateTime(record['created_at']) ?? AppClock.now(),
      isMe: isMe,
    );
  }

  /// Resolve ChatItemType from message type + metadata.
  /// RPC returns 'message_type', Realtime returns 'type'.
  ChatItemType _resolveItemType(Map<String, dynamic> map) {
    final messageType =
        (map['message_type'] ?? map['type']) as String?;
    if (messageType != 'system') return ChatItemType.message;

    final metadata = map['metadata'];
    if (metadata is Map<String, dynamic>) {
      switch (metadata['event'] as String?) {
        case 'member_joined':
          return ChatItemType.systemJoined;
        case 'event_started':
          return ChatItemType.systemStarted;
        case 'event_ended':
          return ChatItemType.systemEnded;
      }
    }
    return ChatItemType.systemJoined;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
