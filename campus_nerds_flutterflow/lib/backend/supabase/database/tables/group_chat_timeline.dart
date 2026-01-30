import '../database.dart';

class GroupChatTimelineTable extends SupabaseTable<GroupChatTimelineRow> {
  @override
  String get tableName => 'group_chat_timeline';

  @override
  GroupChatTimelineRow createRow(Map<String, dynamic> data) =>
      GroupChatTimelineRow(data);
}

class GroupChatTimelineRow extends SupabaseDataRow {
  GroupChatTimelineRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => GroupChatTimelineTable();

  String get itemId => getField<String>('item_id')!;
  set itemId(String value) => setField<String>('item_id', value);

  String get groupId => getField<String>('group_id')!;
  set groupId(String value) => setField<String>('group_id', value);

  String get itemType => getField<String>('item_type')!;
  set itemType(String value) => setField<String>('item_type', value);

  DateTime get sortTs => getField<DateTime>('sort_ts')!;
  set sortTs(DateTime value) => setField<DateTime>('sort_ts', value);

  int get sortRank => getField<int>('sort_rank')!;
  set sortRank(int value) => setField<int>('sort_rank', value);

  String? get messageId => getField<String>('message_id');
  set messageId(String? value) => setField<String>('message_id', value);

  String? get messageType => getField<String>('message_type');
  set messageType(String? value) => setField<String>('message_type', value);

  String? get content => getField<String>('content');
  set content(String? value) => setField<String>('content', value);

  String? get senderUserId => getField<String>('sender_user_id');
  set senderUserId(String? value) => setField<String>('sender_user_id', value);

  String? get senderNickname => getField<String>('sender_nickname');
  set senderNickname(String? value) =>
      setField<String>('sender_nickname', value);

  DateTime? get dividerDate => getField<DateTime>('divider_date');
  set dividerDate(DateTime? value) => setField<DateTime>('divider_date', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  String? get dividerLabel => getField<String>('divider_label');
  set dividerLabel(String? value) => setField<String>('divider_label', value);
}
