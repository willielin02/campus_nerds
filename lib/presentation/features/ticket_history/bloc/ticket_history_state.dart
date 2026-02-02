import 'package:equatable/equatable.dart';

import '../../../../domain/entities/booking.dart';
import '../../../../domain/entities/ticket_history.dart';

/// Status for ticket history page loading
enum TicketHistoryStatus {
  initial,
  loading,
  loaded,
  error,
}

/// State for ticket history BLoC
class TicketHistoryState extends Equatable {
  final TicketHistoryStatus status;
  final List<TicketHistoryEntry> studyEntries;
  final List<TicketHistoryEntry> gamesEntries;
  final TicketBalance ticketBalance;
  final String? errorMessage;
  final bool isRefreshing;

  const TicketHistoryState({
    this.status = TicketHistoryStatus.initial,
    this.studyEntries = const [],
    this.gamesEntries = const [],
    this.ticketBalance = const TicketBalance(),
    this.errorMessage,
    this.isRefreshing = false,
  });

  /// Check if data is loaded
  bool get isLoaded => status == TicketHistoryStatus.loaded;

  TicketHistoryState copyWith({
    TicketHistoryStatus? status,
    List<TicketHistoryEntry>? studyEntries,
    List<TicketHistoryEntry>? gamesEntries,
    TicketBalance? ticketBalance,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return TicketHistoryState(
      status: status ?? this.status,
      studyEntries: studyEntries ?? this.studyEntries,
      gamesEntries: gamesEntries ?? this.gamesEntries,
      ticketBalance: ticketBalance ?? this.ticketBalance,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        studyEntries,
        gamesEntries,
        ticketBalance,
        errorMessage,
        isRefreshing,
      ];
}
