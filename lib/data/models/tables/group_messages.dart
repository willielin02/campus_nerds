import '../database.dart';

class GroupMessagesTable extends SupabaseTable<GroupMessagesRow> {
  @override
  String get tableName => 'group_messages';

  @override
  GroupMessagesRow createRow(Map<String, dynamic> data) =>
      GroupMessagesRow(data);
}

class GroupMessagesRow extends SupabaseDataRow {
  GroupMessagesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => GroupMessagesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get groupId => getField<String>('group_id')!;
  set groupId(String value) => setField<String>('group_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get content => getField<String>('content');
  set content(String? value) => setField<String>('content', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);

  String get type => getField<String>('type')!;
  set type(String value) => setField<String>('type', value);

  dynamic get metadata => getField<dynamic>('metadata')!;
  set metadata(dynamic value) => setField<dynamic>('metadata', value);
}
