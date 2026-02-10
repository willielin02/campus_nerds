import '../database.dart';

class GroupsTable extends SupabaseTable<GroupsRow> {
  @override
  String get tableName => 'groups';

  @override
  GroupsRow createRow(Map<String, dynamic> data) => GroupsRow(data);
}

class GroupsRow extends SupabaseDataRow {
  GroupsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => GroupsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get eventId => getField<String>('event_id')!;
  set eventId(String value) => setField<String>('event_id', value);

  String? get venueId => getField<String>('venue_id');
  set venueId(String? value) => setField<String>('venue_id', value);

  int get maxSize => getField<int>('max_size')!;
  set maxSize(int value) => setField<int>('max_size', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);

  DateTime? get chatOpenAt => getField<DateTime>('chat_open_at');
  set chatOpenAt(DateTime? value) => setField<DateTime>('chat_open_at', value);

  DateTime? get feedbackSentAt => getField<DateTime>('feedback_sent_at');
  set feedbackSentAt(DateTime? value) =>
      setField<DateTime>('feedback_sent_at', value);

  DateTime? get goalCloseAt => getField<DateTime>('goal_close_at');
  set goalCloseAt(DateTime? value) =>
      setField<DateTime>('goal_close_at', value);

}
