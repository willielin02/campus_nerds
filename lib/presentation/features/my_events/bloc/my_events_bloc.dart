import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../../domain/entities/booking.dart';
import '../../../../domain/repositories/my_events_repository.dart';
import 'my_events_event.dart';
import 'my_events_state.dart';

/// MyEvents BLoC for managing user's booked events
class MyEventsBloc extends Bloc<MyEventsEvent, MyEventsState> {
  final MyEventsRepository _myEventsRepository;

  /// Realtime: 追蹤已訂閱的 group IDs，避免重複訂閱
  final Set<String> _subscribedGroupIds = {};
  final List<RealtimeChannel> _realtimeChannels = [];
  Timer? _refreshDebouncer;

  MyEventsBloc({
    required MyEventsRepository myEventsRepository,
  })  : _myEventsRepository = myEventsRepository,
        super(const MyEventsState()) {
    on<MyEventsLoadData>(_onLoadData);
    on<MyEventsRefresh>(_onRefresh);
    on<MyEventsCreateBooking>(_onCreateBooking);
    on<MyEventsCancelBooking>(_onCancelBooking);
    on<MyEventsLoadDetails>(_onLoadDetails);
    on<MyEventsClearError>(_onClearError);
    on<MyEventsClearSuccess>(_onClearSuccess);
    // Study plan events (Phase 7)
    on<MyEventsLoadStudyPlans>(_onLoadStudyPlans);
    on<MyEventsLoadMyStudyPlans>(_onLoadMyStudyPlans);
    on<MyEventsUpdateStudyPlan>(_onUpdateStudyPlan);
  }

  /// Load initial my events data
  Future<void> _onLoadData(
    MyEventsLoadData event,
    Emitter<MyEventsState> emit,
  ) async {
    if (state.status == MyEventsStatus.loading) return;

    emit(state.copyWith(status: MyEventsStatus.loading));

    try {
      final upcomingEvents = await _myEventsRepository.getUpcomingEvents();
      final pastEvents = await _myEventsRepository.getPastEvents();
      final ticketBalance = await _myEventsRepository.getTicketBalance();

      emit(state.copyWith(
        status: MyEventsStatus.loaded,
        upcomingEvents: upcomingEvents,
        pastEvents: pastEvents,
        ticketBalance: ticketBalance,
      ));

      _setupRealtimeSubscriptions(upcomingEvents);
    } catch (e) {
      emit(state.copyWith(
        status: MyEventsStatus.error,
        errorMessage: '載入資料失敗',
      ));
    }
  }

