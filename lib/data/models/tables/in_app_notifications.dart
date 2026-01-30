import '../database.dart';

class InAppNotificationsTable extends SupabaseTable<InAppNotificationsRow> {
  @override
  String get tableName => 'in_app_notifications';

  @override
  InAppNotificationsRow createRow(Map<String, dynamic> data) =>
      InAppNotificationsRow(data);
}

class InAppNotificationsRow extends SupabaseDataRow {
  InAppNotificationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => InAppNotificationsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String? get bookingId => getField<String>('booking_id');
  set bookingId(String? value) => setField<String>('booking_id', value);

  String get eventId => getField<String>('event_id')!;
  set eventId(String value) => setField<String>('event_id', value);

  String? get groupId => getField<String>('group_id');
  set groupId(String? value) => setField<String>('group_id', value);

  String get type => getField<String>('type')!;
  set type(String value) => setField<String>('type', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String get body => getField<String>('body')!;
  set body(String value) => setField<String>('body', value);

  dynamic get dataField => getField<dynamic>('data')!;
  set dataField(dynamic value) => setField<dynamic>('data', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
