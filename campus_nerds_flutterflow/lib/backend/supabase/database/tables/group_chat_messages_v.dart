import '../database.dart';

class GroupChatMessagesVTable extends SupabaseTable<GroupChatMessagesVRow> {
  @override
  String get tableName => 'group_chat_messages_v';

  @override
  GroupChatMessagesVRow createRow(Map<String, dynamic> data) =>
      GroupChatMessagesVRow(data);
}

class GroupChatMessagesVRow extends SupabaseDataRow {
  GroupChatMessagesVRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => GroupChatMessagesVTable();

  String? get messageId => getField<String>('message_id');
  set messageId(String? value) => setField<String>('message_id', value);

  String? get groupId => getField<String>('group_id');
  set groupId(String? value) => setField<String>('group_id', value);

  String? get type => getField<String>('type');
  set type(String? value) => setField<String>('type', value);

  String? get content => getField<String>('content');
  set content(String? value) => setField<String>('content', value);

  String? get senderUserId => getField<String>('sender_user_id');
  set senderUserId(String? value) => setField<String>('sender_user_id', value);

  String? get senderNickname => getField<String>('sender_nickname');
  set senderNickname(String? value) =>
      setField<String>('sender_nickname', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);
}
