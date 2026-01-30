// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ChatTimelineItemDTStruct extends BaseStruct {
  ChatTimelineItemDTStruct({
    String? id,
    String? groupId,
    String? itemType,
    String? content,
    String? senderUserId,
    String? senderNickname,
    DateTime? dividerDate,
    String? dividerLabel,
    DateTime? sortTs,
    int? sortRank,
    String? messageId,
    DateTime? createdAt,
  })  : _id = id,
        _groupId = groupId,
        _itemType = itemType,
        _content = content,
        _senderUserId = senderUserId,
        _senderNickname = senderNickname,
        _dividerDate = dividerDate,
        _dividerLabel = dividerLabel,
        _sortTs = sortTs,
        _sortRank = sortRank,
        _messageId = messageId,
        _createdAt = createdAt;

  // "id" field.
  String? _id;
  String get id => _id ?? '';
  set id(String? val) => _id = val;

  bool hasId() => _id != null;

  // "group_id" field.
  String? _groupId;
  String get groupId => _groupId ?? '';
  set groupId(String? val) => _groupId = val;

  bool hasGroupId() => _groupId != null;

  // "item_type" field.
  String? _itemType;
  String get itemType => _itemType ?? '';
  set itemType(String? val) => _itemType = val;

  bool hasItemType() => _itemType != null;

  // "content" field.
  String? _content;
  String get content => _content ?? '';
  set content(String? val) => _content = val;

  bool hasContent() => _content != null;

  // "sender_user_id" field.
  String? _senderUserId;
  String get senderUserId => _senderUserId ?? '';
  set senderUserId(String? val) => _senderUserId = val;

  bool hasSenderUserId() => _senderUserId != null;

  // "sender_nickname" field.
  String? _senderNickname;
  String get senderNickname => _senderNickname ?? '';
  set senderNickname(String? val) => _senderNickname = val;

  bool hasSenderNickname() => _senderNickname != null;

  // "divider_date" field.
  DateTime? _dividerDate;
  DateTime? get dividerDate => _dividerDate;
  set dividerDate(DateTime? val) => _dividerDate = val;

  bool hasDividerDate() => _dividerDate != null;

  // "divider_label" field.
  String? _dividerLabel;
  String get dividerLabel => _dividerLabel ?? '';
  set dividerLabel(String? val) => _dividerLabel = val;

  bool hasDividerLabel() => _dividerLabel != null;

  // "sort_ts" field.
  DateTime? _sortTs;
  DateTime? get sortTs => _sortTs;
  set sortTs(DateTime? val) => _sortTs = val;

  bool hasSortTs() => _sortTs != null;

  // "sort_rank" field.
  int? _sortRank;
  int get sortRank => _sortRank ?? 0;
  set sortRank(int? val) => _sortRank = val;

  void incrementSortRank(int amount) => sortRank = sortRank + amount;

  bool hasSortRank() => _sortRank != null;

  // "message_id" field.
  String? _messageId;
  String get messageId => _messageId ?? '';
  set messageId(String? val) => _messageId = val;

  bool hasMessageId() => _messageId != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  set createdAt(DateTime? val) => _createdAt = val;

  bool hasCreatedAt() => _createdAt != null;

  static ChatTimelineItemDTStruct fromMap(Map<String, dynamic> data) =>
      ChatTimelineItemDTStruct(
        id: data['id'] as String?,
        groupId: data['group_id'] as String?,
        itemType: data['item_type'] as String?,
        content: data['content'] as String?,
        senderUserId: data['sender_user_id'] as String?,
        senderNickname: data['sender_nickname'] as String?,
        dividerDate: data['divider_date'] as DateTime?,
        dividerLabel: data['divider_label'] as String?,
        sortTs: data['sort_ts'] as DateTime?,
        sortRank: castToType<int>(data['sort_rank']),
        messageId: data['message_id'] as String?,
        createdAt: data['created_at'] as DateTime?,
      );

  static ChatTimelineItemDTStruct? maybeFromMap(dynamic data) => data is Map
      ? ChatTimelineItemDTStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'id': _id,
        'group_id': _groupId,
        'item_type': _itemType,
        'content': _content,
        'sender_user_id': _senderUserId,
        'sender_nickname': _senderNickname,
        'divider_date': _dividerDate,
        'divider_label': _dividerLabel,
        'sort_ts': _sortTs,
        'sort_rank': _sortRank,
        'message_id': _messageId,
        'created_at': _createdAt,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'id': serializeParam(
          _id,
          ParamType.String,
        ),
        'group_id': serializeParam(
          _groupId,
          ParamType.String,
        ),
        'item_type': serializeParam(
          _itemType,
          ParamType.String,
        ),
        'content': serializeParam(
          _content,
          ParamType.String,
        ),
        'sender_user_id': serializeParam(
          _senderUserId,
          ParamType.String,
        ),
        'sender_nickname': serializeParam(
          _senderNickname,
          ParamType.String,
        ),
        'divider_date': serializeParam(
          _dividerDate,
          ParamType.DateTime,
        ),
        'divider_label': serializeParam(
          _dividerLabel,
          ParamType.String,
        ),
        'sort_ts': serializeParam(
          _sortTs,
          ParamType.DateTime,
        ),
        'sort_rank': serializeParam(
          _sortRank,
          ParamType.int,
        ),
        'message_id': serializeParam(
          _messageId,
          ParamType.String,
        ),
        'created_at': serializeParam(
          _createdAt,
          ParamType.DateTime,
        ),
      }.withoutNulls;

  static ChatTimelineItemDTStruct fromSerializableMap(
          Map<String, dynamic> data) =>
      ChatTimelineItemDTStruct(
        id: deserializeParam(
          data['id'],
          ParamType.String,
          false,
        ),
        groupId: deserializeParam(
          data['group_id'],
          ParamType.String,
          false,
        ),
        itemType: deserializeParam(
          data['item_type'],
          ParamType.String,
          false,
        ),
        content: deserializeParam(
          data['content'],
          ParamType.String,
          false,
        ),
        senderUserId: deserializeParam(
          data['sender_user_id'],
          ParamType.String,
          false,
        ),
        senderNickname: deserializeParam(
          data['sender_nickname'],
          ParamType.String,
          false,
        ),
        dividerDate: deserializeParam(
          data['divider_date'],
          ParamType.DateTime,
          false,
        ),
        dividerLabel: deserializeParam(
          data['divider_label'],
          ParamType.String,
          false,
        ),
        sortTs: deserializeParam(
          data['sort_ts'],
          ParamType.DateTime,
          false,
        ),
        sortRank: deserializeParam(
          data['sort_rank'],
          ParamType.int,
          false,
        ),
        messageId: deserializeParam(
          data['message_id'],
          ParamType.String,
          false,
        ),
        createdAt: deserializeParam(
          data['created_at'],
          ParamType.DateTime,
          false,
        ),
      );

  @override
  String toString() => 'ChatTimelineItemDTStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ChatTimelineItemDTStruct &&
        id == other.id &&
        groupId == other.groupId &&
        itemType == other.itemType &&
        content == other.content &&
        senderUserId == other.senderUserId &&
        senderNickname == other.senderNickname &&
        dividerDate == other.dividerDate &&
        dividerLabel == other.dividerLabel &&
        sortTs == other.sortTs &&
        sortRank == other.sortRank &&
        messageId == other.messageId &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode => const ListEquality().hash([
        id,
        groupId,
        itemType,
        content,
        senderUserId,
        senderNickname,
        dividerDate,
        dividerLabel,
        sortTs,
        sortRank,
        messageId,
        createdAt
      ]);
}

ChatTimelineItemDTStruct createChatTimelineItemDTStruct({
  String? id,
  String? groupId,
  String? itemType,
  String? content,
  String? senderUserId,
  String? senderNickname,
  DateTime? dividerDate,
  String? dividerLabel,
  DateTime? sortTs,
  int? sortRank,
  String? messageId,
  DateTime? createdAt,
}) =>
    ChatTimelineItemDTStruct(
      id: id,
      groupId: groupId,
      itemType: itemType,
      content: content,
      senderUserId: senderUserId,
      senderNickname: senderNickname,
      dividerDate: dividerDate,
      dividerLabel: dividerLabel,
      sortTs: sortTs,
      sortRank: sortRank,
      messageId: messageId,
      createdAt: createdAt,
    );
