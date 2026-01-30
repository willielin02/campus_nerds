import '../database.dart';

class OrdersTable extends SupabaseTable<OrdersRow> {
  @override
  String get tableName => 'orders';

  @override
  OrdersRow createRow(Map<String, dynamic> data) => OrdersRow(data);
}

class OrdersRow extends SupabaseDataRow {
  OrdersRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => OrdersTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get productId => getField<String>('product_id')!;
  set productId(String value) => setField<String>('product_id', value);

  String get merchantTradeNo => getField<String>('merchant_trade_no')!;
  set merchantTradeNo(String value) =>
      setField<String>('merchant_trade_no', value);

  String get ticketTypeSnapshot => getField<String>('ticket_type_snapshot')!;
  set ticketTypeSnapshot(String value) =>
      setField<String>('ticket_type_snapshot', value);

  int get packSizeSnapshot => getField<int>('pack_size_snapshot')!;
  set packSizeSnapshot(int value) => setField<int>('pack_size_snapshot', value);

  String get titleSnapshot => getField<String>('title_snapshot')!;
  set titleSnapshot(String value) => setField<String>('title_snapshot', value);

  int get priceSnapshotTwd => getField<int>('price_snapshot_twd')!;
  set priceSnapshotTwd(int value) => setField<int>('price_snapshot_twd', value);

  int get totalAmount => getField<int>('total_amount')!;
  set totalAmount(int value) => setField<int>('total_amount', value);

  String get currency => getField<String>('currency')!;
  set currency(String value) => setField<String>('currency', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);

  DateTime? get paidAt => getField<DateTime>('paid_at');
  set paidAt(DateTime? value) => setField<DateTime>('paid_at', value);

  String? get checkoutTokenHash => getField<String>('checkout_token_hash');
  set checkoutTokenHash(String? value) =>
      setField<String>('checkout_token_hash', value);

  DateTime? get checkoutTokenExpiresAt =>
      getField<DateTime>('checkout_token_expires_at');
  set checkoutTokenExpiresAt(DateTime? value) =>
      setField<DateTime>('checkout_token_expires_at', value);
}
