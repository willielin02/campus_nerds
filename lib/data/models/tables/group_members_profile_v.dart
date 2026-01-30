import '../database.dart';

class GroupMembersProfileVTable extends SupabaseTable<GroupMembersProfileVRow> {
  @override
  String get tableName => 'group_members_profile_v';

  @override
  GroupMembersProfileVRow createRow(Map<String, dynamic> data) =>
      GroupMembersProfileVRow(data);
}

class GroupMembersProfileVRow extends SupabaseDataRow {
  GroupMembersProfileVRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => GroupMembersProfileVTable();

  String? get groupId => getField<String>('group_id');
  set groupId(String? value) => setField<String>('group_id', value);

  String? get memberId => getField<String>('member_id');
  set memberId(String? value) => setField<String>('member_id', value);

  String? get bookingId => getField<String>('booking_id');
  set bookingId(String? value) => setField<String>('booking_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get nickname => getField<String>('nickname');
  set nickname(String? value) => setField<String>('nickname', value);

  String? get gender => getField<String>('gender');
  set gender(String? value) => setField<String>('gender', value);

  String? get clientOs => getField<String>('client_os');
  set clientOs(String? value) => setField<String>('client_os', value);

  int? get academicRank => getField<int>('academic_rank');
  set academicRank(int? value) => setField<int>('academic_rank', value);
}
