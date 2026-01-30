import '../database.dart';

class SchoolEmailVerificationsTable
    extends SupabaseTable<SchoolEmailVerificationsRow> {
  @override
  String get tableName => 'school_email_verifications';

  @override
  SchoolEmailVerificationsRow createRow(Map<String, dynamic> data) =>
      SchoolEmailVerificationsRow(data);
}

class SchoolEmailVerificationsRow extends SupabaseDataRow {
  SchoolEmailVerificationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => SchoolEmailVerificationsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get schoolEmail => getField<String>('school_email')!;
  set schoolEmail(String value) => setField<String>('school_email', value);

  String get codeHash => getField<String>('code_hash')!;
  set codeHash(String value) => setField<String>('code_hash', value);

  String get salt => getField<String>('salt')!;
  set salt(String value) => setField<String>('salt', value);

  DateTime get expiresAt => getField<DateTime>('expires_at')!;
  set expiresAt(DateTime value) => setField<DateTime>('expires_at', value);

  DateTime? get consumedAt => getField<DateTime>('consumed_at');
  set consumedAt(DateTime? value) => setField<DateTime>('consumed_at', value);

  int get failCount => getField<int>('fail_count')!;
  set failCount(int value) => setField<int>('fail_count', value);

  int get sentCount => getField<int>('sent_count')!;
  set sentCount(int value) => setField<int>('sent_count', value);

  DateTime get lastSentAt => getField<DateTime>('last_sent_at')!;
  set lastSentAt(DateTime value) => setField<DateTime>('last_sent_at', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
