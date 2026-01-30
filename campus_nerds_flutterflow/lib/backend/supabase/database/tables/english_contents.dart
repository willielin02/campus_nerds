import '../database.dart';

class EnglishContentsTable extends SupabaseTable<EnglishContentsRow> {
  @override
  String get tableName => 'english_contents';

  @override
  EnglishContentsRow createRow(Map<String, dynamic> data) =>
      EnglishContentsRow(data);
}

class EnglishContentsRow extends SupabaseDataRow {
  EnglishContentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EnglishContentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get contentEn => getField<String>('content_en')!;
  set contentEn(String value) => setField<String>('content_en', value);

  String get contentZh => getField<String>('content_zh')!;
  set contentZh(String value) => setField<String>('content_zh', value);

  String? get note => getField<String>('note');
  set note(String? value) => setField<String>('note', value);

  bool get isActive => getField<bool>('is_active')!;
  set isActive(bool value) => setField<bool>('is_active', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
