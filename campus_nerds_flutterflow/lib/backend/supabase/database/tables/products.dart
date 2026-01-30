import '../database.dart';

class ProductsTable extends SupabaseTable<ProductsRow> {
  @override
  String get tableName => 'products';

  @override
  ProductsRow createRow(Map<String, dynamic> data) => ProductsRow(data);
}

class ProductsRow extends SupabaseDataRow {
  ProductsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProductsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get ticketType => getField<String>('ticket_type')!;
  set ticketType(String value) => setField<String>('ticket_type', value);

  int get packSize => getField<int>('pack_size')!;
  set packSize(int value) => setField<int>('pack_size', value);

  int get priceTwd => getField<int>('price_twd')!;
  set priceTwd(int value) => setField<int>('price_twd', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  bool get isActive => getField<bool>('is_active')!;
  set isActive(bool value) => setField<bool>('is_active', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);

  int get percentOff => getField<int>('percent_off')!;
  set percentOff(int value) => setField<int>('percent_off', value);

  int? get unitPriceTwd => getField<int>('unit_price_twd');
  set unitPriceTwd(int? value) => setField<int>('unit_price_twd', value);
}
