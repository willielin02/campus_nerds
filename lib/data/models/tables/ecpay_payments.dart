import '../database.dart';

class EcpayPaymentsTable extends SupabaseTable<EcpayPaymentsRow> {
  @override
  String get tableName => 'ecpay_payments';

  @override
  EcpayPaymentsRow createRow(Map<String, dynamic> data) =>
      EcpayPaymentsRow(data);
}

class EcpayPaymentsRow extends SupabaseDataRow {
  EcpayPaymentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EcpayPaymentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get orderId => getField<String>('order_id')!;
  set orderId(String value) => setField<String>('order_id', value);

  String? get tradeNo => getField<String>('trade_no');
  set tradeNo(String? value) => setField<String>('trade_no', value);

  int? get rtnCode => getField<int>('rtn_code');
  set rtnCode(int? value) => setField<int>('rtn_code', value);

  String? get rtnMsg => getField<String>('rtn_msg');
  set rtnMsg(String? value) => setField<String>('rtn_msg', value);

  DateTime? get paidAt => getField<DateTime>('paid_at');
  set paidAt(DateTime? value) => setField<DateTime>('paid_at', value);

  int? get tradeAmt => getField<int>('trade_amt');
  set tradeAmt(int? value) => setField<int>('trade_amt', value);

  String? get checkMacValue => getField<String>('check_mac_value');
  set checkMacValue(String? value) =>
      setField<String>('check_mac_value', value);

  dynamic get raw => getField<dynamic>('raw')!;
  set raw(dynamic value) => setField<dynamic>('raw', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);
}
