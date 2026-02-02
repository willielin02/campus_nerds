import 'package:equatable/equatable.dart';

/// Base class for ticket history events
abstract class TicketHistoryEvent extends Equatable {
  const TicketHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load ticket history for study tickets
class TicketHistoryLoadStudy extends TicketHistoryEvent {
  const TicketHistoryLoadStudy();
}

/// Event to load ticket history for games tickets
class TicketHistoryLoadGames extends TicketHistoryEvent {
  const TicketHistoryLoadGames();
}

/// Event to refresh ticket history
class TicketHistoryRefresh extends TicketHistoryEvent {
  const TicketHistoryRefresh();
}
