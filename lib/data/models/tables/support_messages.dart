import '../database.dart';

class SupportMessagesTable extends SupabaseTable<SupportMessagesRow> {
  @override
  String get tableName => 'support_messages';

  @override
  SupportMessagesRow createRow(Map<String, dynamic> data) =>
      SupportMessagesRow(data);
}

class SupportMessagesRow extends SupabaseDataRow {
  SupportMessagesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SupportMessagesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get ticketId => getField<String>('ticket_id')!;
  set ticketId(String value) => setField<String>('ticket_id', value);

  String get senderType => getField<String>('sender_type')!;
  set senderType(String value) => setField<String>('sender_type', value);

  String get senderId => getField<String>('sender_id')!;
  set senderId(String value) => setField<String>('sender_id', value);

  String? get content => getField<String>('content');
  set content(String? value) => setField<String>('content', value);

  String? get imagePath => getField<String>('image_path');
  set imagePath(String? value) => setField<String>('image_path', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
