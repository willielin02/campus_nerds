import '../database.dart';

class UniversitiesTable extends SupabaseTable<UniversitiesRow> {
  @override
  String get tableName => 'universities';

  @override
  UniversitiesRow createRow(Map<String, dynamic> data) => UniversitiesRow(data);
}

class UniversitiesRow extends SupabaseDataRow {
  UniversitiesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UniversitiesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get cityId => getField<String>('city_id')!;
  set cityId(String value) => setField<String>('city_id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String? get shortName => getField<String>('short_name');
  set shortName(String? value) => setField<String>('short_name', value);

  String get slug => getField<String>('slug')!;
  set slug(String value) => setField<String>('slug', value);

  String get code => getField<String>('code')!;
  set code(String value) => setField<String>('code', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);

  int? get academicRank => getField<int>('academic_rank');
  set academicRank(int? value) => setField<int>('academic_rank', value);
}
