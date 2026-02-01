import 'package:flutter_bloc/flutter_bloc.dart';

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
    on<HomeChangeCity>(_onChangeCity);
    on<HomeClearCity>(_onClearCity);
  }

  /// Load initial home data
  Future<void> _onLoadData(
    HomeLoadData event,
    Emitter<HomeState> emit,
  ) async {
    if (state.status == HomeStatus.loading) return;

    emit(state.copyWith(status: HomeStatus.loading));

    try {
      // Load cities
      final cities = await _homeRepository.getCities();

      // Load saved city preference
      final savedCity = await _homeRepository.getUserCityPreference();

      // Load ticket balance
      final ticketBalance = await _homeRepository.getTicketBalance();

      // Load events for selected city (or all cities if no preference)
      final cityId = savedCity?.id;

      final focusedStudyEvents = await _homeRepository.getFocusedStudyEvents(
        cityId: cityId,
        limit: 10,
      );

      final englishGamesEvents = await _homeRepository.getEnglishGamesEvents(
        cityId: cityId,
        limit: 10,
      );

      // Load event counts for all cities (for city selector opacity)
      final focusedStudyCountsByCity = await _homeRepository.getEventCountsByCity(
        EventCategory.focusedStudy,
      );
      final englishGamesCountsByCity = await _homeRepository.getEventCountsByCity(
        EventCategory.englishGames,
      );

      emit(state.copyWith(
        status: HomeStatus.loaded,
        cities: cities,
        selectedCity: savedCity,
        focusedStudyEvents: focusedStudyEvents,
        englishGamesEvents: englishGamesEvents,
        ticketBalance: ticketBalance,
        focusedStudyCountsByCity: focusedStudyCountsByCity,
        englishGamesCountsByCity: englishGamesCountsByCity,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: '載入資料失敗',
      ));
    }
  }

  /// Refresh home data
  Future<void> _onRefresh(
    HomeRefresh event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));

    try {
      final cityId = state.selectedCity?.id;

      final focusedStudyEvents = await _homeRepository.getFocusedStudyEvents(
        cityId: cityId,
        limit: 10,
      );

      final englishGamesEvents = await _homeRepository.getEnglishGamesEvents(
        cityId: cityId,
        limit: 10,
      );

      emit(state.copyWith(
        focusedStudyEvents: focusedStudyEvents,
        englishGamesEvents: englishGamesEvents,
        isRefreshing: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        errorMessage: '重新整理失敗',
      ));
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
    } catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        errorMessage: '載入資料失敗',
      ));
    }
  }

  /// Clear selected city (show all cities)
  Future<void> _onClearCity(
    HomeClearCity event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(
      clearSelectedCity: true,
      isRefreshing: true,
    ));

    try {
      final focusedStudyEvents = await _homeRepository.getFocusedStudyEvents(
        limit: 10,
      );

      final englishGamesEvents = await _homeRepository.getEnglishGamesEvents(
        limit: 10,
      );

      emit(state.copyWith(
        focusedStudyEvents: focusedStudyEvents,
        englishGamesEvents: englishGamesEvents,
        isRefreshing: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        errorMessage: '載入資料失敗',
      ));
    }
  }
}
