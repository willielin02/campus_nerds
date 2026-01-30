import '../database.dart';

class FbFriendSyncAttemptsTable extends SupabaseTable<FbFriendSyncAttemptsRow> {
  @override
  String get tableName => 'fb_friend_sync_attempts';

  @override
  FbFriendSyncAttemptsRow createRow(Map<String, dynamic> data) =>
      FbFriendSyncAttemptsRow(data);
}

class FbFriendSyncAttemptsRow extends SupabaseDataRow {
  FbFriendSyncAttemptsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FbFriendSyncAttemptsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get bookingId => getField<String>('booking_id')!;
  set bookingId(String value) => setField<String>('booking_id', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  String? get errorCode => getField<String>('error_code');
  set errorCode(String? value) => setField<String>('error_code', value);

  String? get errorMessage => getField<String>('error_message');
  set errorMessage(String? value) => setField<String>('error_message', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);
}
