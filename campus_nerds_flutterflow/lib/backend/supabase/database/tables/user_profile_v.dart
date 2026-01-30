import '../database.dart';

class UserProfileVTable extends SupabaseTable<UserProfileVRow> {
  @override
  String get tableName => 'user_profile_v';

  @override
  UserProfileVRow createRow(Map<String, dynamic> data) => UserProfileVRow(data);
}

class UserProfileVRow extends SupabaseDataRow {
  UserProfileVRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserProfileVTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get gender => getField<String>('gender');
  set gender(String? value) => setField<String>('gender', value);

  DateTime? get birthday => getField<DateTime>('birthday');
  set birthday(DateTime? value) => setField<DateTime>('birthday', value);

  int? get age => getField<int>('age');
  set age(int? value) => setField<int>('age', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get schoolEmail => getField<String>('school_email');
  set schoolEmail(String? value) => setField<String>('school_email', value);

  String? get schoolEmailStatus => getField<String>('school_email_status');
  set schoolEmailStatus(String? value) =>
      setField<String>('school_email_status', value);

  DateTime? get schoolEmailVerifiedAt =>
      getField<DateTime>('school_email_verified_at');
  set schoolEmailVerifiedAt(DateTime? value) =>
      setField<DateTime>('school_email_verified_at', value);

  String? get universityId => getField<String>('university_id');
  set universityId(String? value) => setField<String>('university_id', value);

  String? get universityName => getField<String>('university_name');
  set universityName(String? value) =>
      setField<String>('university_name', value);

  String? get universityCode => getField<String>('university_code');
  set universityCode(String? value) =>
      setField<String>('university_code', value);

  String? get nickname => getField<String>('nickname');
  set nickname(String? value) => setField<String>('nickname', value);

  String? get os => getField<String>('os');
  set os(String? value) => setField<String>('os', value);

  int? get academicRank => getField<int>('academic_rank');
  set academicRank(int? value) => setField<int>('academic_rank', value);
}
