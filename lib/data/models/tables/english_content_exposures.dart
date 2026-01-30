import '../database.dart';

class EnglishContentExposuresTable
    extends SupabaseTable<EnglishContentExposuresRow> {
  @override
  String get tableName => 'english_content_exposures';

  @override
  EnglishContentExposuresRow createRow(Map<String, dynamic> data) =>
      EnglishContentExposuresRow(data);
}

class EnglishContentExposuresRow extends SupabaseDataRow {
  EnglishContentExposuresRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EnglishContentExposuresTable();

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get contentId => getField<String>('content_id')!;
  set contentId(String value) => setField<String>('content_id', value);

  DateTime get firstSeenAt => getField<DateTime>('first_seen_at')!;
  set firstSeenAt(DateTime value) => setField<DateTime>('first_seen_at', value);

  String? get firstSeenGroupId => getField<String>('first_seen_group_id');
  set firstSeenGroupId(String? value) =>
      setField<String>('first_seen_group_id', value);
}
