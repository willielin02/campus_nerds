import '../database.dart';

class UsersTable extends SupabaseTable<UsersRow> {
  @override
  String get tableName => 'users';

  @override
  UsersRow createRow(Map<String, dynamic> data) => UsersRow(data);
}

class UsersRow extends SupabaseDataRow {
  UsersRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UsersTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get gender => getField<String>('gender');
  set gender(String? value) => setField<String>('gender', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);

  String? get fbUserId => getField<String>('fb_user_id');
  set fbUserId(String? value) => setField<String>('fb_user_id', value);

  DateTime? get fbConnectedAt => getField<DateTime>('fb_connected_at');
  set fbConnectedAt(DateTime? value) =>
      setField<DateTime>('fb_connected_at', value);

  DateTime? get fbLastSyncAt => getField<DateTime>('fb_last_sync_at');
  set fbLastSyncAt(DateTime? value) =>
      setField<DateTime>('fb_last_sync_at', value);

  String? get fbLastSyncStatus => getField<String>('fb_last_sync_status');
  set fbLastSyncStatus(String? value) =>
      setField<String>('fb_last_sync_status', value);

  DateTime? get birthday => getField<DateTime>('birthday');
  set birthday(DateTime? value) => setField<DateTime>('birthday', value);

  String? get nickname => getField<String>('nickname');
  set nickname(String? value) => setField<String>('nickname', value);

  String? get os => getField<String>('os');
  set os(String? value) => setField<String>('os', value);
}
