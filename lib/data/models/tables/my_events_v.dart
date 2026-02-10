import '../database.dart';

class MyEventsVTable extends SupabaseTable<MyEventsVRow> {
  @override
  String get tableName => 'my_events_v';

  @override
  MyEventsVRow createRow(Map<String, dynamic> data) => MyEventsVRow(data);
}

class MyEventsVRow extends SupabaseDataRow {
  MyEventsVRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MyEventsVTable();

  String? get bookingId => getField<String>('booking_id');
  set bookingId(String? value) => setField<String>('booking_id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get eventId => getField<String>('event_id');
  set eventId(String? value) => setField<String>('event_id', value);

  String? get bookingStatus => getField<String>('booking_status');
  set bookingStatus(String? value) => setField<String>('booking_status', value);

  DateTime? get bookingCreatedAt => getField<DateTime>('booking_created_at');
  set bookingCreatedAt(DateTime? value) =>
      setField<DateTime>('booking_created_at', value);

  DateTime? get cancelledAt => getField<DateTime>('cancelled_at');
  set cancelledAt(DateTime? value) => setField<DateTime>('cancelled_at', value);

  String? get eventCategory => getField<String>('event_category');
  set eventCategory(String? value) => setField<String>('event_category', value);

  String? get cityId => getField<String>('city_id');
  set cityId(String? value) => setField<String>('city_id', value);

  String? get universityId => getField<String>('university_id');
  set universityId(String? value) => setField<String>('university_id', value);

  DateTime? get eventDate => getField<DateTime>('event_date');
  set eventDate(DateTime? value) => setField<DateTime>('event_date', value);

  String? get timeSlot => getField<String>('time_slot');
  set timeSlot(String? value) => setField<String>('time_slot', value);

  String? get locationDetail => getField<String>('location_detail');
  set locationDetail(String? value) =>
      setField<String>('location_detail', value);

  String? get eventStatus => getField<String>('event_status');
  set eventStatus(String? value) => setField<String>('event_status', value);

  String? get groupId => getField<String>('group_id');
  set groupId(String? value) => setField<String>('group_id', value);

  DateTime? get groupStartAt => getField<DateTime>('group_start_at');
  set groupStartAt(DateTime? value) =>
      setField<DateTime>('group_start_at', value);

  String? get groupStatus => getField<String>('group_status');
  set groupStatus(String? value) => setField<String>('group_status', value);

  DateTime? get chatOpenAt => getField<DateTime>('chat_open_at');
  set chatOpenAt(DateTime? value) => setField<DateTime>('chat_open_at', value);

  String? get venueId => getField<String>('venue_id');
  set venueId(String? value) => setField<String>('venue_id', value);

  String? get venueType => getField<String>('venue_type');
  set venueType(String? value) => setField<String>('venue_type', value);

  String? get venueName => getField<String>('venue_name');
  set venueName(String? value) => setField<String>('venue_name', value);

  String? get venueAddress => getField<String>('venue_address');
  set venueAddress(String? value) => setField<String>('venue_address', value);

  String? get venueGoogleMapUrl => getField<String>('venue_google_map_url');
  set venueGoogleMapUrl(String? value) =>
      setField<String>('venue_google_map_url', value);

  DateTime? get signupDeadlineAt => getField<DateTime>('signup_deadline_at');
  set signupDeadlineAt(DateTime? value) =>
      setField<DateTime>('signup_deadline_at', value);

  DateTime? get feedbackSentAt => getField<DateTime>('feedback_sent_at');
  set feedbackSentAt(DateTime? value) =>
      setField<DateTime>('feedback_sent_at', value);

  DateTime? get goalCloseAt => getField<DateTime>('goal_close_at');
  set goalCloseAt(DateTime? value) =>
      setField<DateTime>('goal_close_at', value);

  bool? get hasEventFeedback => getField<bool>('has_event_feedback');
  set hasEventFeedback(bool? value) =>
      setField<bool>('has_event_feedback', value);

  bool? get hasPeerFeedbackAll => getField<bool>('has_peer_feedback_all');
  set hasPeerFeedbackAll(bool? value) =>
      setField<bool>('has_peer_feedback_all', value);

  bool? get hasFilledFeedbackAll => getField<bool>('has_filled_feedback_all');
  set hasFilledFeedbackAll(bool? value) =>
      setField<bool>('has_filled_feedback_all', value);
}
