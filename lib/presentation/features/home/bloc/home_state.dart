import 'package:equatable/equatable.dart';

import '../../../../domain/entities/booking.dart';
import '../../../../domain/entities/city.dart';
import '../../../../domain/entities/event.dart';

/// Status for home page loading
enum HomeStatus {
  initial,
  loading,
  loaded,
  error,
}

/// State for home BLoC
class HomeState extends Equatable {
  final HomeStatus status;
  final List<City> cities;
  final City? selectedCity;
  final List<Event> focusedStudyEvents;
  final List<Event> englishGamesEvents;
  final TicketBalance ticketBalance;
  final String? errorMessage;
  final bool isRefreshing;

  const HomeState({
    this.status = HomeStatus.initial,
    this.cities = const [],
    this.selectedCity,
    this.focusedStudyEvents = const [],
    this.englishGamesEvents = const [],
    this.ticketBalance = const TicketBalance(),
    this.errorMessage,
    this.isRefreshing = false,
  });

  /// Check if data is loaded
  bool get isLoaded => status == HomeStatus.loaded;

  /// Check if there are any events
  bool get hasEvents =>
      focusedStudyEvents.isNotEmpty || englishGamesEvents.isNotEmpty;

  /// Get display name for selected city
  String get selectedCityName => selectedCity?.name ?? '全部地區';

  HomeState copyWith({
    HomeStatus? status,
    List<City>? cities,
    City? selectedCity,
    bool clearSelectedCity = false,
    List<Event>? focusedStudyEvents,
    List<Event>? englishGamesEvents,
    TicketBalance? ticketBalance,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return HomeState(
      status: status ?? this.status,
      cities: cities ?? this.cities,
      selectedCity: clearSelectedCity ? null : (selectedCity ?? this.selectedCity),
      focusedStudyEvents: focusedStudyEvents ?? this.focusedStudyEvents,
      englishGamesEvents: englishGamesEvents ?? this.englishGamesEvents,
      ticketBalance: ticketBalance ?? this.ticketBalance,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        cities,
        selectedCity,
        focusedStudyEvents,
        englishGamesEvents,
        ticketBalance,
        errorMessage,
        isRefreshing,
      ];
}
