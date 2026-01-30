import '../database.dart';

class FocusedStudyPlansTable extends SupabaseTable<FocusedStudyPlansRow> {
  @override
  String get tableName => 'focused_study_plans';

  @override
  FocusedStudyPlansRow createRow(Map<String, dynamic> data) =>
      FocusedStudyPlansRow(data);
}

class FocusedStudyPlansRow extends SupabaseDataRow {
  FocusedStudyPlansRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FocusedStudyPlansTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get bookingId => getField<String>('booking_id')!;
  set bookingId(String value) => setField<String>('booking_id', value);

  int get slot => getField<int>('slot')!;
  set slot(int value) => setField<int>('slot', value);

  String get content => getField<String>('content')!;
  set content(String value) => setField<String>('content', value);

  bool get isDone => getField<bool>('is_done')!;
  set isDone(bool value) => setField<bool>('is_done', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);
}
