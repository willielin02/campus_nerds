import '../database.dart';

class GroupFocusedStudyPlansVTable
    extends SupabaseTable<GroupFocusedStudyPlansVRow> {
  @override
  String get tableName => 'group_focused_study_plans_v';

  @override
  GroupFocusedStudyPlansVRow createRow(Map<String, dynamic> data) =>
      GroupFocusedStudyPlansVRow(data);
}

class GroupFocusedStudyPlansVRow extends SupabaseDataRow {
  GroupFocusedStudyPlansVRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => GroupFocusedStudyPlansVTable();

  String? get groupId => getField<String>('group_id');
  set groupId(String? value) => setField<String>('group_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  int? get slot => getField<int>('slot');
  set slot(int? value) => setField<int>('slot', value);

  String? get content => getField<String>('content');
  set content(String? value) => setField<String>('content', value);

  bool? get isDone => getField<bool>('is_done');
  set isDone(bool? value) => setField<bool>('is_done', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
