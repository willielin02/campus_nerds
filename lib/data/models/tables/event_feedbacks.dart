import '../database.dart';

class EventFeedbacksTable extends SupabaseTable<EventFeedbacksRow> {
  @override
  String get tableName => 'event_feedbacks';

  @override
  EventFeedbacksRow createRow(Map<String, dynamic> data) =>
      EventFeedbacksRow(data);
}

class EventFeedbacksRow extends SupabaseDataRow {
  EventFeedbacksRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EventFeedbacksTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get groupId => getField<String>('group_id')!;
  set groupId(String value) => setField<String>('group_id', value);

  String get memberId => getField<String>('member_id')!;
  set memberId(String value) => setField<String>('member_id', value);

  int get venueRating => getField<int>('venue_rating')!;
  set venueRating(int value) => setField<int>('venue_rating', value);

  int get flowRating => getField<int>('flow_rating')!;
  set flowRating(int value) => setField<int>('flow_rating', value);

  int get vibeRating => getField<int>('vibe_rating')!;
  set vibeRating(int value) => setField<int>('vibe_rating', value);

  String? get comment => getField<String>('comment');
  set comment(String? value) => setField<String>('comment', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);
}
