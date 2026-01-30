import '../database.dart';

class UniversityEmailDomainsTable
    extends SupabaseTable<UniversityEmailDomainsRow> {
  @override
  String get tableName => 'university_email_domains';

  @override
  UniversityEmailDomainsRow createRow(Map<String, dynamic> data) =>
      UniversityEmailDomainsRow(data);
}

class UniversityEmailDomainsRow extends SupabaseDataRow {
  UniversityEmailDomainsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UniversityEmailDomainsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get universityId => getField<String>('university_id')!;
  set universityId(String value) => setField<String>('university_id', value);

  String get domain => getField<String>('domain')!;
  set domain(String value) => setField<String>('domain', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);
}
