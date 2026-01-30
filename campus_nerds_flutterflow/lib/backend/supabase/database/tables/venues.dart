import '../database.dart';

class VenuesTable extends SupabaseTable<VenuesRow> {
  @override
  String get tableName => 'venues';

  @override
  VenuesRow createRow(Map<String, dynamic> data) => VenuesRow(data);
}

class VenuesRow extends SupabaseDataRow {
  VenuesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VenuesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get universityId => getField<String>('university_id');
  set universityId(String? value) => setField<String>('university_id', value);

  String get cityId => getField<String>('city_id')!;
  set cityId(String value) => setField<String>('city_id', value);

  String get type => getField<String>('type')!;
  set type(String value) => setField<String>('type', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String get address => getField<String>('address')!;
  set address(String value) => setField<String>('address', value);

  String get googleMapUrl => getField<String>('google_map_url')!;
  set googleMapUrl(String value) => setField<String>('google_map_url', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);

  String get category => getField<String>('category')!;
  set category(String value) => setField<String>('category', value);

  DateTime? get startAt => getField<DateTime>('start_at');
  set startAt(DateTime? value) => setField<DateTime>('start_at', value);
}
