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
  Future<void> _onLoadStudy(
    TicketHistoryLoadStudy event,
    Emitter<TicketHistoryState> emit,
  ) async {
    // Skip if already loaded study entries
    if (state.studyEntries.isNotEmpty && !state.isRefreshing) return;

    emit(state.copyWith(status: TicketHistoryStatus.loading));

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
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TicketHistoryStatus.error,
        errorMessage: '載入票券紀錄失敗',
      ));
    }
  }

  /// Load games ticket history
  Future<void> _onLoadGames(
    TicketHistoryLoadGames event,
    Emitter<TicketHistoryState> emit,
  ) async {
    // Skip if already loaded games entries
    if (state.gamesEntries.isNotEmpty && !state.isRefreshing) return;

    emit(state.copyWith(status: TicketHistoryStatus.loading));

    try {
      final entries = await _ticketHistoryRepository.getTicketHistory(
        ticketType: 'games',
      );

      emit(state.copyWith(
        status: TicketHistoryStatus.loaded,
        gamesEntries: entries,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TicketHistoryStatus.error,
        errorMessage: '載入票券紀錄失敗',
      ));
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
