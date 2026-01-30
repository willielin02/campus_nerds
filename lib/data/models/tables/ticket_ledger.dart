import '../database.dart';

class TicketLedgerTable extends SupabaseTable<TicketLedgerRow> {
  @override
  String get tableName => 'ticket_ledger';

  @override
  TicketLedgerRow createRow(Map<String, dynamic> data) => TicketLedgerRow(data);
}

class TicketLedgerRow extends SupabaseDataRow {
  TicketLedgerRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => TicketLedgerTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String? get orderId => getField<String>('order_id');
  set orderId(String? value) => setField<String>('order_id', value);

  String? get bookingId => getField<String>('booking_id');
  set bookingId(String? value) => setField<String>('booking_id', value);

  int get deltaStudy => getField<int>('delta_study')!;
  set deltaStudy(int value) => setField<int>('delta_study', value);

  int get deltaGames => getField<int>('delta_games')!;
  set deltaGames(int value) => setField<int>('delta_games', value);

  String get reason => getField<String>('reason')!;
  set reason(String value) => setField<String>('reason', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);
}
