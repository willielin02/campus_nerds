import '../database.dart';

class UserBookingStatsVTable extends SupabaseTable<UserBookingStatsVRow> {
  @override
  String get tableName => 'user_booking_stats_v';

  @override
  UserBookingStatsVRow createRow(Map<String, dynamic> data) =>
      UserBookingStatsVRow(data);
}

class UserBookingStatsVRow extends SupabaseDataRow {
  UserBookingStatsVRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserBookingStatsVTable();

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  int? get notGroupedCount => getField<int>('not_grouped_count');
  set notGroupedCount(int? value) => setField<int>('not_grouped_count', value);

  int? get totalBookings => getField<int>('total_bookings');
  set totalBookings(int? value) => setField<int>('total_bookings', value);

  int? get cancelledCount => getField<int>('cancelled_count');
  set cancelledCount(int? value) => setField<int>('cancelled_count', value);

  int? get activeCount => getField<int>('active_count');
  set activeCount(int? value) => setField<int>('active_count', value);

  int? get unmatchedCount => getField<int>('unmatched_count');
  set unmatchedCount(int? value) => setField<int>('unmatched_count', value);

  int? get eventCancelledCount => getField<int>('event_cancelled_count');
  set eventCancelledCount(int? value) =>
      setField<int>('event_cancelled_count', value);
}
