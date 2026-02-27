import '../database.dart';

class LearningReportsTable extends SupabaseTable<LearningReportsRow> {
  @override
  String get tableName => 'learning_reports';

  @override
  LearningReportsRow createRow(Map<String, dynamic> data) =>
      LearningReportsRow(data);
}

class LearningReportsRow extends SupabaseDataRow {
  LearningReportsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => LearningReportsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get bookingId => getField<String>('booking_id')!;
  set bookingId(String value) => setField<String>('booking_id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  String? get transcript => getField<String>('transcript');
  set transcript(String? value) => setField<String>('transcript', value);

  /// analysis is stored as JSONB — returns Map<String, dynamic>
  Map<String, dynamic>? get analysis {
    final raw = data['analysis'];
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  String? get errorMessage => getField<String>('error_message');
  set errorMessage(String? value) =>
      setField<String>('error_message', value);

  int get totalDurationSeconds => getField<int>('total_duration_seconds') ?? 0;
  set totalDurationSeconds(int value) =>
      setField<int>('total_duration_seconds', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);
}
