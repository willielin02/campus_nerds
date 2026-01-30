import '../database.dart';

class GroupEnglishAssignmentsVTable
    extends SupabaseTable<GroupEnglishAssignmentsVRow> {
  @override
  String get tableName => 'group_english_assignments_v';

  @override
  GroupEnglishAssignmentsVRow createRow(Map<String, dynamic> data) =>
      GroupEnglishAssignmentsVRow(data);
}

class GroupEnglishAssignmentsVRow extends SupabaseDataRow {
  GroupEnglishAssignmentsVRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => GroupEnglishAssignmentsVTable();

  String? get groupId => getField<String>('group_id');
  set groupId(String? value) => setField<String>('group_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get contentEn => getField<String>('content_en');
  set contentEn(String? value) => setField<String>('content_en', value);

  String? get contentZh => getField<String>('content_zh');
  set contentZh(String? value) => setField<String>('content_zh', value);

  int? get usedCount => getField<int>('used_count');
  set usedCount(int? value) => setField<int>('used_count', value);

  DateTime? get assignedAt => getField<DateTime>('assigned_at');
  set assignedAt(DateTime? value) => setField<DateTime>('assigned_at', value);
}
