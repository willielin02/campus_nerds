import '../database.dart';

class RecordingSegmentsTable extends SupabaseTable<RecordingSegmentsRow> {
  @override
  String get tableName => 'recording_segments';

  @override
  RecordingSegmentsRow createRow(Map<String, dynamic> data) =>
      RecordingSegmentsRow(data);
}

class RecordingSegmentsRow extends SupabaseDataRow {
  RecordingSegmentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RecordingSegmentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get bookingId => getField<String>('booking_id')!;
  set bookingId(String value) => setField<String>('booking_id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get storagePath => getField<String>('storage_path')!;
  set storagePath(String value) => setField<String>('storage_path', value);

  int get durationSeconds => getField<int>('duration_seconds')!;
  set durationSeconds(int value) => setField<int>('duration_seconds', value);

  int get sequence => getField<int>('sequence')!;
  set sequence(int value) => setField<int>('sequence', value);

  int? get fileSizeBytes => getField<int>('file_size_bytes');
  set fileSizeBytes(int? value) => setField<int>('file_size_bytes', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
