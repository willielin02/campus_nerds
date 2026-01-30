import '../database.dart';

class UserPeerScoresVTable extends SupabaseTable<UserPeerScoresVRow> {
  @override
  String get tableName => 'user_peer_scores_v';

  @override
  UserPeerScoresVRow createRow(Map<String, dynamic> data) =>
      UserPeerScoresVRow(data);
}

class UserPeerScoresVRow extends SupabaseDataRow {
  UserPeerScoresVRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserPeerScoresVTable();

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  int? get feedbackCount => getField<int>('feedback_count');
  set feedbackCount(int? value) => setField<int>('feedback_count', value);

  double? get avgPerformanceScore => getField<double>('avg_performance_score');
  set avgPerformanceScore(double? value) =>
      setField<double>('avg_performance_score', value);
}
