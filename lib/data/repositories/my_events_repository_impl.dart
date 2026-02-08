import '../../core/services/supabase_service.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/my_events_repository.dart';
import '../models/tables/group_members_profile_v.dart';
import '../models/tables/my_events_v.dart';
import '../models/tables/user_ticket_balances_v.dart';

/// Implementation of MyEventsRepository using Supabase
class MyEventsRepositoryImpl implements MyEventsRepository {
  @override
  Future<List<MyEvent>> getUpcomingEvents() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final response = await MyEventsVTable().queryRows(
        queryFn: (q) => q
            .eq('user_id', userId)
            .neq('booking_status', 'cancelled')
            .gte('event_date', today.toIso8601String())
            .order('event_date')
            .order('time_slot'),
      );

      return response.map(_mapRowToMyEvent).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<MyEvent>> getPastEvents() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final response = await MyEventsVTable().queryRows(
        queryFn: (q) => q
            .eq('user_id', userId)
            .neq('booking_status', 'cancelled')
            .lt('event_date', today.toIso8601String())
            .order('event_date', ascending: false)
            .order('time_slot')
            .limit(20),
      );

      return response.map(_mapRowToMyEvent).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<MyEvent?> getEventByBookingId(String bookingId) async {
    try {
      final response = await MyEventsVTable().queryRows(
        queryFn: (q) => q.eq('booking_id', bookingId).limit(1),
      );

      if (response.isEmpty) return null;

      final myEvent = _mapRowToMyEvent(response.first);

      // Load group members if there's a group
      if (myEvent.groupId != null) {
        final members = await getGroupMembers(myEvent.groupId!);
        return myEvent.copyWithGroupMembers(members);
      }

      return myEvent;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final currentUserId = SupabaseService.currentUserId;

      final response = await GroupMembersProfileVTable().queryRows(
        queryFn: (q) => q.eq('group_id', groupId),
      );

      return response.map((row) {
        return GroupMember(
          id: row.memberId ?? '',
          nickname: row.nickname,
          gender: row.gender,
          academicRank: row.academicRank,
          isCurrentUser: row.userId == currentUserId,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<TicketBalance> getTicketBalance() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return const TicketBalance();

      final response = await UserTicketBalancesVTable().queryRows(
        queryFn: (q) => q.eq('user_id', userId).limit(1),
      );

      if (response.isEmpty) return const TicketBalance();

      final row = response.first;
      return TicketBalance(
        studyBalance: row.studyBalance ?? 0,
        gamesBalance: row.gamesBalance ?? 0,
      );
    } catch (e) {
      return const TicketBalance();
    }
  }

  @override
  Future<BookingResult> createBooking({
    required String eventId,
    required EventCategory category,
  }) async {
    try {
      // Call RPC function to create booking
      final response = await SupabaseService.client.rpc(
        'rpc_create_booking',
        params: {
          'p_event_id': eventId,
        },
      );

      // Response should contain the booking ID
      if (response != null) {
        final bookingId = response['booking_id'] as String?;
        return BookingResult.success(bookingId);
      }

      return BookingResult.success();
    } catch (e) {
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('already')) {
        return BookingResult.failure('您已經報名此活動');
      }
      if (errorString.contains('full') || errorString.contains('額滿')) {
        return BookingResult.failure('活動已額滿');
      }
      if (errorString.contains('closed') || errorString.contains('截止')) {
        return BookingResult.failure('報名已截止');
      }
      if (errorString.contains('balance') || errorString.contains('ticket')) {
        return BookingResult.failure('票券餘額不足');
      }
      if (errorString.contains('conflict') || errorString.contains('衝突')) {
        return BookingResult.failure('與其他活動時段衝突');
      }

      return BookingResult.failure('報名失敗，請稍後再試');
    }
  }

  @override
  Future<BookingResult> cancelBooking({
    required String bookingId,
  }) async {
    try {
      // Call RPC function to cancel booking
      await SupabaseService.client.rpc(
        'rpc_cancel_booking',
        params: {
          'p_booking_id': bookingId,
        },
      );

      return BookingResult.success();
    } catch (e) {
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('deadline') || errorString.contains('截止')) {
        return BookingResult.failure('已超過取消期限');
      }
      if (errorString.contains('not found') || errorString.contains('找不到')) {
        return BookingResult.failure('找不到此報名記錄');
      }

      return BookingResult.failure('取消報名失敗，請稍後再試');
    }
  }

  @override
  Future<bool> hasBookedEvent(String eventId) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return false;

      final response = await MyEventsVTable().queryRows(
        queryFn: (q) => q
            .eq('user_id', userId)
            .eq('event_id', eventId)
            .neq('booking_status', 'cancelled')
            .limit(1),
      );

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // Study Plan Methods (Phase 7)
  // ============================================

  @override
  Future<List<GroupFocusedPlan>> getGroupFocusedStudyPlans(String groupId) async {
    try {
      final token = SupabaseService.jwtToken;
      if (token == null) return [];

      final response = await SupabaseService.client.rpc(
        'get_group_focused_study_plans',
        params: {'p_group_id': groupId},
      );

      if (response == null || response is! List) return [];

      return response.map((item) {
        final map = item as Map<String, dynamic>;
        return GroupFocusedPlan(
          groupId: map['group_id'] ?? groupId,
          userId: map['user_id'],
          displayName: map['display_name'] ?? '匿名',
          isMe: map['is_me'] ?? false,
          plan1Id: map['plan1_id'],
          plan1Content: map['plan1_content'],
          plan1Done: map['plan1_done'] ?? false,
          plan2Id: map['plan2_id'],
          plan2Content: map['plan2_content'],
          plan2Done: map['plan2_done'] ?? false,
          plan3Id: map['plan3_id'],
          plan3Content: map['plan3_content'],
          plan3Done: map['plan3_done'] ?? false,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<GroupFocusedPlan>> getMyFocusedStudyPlans(String bookingId) async {
    try {
      final response = await SupabaseService.client.rpc(
        'get_my_focused_study_plans',
        params: {'p_booking_id': bookingId},
      );

      if (response == null || response is! List) return [];

      return response.map((item) {
        final map = item as Map<String, dynamic>;
        return GroupFocusedPlan(
          groupId: null,
          userId: map['user_id'],
          displayName: map['display_name'] ?? '匿名',
          isMe: true,
          plan1Id: map['plan1_id'],
          plan1Content: map['plan1_content'],
          plan1Done: map['plan1_done'] ?? false,
          plan2Id: map['plan2_id'],
          plan2Content: map['plan2_content'],
          plan2Done: map['plan2_done'] ?? false,
          plan3Id: map['plan3_id'],
          plan3Content: map['plan3_content'],
          plan3Done: map['plan3_done'] ?? false,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<BookingResult> updateFocusedStudyPlan({
    required String planId,
    required String content,
    required bool isDone,
  }) async {
    try {
      await SupabaseService.client.rpc(
        'update_focused_study_plan',
        params: {
          'p_plan_id': planId,
          'p_content': content,
          'p_done': isDone,
        },
      );

      return BookingResult.success();
    } catch (e) {
      return BookingResult.failure('更新失敗，請稍後再試');
    }
  }

  MyEvent _mapRowToMyEvent(MyEventsVRow row) {
    return MyEvent(
      bookingId: row.bookingId ?? '',
      eventId: row.eventId ?? '',
      groupId: row.groupId,
      bookingStatus: BookingStatus.fromString(row.bookingStatus ?? 'pending'),
      bookingCreatedAt: row.bookingCreatedAt ?? DateTime.now(),
      cancelledAt: row.cancelledAt,
      eventCategory:
          EventCategory.fromString(row.eventCategory ?? 'focused_study'),
      cityId: row.cityId,
      universityId: row.universityId,
      eventDate: row.eventDate ?? DateTime.now(),
      timeSlot: TimeSlot.fromString(row.timeSlot ?? 'afternoon'),
      locationDetail: row.locationDetail ?? '',
      eventStatus: EventStatus.fromString(row.eventStatus ?? 'open'),
      signupDeadlineAt: row.signupDeadlineAt,
      groupStatus: row.groupStatus != null
          ? GroupStatus.fromString(row.groupStatus!)
          : null,
      groupStartAt: row.groupStartAt,
      chatOpenAt: row.chatOpenAt,
      venueId: row.venueId,
      venueName: row.venueName,
      venueAddress: row.venueAddress,
      venueGoogleMapUrl: row.venueGoogleMapUrl,
      goalCloseAt: row.goalCloseAt,
      goalCheckCloseAt: row.goalCheckCloseAt,
      feedbackSentAt: row.feedbackSentAt,
      hasEventFeedback: row.hasEventFeedback ?? false,
      hasPeerFeedbackAll: row.hasPeerFeedbackAll ?? false,
      hasFilledFeedbackAll: row.hasFilledFeedbackAll ?? false,
    );
  }
}
