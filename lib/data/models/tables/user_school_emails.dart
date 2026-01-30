import '../database.dart';

class UserSchoolEmailsTable extends SupabaseTable<UserSchoolEmailsRow> {
  @override
  String get tableName => 'user_school_emails';

  @override
  UserSchoolEmailsRow createRow(Map<String, dynamic> data) =>
      UserSchoolEmailsRow(data);
}

class UserSchoolEmailsRow extends SupabaseDataRow {
  UserSchoolEmailsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserSchoolEmailsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get schoolEmail => getField<String>('school_email')!;
  set schoolEmail(String value) => setField<String>('school_email', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  DateTime? get verifiedAt => getField<DateTime>('verified_at');
  set verifiedAt(DateTime? value) => setField<DateTime>('verified_at', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);

  bool get isActive => getField<bool>('is_active')!;
  set isActive(bool value) => setField<bool>('is_active', value);

  DateTime? get releasedAt => getField<DateTime>('released_at');
  set releasedAt(DateTime? value) => setField<DateTime>('released_at', value);

  String? get releasedReason => getField<String>('released_reason');
  set releasedReason(String? value) =>
      setField<String>('released_reason', value);

  String? get releasedBy => getField<String>('released_by');
  set releasedBy(String? value) => setField<String>('released_by', value);
}
