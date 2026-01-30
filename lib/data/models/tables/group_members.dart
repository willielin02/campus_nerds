import '../database.dart';

class GroupMembersTable extends SupabaseTable<GroupMembersRow> {
  @override
  String get tableName => 'group_members';

  @override
  GroupMembersRow createRow(Map<String, dynamic> data) => GroupMembersRow(data);
}

class GroupMembersRow extends SupabaseDataRow {
  GroupMembersRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => GroupMembersTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get groupId => getField<String>('group_id')!;
  set groupId(String value) => setField<String>('group_id', value);

  String get bookingId => getField<String>('booking_id')!;
  set bookingId(String value) => setField<String>('booking_id', value);

  String get eventId => getField<String>('event_id')!;
  set eventId(String value) => setField<String>('event_id', value);

  DateTime get joinedAt => getField<DateTime>('joined_at')!;
  set joinedAt(DateTime value) => setField<DateTime>('joined_at', value);

  DateTime? get leftAt => getField<DateTime>('left_at');
  set leftAt(DateTime? value) => setField<DateTime>('left_at', value);

  DateTime? get chatJoinedAt => getField<DateTime>('chat_joined_at');
  set chatJoinedAt(DateTime? value) =>
      setField<DateTime>('chat_joined_at', value);
}
