import '../database.dart';

class PeerFeedbacksTable extends SupabaseTable<PeerFeedbacksRow> {
  @override
  String get tableName => 'peer_feedbacks';

  @override
  PeerFeedbacksRow createRow(Map<String, dynamic> data) =>
      PeerFeedbacksRow(data);
}

class PeerFeedbacksRow extends SupabaseDataRow {
  PeerFeedbacksRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PeerFeedbacksTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get groupId => getField<String>('group_id')!;
  set groupId(String value) => setField<String>('group_id', value);

  String get fromMemberId => getField<String>('from_member_id')!;
  set fromMemberId(String value) => setField<String>('from_member_id', value);

  String get toMemberId => getField<String>('to_member_id')!;
  set toMemberId(String value) => setField<String>('to_member_id', value);

  bool get noShow => getField<bool>('no_show')!;
  set noShow(bool value) => setField<bool>('no_show', value);

  int? get focusRating => getField<int>('focus_rating');
  set focusRating(int? value) => setField<int>('focus_rating', value);

  bool get hasDiscomfortBehavior => getField<bool>('has_discomfort_behavior')!;
  set hasDiscomfortBehavior(bool value) =>
      setField<bool>('has_discomfort_behavior', value);

  String? get discomfortBehaviorNote =>
      getField<String>('discomfort_behavior_note');
  set discomfortBehaviorNote(String? value) =>
      setField<String>('discomfort_behavior_note', value);

  String? get comment => getField<String>('comment');
  set comment(String? value) => setField<String>('comment', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);

  DateTime get updatedAt => getField<DateTime>('updated_at')!;
  set updatedAt(DateTime value) => setField<DateTime>('updated_at', value);

  bool get hasProfileMismatch => getField<bool>('has_profile_mismatch')!;
  set hasProfileMismatch(bool value) =>
      setField<bool>('has_profile_mismatch', value);

  String? get profileMismatchNote => getField<String>('profile_mismatch_note');
  set profileMismatchNote(String? value) =>
      setField<String>('profile_mismatch_note', value);

  int? get performanceScore => getField<int>('performance_score');
  set performanceScore(int? value) => setField<int>('performance_score', value);
}
