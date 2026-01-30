import '../database.dart';

class UserCurrentUniversityVTable
    extends SupabaseTable<UserCurrentUniversityVRow> {
  @override
  String get tableName => 'user_current_university_v';

  @override
  UserCurrentUniversityVRow createRow(Map<String, dynamic> data) =>
      UserCurrentUniversityVRow(data);
}

class UserCurrentUniversityVRow extends SupabaseDataRow {
  UserCurrentUniversityVRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserCurrentUniversityVTable();

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get schoolEmail => getField<String>('school_email');
  set schoolEmail(String? value) => setField<String>('school_email', value);

  String? get universityId => getField<String>('university_id');
  set universityId(String? value) => setField<String>('university_id', value);

  String? get universityName => getField<String>('university_name');
  set universityName(String? value) =>
      setField<String>('university_name', value);

  String? get universityCode => getField<String>('university_code');
  set universityCode(String? value) =>
      setField<String>('university_code', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  DateTime? get verifiedAt => getField<DateTime>('verified_at');
  set verifiedAt(DateTime? value) => setField<DateTime>('verified_at', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get academicRank => getField<int>('academic_rank');
  set academicRank(int? value) => setField<int>('academic_rank', value);
}
