import '../database.dart';

class UserTicketBalancesVTable extends SupabaseTable<UserTicketBalancesVRow> {
  @override
  String get tableName => 'user_ticket_balances_v';

  @override
  UserTicketBalancesVRow createRow(Map<String, dynamic> data) =>
      UserTicketBalancesVRow(data);
}

class UserTicketBalancesVRow extends SupabaseDataRow {
  UserTicketBalancesVRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserTicketBalancesVTable();

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  int? get studyBalance => getField<int>('study_balance');
  set studyBalance(int? value) => setField<int>('study_balance', value);

  int? get gamesBalance => getField<int>('games_balance');
  set gamesBalance(int? value) => setField<int>('games_balance', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
