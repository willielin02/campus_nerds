import '../database.dart';

class EventsTable extends SupabaseTable<EventsRow> {
  @override
  String get tableName => 'events';

  @override
  EventsRow createRow(Map<String, dynamic> data) => EventsRow(data);
}

class EventsRow extends SupabaseDataRow {
  EventsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EventsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get universityId => getField<String>('university_id');
  set universityId(String? value) => setField<String>('university_id', value);

  String get cityId => getField<String>('city_id')!;
  set cityId(String value) => setField<String>('city_id', value);

  String get category => getField<String>('category')!;
  set category(String value) => setField<String>('category', value);

  DateTime get eventDate => getField<DateTime>('event_date')!;
  set eventDate(DateTime value) => setField<DateTime>('event_date', value);

  String get timeSlot => getField<String>('time_slot')!;
  set timeSlot(String value) => setField<String>('time_slot', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  DateTime get signupDeadlineAt => getField<DateTime>('signup_deadline_at')!;
  set signupDeadlineAt(DateTime value) =>
      setField<DateTime>('signup_deadline_at', value);

  DateTime? get notifySentAt => getField<DateTime>('notify_sent_at');
  set notifySentAt(DateTime? value) =>
      setField<DateTime>('notify_sent_at', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);

  DateTime get signupOpenAt => getField<DateTime>('signup_open_at')!;
  set signupOpenAt(DateTime value) =>
      setField<DateTime>('signup_open_at', value);

  String get locationDetail => getField<String>('location_detail')!;
  set locationDetail(String value) =>
      setField<String>('location_detail', value);

  DateTime? get notifyDeadlineAt => getField<DateTime>('notify_deadline_at');
  set notifyDeadlineAt(DateTime? value) =>
      setField<DateTime>('notify_deadline_at', value);
}
