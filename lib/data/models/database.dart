/// Database models and table access
///
/// This file re-exports all Supabase table models and utilities.
library;

// Core exports
export 'package:supabase_flutter/supabase_flutter.dart';

// Base classes
export 'lat_lng.dart';
export 'supabase_row.dart';
export 'supabase_table.dart';

// Table models (37 tables)
export 'tables/bookings.dart';
export 'tables/cities.dart';
export 'tables/ecpay_payments.dart';
export 'tables/english_content_exposures.dart';
export 'tables/english_contents.dart';
export 'tables/event_feedbacks.dart';
export 'tables/events.dart';
export 'tables/fb_friend_sync_attempts.dart';
export 'tables/focused_study_plans.dart';
export 'tables/friendships.dart';
export 'tables/group_chat_messages_v.dart';
export 'tables/group_chat_timeline.dart';
export 'tables/group_english_assignments.dart';
export 'tables/group_english_assignments_v.dart';
export 'tables/group_focused_study_plans_v.dart';
export 'tables/group_members.dart';
export 'tables/group_members_profile_v.dart';
export 'tables/group_messages.dart';
export 'tables/groups.dart';
export 'tables/home_events_v.dart';
export 'tables/in_app_notifications.dart';
export 'tables/my_events_v.dart';
export 'tables/orders.dart';
export 'tables/peer_feedbacks.dart';
export 'tables/products.dart';
export 'tables/school_email_verifications.dart';
export 'tables/ticket_ledger.dart';
export 'tables/universities.dart';
export 'tables/university_email_domains.dart';
export 'tables/user_booking_stats_v.dart';
export 'tables/user_current_university_v.dart';
export 'tables/user_peer_scores_v.dart';
export 'tables/user_profile_v.dart';
export 'tables/user_school_emails.dart';
export 'tables/user_ticket_balances_v.dart';
export 'tables/users.dart';
export 'tables/venues.dart';
