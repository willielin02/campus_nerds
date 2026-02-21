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

  /// Event counts per city for focused study (cityId -> count)
  final Map<String, int> focusedStudyCountsByCity;

  /// Event counts per city for english games (cityId -> count)
  final Map<String, int> englishGamesCountsByCity;

  const HomeState({
    this.status = HomeStatus.initial,
    this.cities = const [],
    this.selectedCity,
    this.focusedStudyEvents = const [],
    this.englishGamesEvents = const [],
    this.ticketBalance = const TicketBalance(),
    this.errorMessage,
    this.isRefreshing = false,
    this.focusedStudyCountsByCity = const {},
    this.englishGamesCountsByCity = const {},
  });

  /// Check if data is loaded
  bool get isLoaded => status == HomeStatus.loaded;

  /// Check if there are any events
  bool get hasEvents =>
      focusedStudyEvents.isNotEmpty || englishGamesEvents.isNotEmpty;

  /// Get display name for selected city
  String get selectedCityName => selectedCity?.name ?? '臺北';

  /// Get focused study event count for a city
  int getFocusedStudyCountForCity(String cityId) =>
      focusedStudyCountsByCity[cityId] ?? 0;

  /// Get english games event count for a city
  int getEnglishGamesCountForCity(String cityId) =>
      englishGamesCountsByCity[cityId] ?? 0;

  HomeState copyWith({
    HomeStatus? status,
    List<City>? cities,
    City? selectedCity,
    List<Event>? focusedStudyEvents,
    List<Event>? englishGamesEvents,
    TicketBalance? ticketBalance,
    String? errorMessage,
    bool? isRefreshing,
    Map<String, int>? focusedStudyCountsByCity,
    Map<String, int>? englishGamesCountsByCity,
  }) {
    return HomeState(
      status: status ?? this.status,
      cities: cities ?? this.cities,
      selectedCity: selectedCity ?? this.selectedCity,
      focusedStudyEvents: focusedStudyEvents ?? this.focusedStudyEvents,
      englishGamesEvents: englishGamesEvents ?? this.englishGamesEvents,
      ticketBalance: ticketBalance ?? this.ticketBalance,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      focusedStudyCountsByCity:
          focusedStudyCountsByCity ?? this.focusedStudyCountsByCity,
      englishGamesCountsByCity:
          englishGamesCountsByCity ?? this.englishGamesCountsByCity,
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
        focusedStudyCountsByCity,
        englishGamesCountsByCity,
      ];
}
