import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/retry_until_success.dart';
import '../../../../domain/entities/event.dart';
import '../../../../domain/repositories/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

/// Home BLoC for managing home page state
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _homeRepository;

  HomeBloc({
    required HomeRepository homeRepository,
  })  : _homeRepository = homeRepository,
        super(const HomeState()) {
    on<HomeLoadData>(_onLoadData);
    on<HomeRefresh>(_onRefresh);
    on<HomeRefreshBalance>(_onRefreshBalance);
    on<HomeChangeCity>(_onChangeCity);
  }

  /// Load initial home data — retries until success
  Future<void> _onLoadData(
    HomeLoadData event,
    Emitter<HomeState> emit,
  ) async {
    if (state.status == HomeStatus.loading) return;

    emit(state.copyWith(status: HomeStatus.loading));

    final data = await retryUntilSuccess(() async {
      final cities = await _homeRepository.getCities();
      final savedCity = await _homeRepository.getUserCityPreference() ??
          cities.where((c) => c.name == '臺北').firstOrNull;
      final ticketBalance = await _homeRepository.getTicketBalance();
      final cityId = savedCity?.id;
      final focusedStudyEvents = await _homeRepository.getFocusedStudyEvents(
        cityId: cityId, limit: 10,
      );
      final englishGamesEvents = await _homeRepository.getEnglishGamesEvents(
        cityId: cityId, limit: 10,
      );
      final focusedStudyCountsByCity = await _homeRepository.getEventCountsByCity(
        EventCategory.focusedStudy,
      );
      final englishGamesCountsByCity = await _homeRepository.getEventCountsByCity(
        EventCategory.englishGames,
      );
      return (
        cities: cities,
        savedCity: savedCity,
        ticketBalance: ticketBalance,
        focusedStudyEvents: focusedStudyEvents,
        englishGamesEvents: englishGamesEvents,
        focusedStudyCountsByCity: focusedStudyCountsByCity,
        englishGamesCountsByCity: englishGamesCountsByCity,
      );
    });

    emit(state.copyWith(
      status: HomeStatus.loaded,
      cities: data.cities,
      selectedCity: data.savedCity,
      focusedStudyEvents: data.focusedStudyEvents,
      englishGamesEvents: data.englishGamesEvents,
      ticketBalance: data.ticketBalance,
      focusedStudyCountsByCity: data.focusedStudyCountsByCity,
      englishGamesCountsByCity: data.englishGamesCountsByCity,
    ));
  }

  /// Refresh home data (events + balance)
  Future<void> _onRefresh(
    HomeRefresh event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));

    try {
      final cityId = state.selectedCity?.id;

      final results = await Future.wait([
        _homeRepository.getFocusedStudyEvents(cityId: cityId, limit: 10),
        _homeRepository.getEnglishGamesEvents(cityId: cityId, limit: 10),
        _homeRepository.getTicketBalance(),
      ]);

      emit(state.copyWith(
        focusedStudyEvents: results[0] as List<Event>,
        englishGamesEvents: results[1] as List<Event>,
        ticketBalance: results[2] as dynamic,
        isRefreshing: false,
      ));
    } catch (_) {
      // Keep showing cached data
      emit(state.copyWith(isRefreshing: false));
    }
  }

  /// Refresh only the ticket balance (lightweight, for app resume)
  Future<void> _onRefreshBalance(
    HomeRefreshBalance event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final ticketBalance = await _homeRepository.getTicketBalance();
      emit(state.copyWith(ticketBalance: ticketBalance));
    } catch (_) {
      // Silently fail — keep showing cached balance
    }
  }

  /// Change selected city
  Future<void> _onChangeCity(
    HomeChangeCity event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(
      selectedCity: event.city,
      isRefreshing: true,
    ));

    // Save city preference
    await _homeRepository.saveUserCityPreference(event.city.id);

    try {
      final focusedStudyEvents = await _homeRepository.getFocusedStudyEvents(
        cityId: event.city.id,
        limit: 10,
      );

      final englishGamesEvents = await _homeRepository.getEnglishGamesEvents(
        cityId: event.city.id,
        limit: 10,
      );

      emit(state.copyWith(
        focusedStudyEvents: focusedStudyEvents,
        englishGamesEvents: englishGamesEvents,
        isRefreshing: false,
      ));
    } catch (_) {
      // Keep showing cached data
      emit(state.copyWith(isRefreshing: false));
    }
  }

}
