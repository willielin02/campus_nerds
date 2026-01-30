import '../database.dart';

class GroupEnglishAssignmentsTable
    extends SupabaseTable<GroupEnglishAssignmentsRow> {
  @override
  String get tableName => 'group_english_assignments';

  @override
  GroupEnglishAssignmentsRow createRow(Map<String, dynamic> data) =>
      GroupEnglishAssignmentsRow(data);
}

class GroupEnglishAssignmentsRow extends SupabaseDataRow {
  GroupEnglishAssignmentsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => GroupEnglishAssignmentsTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get groupId => getField<String>('group_id')!;
  set groupId(String value) => setField<String>('group_id', value);

  String get memberId => getField<String>('member_id')!;
  set memberId(String value) => setField<String>('member_id', value);

  String get contentId => getField<String>('content_id')!;
  set contentId(String value) => setField<String>('content_id', value);

  String get contentEnSnapshot => getField<String>('content_en_snapshot')!;
  set contentEnSnapshot(String value) =>
      setField<String>('content_en_snapshot', value);

  String get contentZhSnapshot => getField<String>('content_zh_snapshot')!;
  set contentZhSnapshot(String value) =>
      setField<String>('content_zh_snapshot', value);

  int get usedCount => getField<int>('used_count')!;
  set usedCount(int value) => setField<int>('used_count', value);

  DateTime get assignedAt => getField<DateTime>('assigned_at')!;
  set assignedAt(DateTime value) => setField<DateTime>('assigned_at', value);
}