  /// Refresh my events data
  Future<void> _onRefresh(
    MyEventsRefresh event,
    Emitter<MyEventsState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));

    try {
      final upcomingEvents = await _myEventsRepository.getUpcomingEvents();
      final pastEvents = await _myEventsRepository.getPastEvents();
      final ticketBalance = await _myEventsRepository.getTicketBalance();

      emit(state.copyWith(
        upcomingEvents: upcomingEvents,
        pastEvents: pastEvents,
        ticketBalance: ticketBalance,
        isRefreshing: false,
      ));

      _setupRealtimeSubscriptions(upcomingEvents);
    } catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        errorMessage: '重新整理失敗',
      ));
    }
  }

  /// Create a booking
  Future<void> _onCreateBooking(
    MyEventsCreateBooking event,
    Emitter<MyEventsState> emit,
  ) async {
    emit(state.copyWith(isBooking: true));

    try {
      final result = await _myEventsRepository.createBooking(
        eventId: event.eventId,
        category: event.category,
      );

      if (result.success) {
        // Refresh events list after successful booking
        final upcomingEvents = await _myEventsRepository.getUpcomingEvents();
        final ticketBalance = await _myEventsRepository.getTicketBalance();

        emit(state.copyWith(
          upcomingEvents: upcomingEvents,
          ticketBalance: ticketBalance,
          isBooking: false,
          successMessage: '報名成功！',
        ));
      } else {
        emit(state.copyWith(
          isBooking: false,
          errorMessage: result.errorMessage ?? '報名失敗',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isBooking: false,
        errorMessage: '報名失敗，請稍後再試',
      ));
    }
  }

  /// Cancel a booking
  Future<void> _onCancelBooking(
    MyEventsCancelBooking event,
    Emitter<MyEventsState> emit,
  ) async {
    emit(state.copyWith(isBooking: true));

    try {
      final result = await _myEventsRepository.cancelBooking(
        bookingId: event.bookingId,
      );

      if (result.success) {
        // Refresh events list after successful cancellation
        final upcomingEvents = await _myEventsRepository.getUpcomingEvents();
        final ticketBalance = await _myEventsRepository.getTicketBalance();

        emit(state.copyWith(
          upcomingEvents: upcomingEvents,
          ticketBalance: ticketBalance,
          isBooking: false,
          clearSelectedEvent: true,
          successMessage: '已取消報名',
        ));
      } else {
        emit(state.copyWith(
          isBooking: false,
          errorMessage: result.errorMessage ?? '取消報名失敗',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isBooking: false,
        errorMessage: '取消報名失敗，請稍後再試',
      ));
    }
  }

  /// Load event details and study plans in one handler.
  /// This guarantees study plans are loaded with fresh event data,
  /// avoiding stale groupId issues from _initTabController timing.
  Future<void> _onLoadDetails(
    MyEventsLoadDetails event,
    Emitter<MyEventsState> emit,
  ) async {
    // Clear stale data
    emit(state.copyWith(
      clearSelectedEvent: true,
      studyPlans: const [],
    ));

    try {
      final myEvent =
          await _myEventsRepository.getEventByBookingId(event.bookingId);

      emit(state.copyWith(selectedEvent: myEvent));

      // Load study plans using fresh event data
      if (myEvent != null && myEvent.isFocusedStudy) {
        emit(state.copyWith(isLoadingStudyPlans: true));

        final plans = myEvent.groupId != null
            ? await _myEventsRepository
                .getGroupFocusedStudyPlans(myEvent.groupId!)
            : await _myEventsRepository
                .getMyFocusedStudyPlans(myEvent.bookingId);

        emit(state.copyWith(
          studyPlans: plans,
          isLoadingStudyPlans: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: '載入活動詳情失敗',
      ));
    }
  }

  /// Clear error state
  void _onClearError(
    MyEventsClearError event,
    Emitter<MyEventsState> emit,
  ) {
    emit(state.copyWith(errorMessage: null));
  }

  /// Clear success message
  void _onClearSuccess(
    MyEventsClearSuccess event,
    Emitter<MyEventsState> emit,
  ) {
    emit(state.copyWith(successMessage: null));
  }

  // ============================================
  // Study Plan Handlers (Phase 7)
  // ============================================

  /// Load study plans for a group
  Future<void> _onLoadStudyPlans(
    MyEventsLoadStudyPlans event,
    Emitter<MyEventsState> emit,
  ) async {
    emit(state.copyWith(isLoadingStudyPlans: true));

    try {
      final studyPlans =
          await _myEventsRepository.getGroupFocusedStudyPlans(event.groupId);

      emit(state.copyWith(
        studyPlans: studyPlans,
        isLoadingStudyPlans: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingStudyPlans: false,
        errorMessage: '載入待辦事項失敗',
      ));
    }
  }

  /// Load own study plans by booking ID (pre-grouping)
  Future<void> _onLoadMyStudyPlans(
    MyEventsLoadMyStudyPlans event,
    Emitter<MyEventsState> emit,
  ) async {
    emit(state.copyWith(isLoadingStudyPlans: true));

    try {
      final studyPlans =
          await _myEventsRepository.getMyFocusedStudyPlans(event.bookingId);

      emit(state.copyWith(
        studyPlans: studyPlans,
        isLoadingStudyPlans: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingStudyPlans: false,
        errorMessage: '載入待辦事項失敗',
      ));
    }
  }

  /// Update a study plan
  Future<void> _onUpdateStudyPlan(
    MyEventsUpdateStudyPlan event,
    Emitter<MyEventsState> emit,
  ) async {
    emit(state.copyWith(isUpdatingStudyPlan: true));

    try {
      final result = await _myEventsRepository.updateFocusedStudyPlan(
        planId: event.planId,
        content: event.content,
        isDone: event.isDone,
      );

      if (result.success) {
        // Refresh study plans after update (group or own)
        final List<GroupFocusedPlan> studyPlans;
        if (event.groupId != null) {
          studyPlans = await _myEventsRepository
              .getGroupFocusedStudyPlans(event.groupId!);
        } else if (event.bookingId != null) {
          studyPlans = await _myEventsRepository
              .getMyFocusedStudyPlans(event.bookingId!);
        } else {
          studyPlans = state.studyPlans;
        }

        emit(state.copyWith(
          studyPlans: studyPlans,
          isUpdatingStudyPlan: false,
          successMessage: '已更新待辦事項',
        ));
      } else {
        emit(state.copyWith(
          isUpdatingStudyPlan: false,
          errorMessage: result.errorMessage ?? '更新失敗',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isUpdatingStudyPlan: false,
        errorMessage: '更新失敗，請稍後再試',
      ));
    }
  }

  // ============================================
  // Realtime Subscriptions (未讀訊息即時更新)
  // ============================================

  /// 對所有有 groupId 的活動建立 Realtime 訂閱，
  /// 偵測到非自己的新訊息時 debounce 觸發 refresh。
  void _setupRealtimeSubscriptions(List<MyEvent> upcomingEvents) {
    final groupIds = upcomingEvents
        .where((e) => e.groupId != null)
        .map((e) => e.groupId!)
        .toSet();

    // 如果 group IDs 沒變，不重新訂閱
    if (_subscribedGroupIds.length == groupIds.length &&
        _subscribedGroupIds.containsAll(groupIds)) {
      return;
    }

    _teardownSubscriptions();

    if (groupIds.isEmpty) return;

    final currentUserId = SupabaseService.currentUserId;

    for (final groupId in groupIds) {
      final channel = SupabaseService.channel('my-events:$groupId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'group_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'group_id',
              value: groupId,
            ),
            callback: (payload) {
              final senderId = payload.newRecord['user_id'] as String?;
              // 自己發的訊息不觸發刷新
              if (senderId == currentUserId) return;
              _debouncedRefresh();
            },
          )
          .subscribe();

      _realtimeChannels.add(channel);
    }

    _subscribedGroupIds.addAll(groupIds);
  }

  /// Debounce 刷新，避免短時間內多條訊息造成重複查詢
  void _debouncedRefresh() {
    _refreshDebouncer?.cancel();
    _refreshDebouncer = Timer(const Duration(milliseconds: 800), () {
      if (!isClosed) {
        add(const MyEventsRefresh());
      }
    });
  }

  void _teardownSubscriptions() {
    for (final channel in _realtimeChannels) {
      SupabaseService.removeChannel(channel);
    }
    _realtimeChannels.clear();
    _subscribedGroupIds.clear();
    _refreshDebouncer?.cancel();
  }

  @override
  Future<void> close() {
    _teardownSubscriptions();
    return super.close();
  }
}
