import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/repositories/ticket_history_repository.dart';
import 'ticket_history_event.dart';
import 'ticket_history_state.dart';

/// Ticket History BLoC for managing ticket history page state
class TicketHistoryBloc extends Bloc<TicketHistoryEvent, TicketHistoryState> {
  final TicketHistoryRepository _ticketHistoryRepository;

  TicketHistoryBloc({
    required TicketHistoryRepository ticketHistoryRepository,
  })  : _ticketHistoryRepository = ticketHistoryRepository,
        super(const TicketHistoryState()) {
    on<TicketHistoryLoadStudy>(_onLoadStudy);
    on<TicketHistoryLoadGames>(_onLoadGames);
    on<TicketHistoryRefresh>(_onRefresh);
  }

  /// Load study ticket history
  /// Uses stale-while-revalidate pattern: show cached data first, refresh in background
  Future<void> _onLoadStudy(
    TicketHistoryLoadStudy event,
    Emitter<TicketHistoryState> emit,
  ) async {
    // If we have cached data, show it immediately and refresh in background
    if (state.hasCachedStudyData) {
      emit(state.copyWith(
        status: TicketHistoryStatus.loaded,
        isRefreshing: true,
      ));
    } else {
      // No cached data, show loading state
      emit(state.copyWith(status: TicketHistoryStatus.loading));
    }

    try {
      // Load ticket balance and entries in parallel
      final results = await Future.wait([
        _ticketHistoryRepository.getTicketBalance(),
        _ticketHistoryRepository.getTicketHistory(ticketType: 'study'),
      ]);

      emit(state.copyWith(
        status: TicketHistoryStatus.loaded,
        ticketBalance: results[0] as dynamic,
        studyEntries: results[1] as dynamic,
        isRefreshing: false,
      ));
    } catch (e) {
      // If we have cached data, keep showing it even if refresh fails
      if (state.hasCachedStudyData) {
        emit(state.copyWith(isRefreshing: false));
      } else {
        emit(state.copyWith(
          status: TicketHistoryStatus.error,
          errorMessage: '載入票券紀錄失敗',
        ));
      }
    }
  }

  /// Load games ticket history
  /// Uses stale-while-revalidate pattern: show cached data first, refresh in background
  Future<void> _onLoadGames(
    TicketHistoryLoadGames event,
    Emitter<TicketHistoryState> emit,
  ) async {
    // If we have cached data, show it immediately and refresh in background
    if (state.hasCachedGamesData) {
      emit(state.copyWith(
        status: TicketHistoryStatus.loaded,
        isRefreshing: true,
      ));
    } else {
      // No cached data, show loading state
      emit(state.copyWith(status: TicketHistoryStatus.loading));
    }

    try {
      // Load ticket balance and entries in parallel
      final results = await Future.wait([
        _ticketHistoryRepository.getTicketBalance(),
        _ticketHistoryRepository.getTicketHistory(ticketType: 'games'),
      ]);

      emit(state.copyWith(
        status: TicketHistoryStatus.loaded,
        ticketBalance: results[0] as dynamic,
        gamesEntries: results[1] as dynamic,
        isRefreshing: false,
      ));
    } catch (e) {
      // If we have cached data, keep showing it even if refresh fails
      if (state.hasCachedGamesData) {
        emit(state.copyWith(isRefreshing: false));
      } else {
        emit(state.copyWith(
          status: TicketHistoryStatus.error,
          errorMessage: '載入票券紀錄失敗',
        ));
      }
    }
  }

  /// Refresh all ticket history
  Future<void> _onRefresh(
    TicketHistoryRefresh event,
    Emitter<TicketHistoryState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _ticketHistoryRepository.getTicketBalance(),
        _ticketHistoryRepository.getTicketHistory(ticketType: 'study'),
        _ticketHistoryRepository.getTicketHistory(ticketType: 'games'),
      ]);

      emit(state.copyWith(
        status: TicketHistoryStatus.loaded,
        ticketBalance: results[0] as dynamic,
        studyEntries: results[1] as dynamic,
        gamesEntries: results[2] as dynamic,
        isRefreshing: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        errorMessage: '重新整理失敗',
      ));
    }
  }
}
