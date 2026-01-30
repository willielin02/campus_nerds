import '../database.dart';

class FriendshipsTable extends SupabaseTable<FriendshipsRow> {
  @override
  String get tableName => 'friendships';

  @override
  FriendshipsRow createRow(Map<String, dynamic> data) => FriendshipsRow(data);
}

class FriendshipsRow extends SupabaseDataRow {
  FriendshipsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FriendshipsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userLowId => getField<String>('user_low_id')!;
  set userLowId(String value) => setField<String>('user_low_id', value);

  String get userHighId => getField<String>('user_high_id')!;
  set userHighId(String value) => setField<String>('user_high_id', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);

  DateTime get lastSeenAt => getField<DateTime>('last_seen_at')!;
  set lastSeenAt(DateTime value) => setField<DateTime>('last_seen_at', value);
}
