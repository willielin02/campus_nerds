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
  final bool studyDataLoaded;
  final bool gamesDataLoaded;

  const TicketHistoryState({
    this.status = TicketHistoryStatus.initial,
    this.studyEntries = const [],
    this.gamesEntries = const [],
    this.ticketBalance = const TicketBalance(),
    this.errorMessage,
    this.isRefreshing = false,
    this.studyDataLoaded = false,
    this.gamesDataLoaded = false,
  });

  /// Check if data is loaded
  bool get isLoaded => status == TicketHistoryStatus.loaded;

  /// Check if we have cached study data (loaded at least once)
  bool get hasCachedStudyData => studyDataLoaded;

  /// Check if we have cached games data (loaded at least once)
  bool get hasCachedGamesData => gamesDataLoaded;

  TicketHistoryState copyWith({
    TicketHistoryStatus? status,
    List<TicketHistoryEntry>? studyEntries,
    List<TicketHistoryEntry>? gamesEntries,
    TicketBalance? ticketBalance,
    String? errorMessage,
    bool? isRefreshing,
    bool? studyDataLoaded,
    bool? gamesDataLoaded,
  }) {
    return TicketHistoryState(
      status: status ?? this.status,
      studyEntries: studyEntries ?? this.studyEntries,
      gamesEntries: gamesEntries ?? this.gamesEntries,
      ticketBalance: ticketBalance ?? this.ticketBalance,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      studyDataLoaded: studyDataLoaded ?? this.studyDataLoaded,
      gamesDataLoaded: gamesDataLoaded ?? this.gamesDataLoaded,
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
        studyDataLoaded,
        gamesDataLoaded,
      ];
}
