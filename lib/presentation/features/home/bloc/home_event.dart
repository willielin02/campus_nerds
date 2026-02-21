import 'package:equatable/equatable.dart';

import '../../../../domain/entities/city.dart';

/// Base class for home events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial home data (cities and events)
class HomeLoadData extends HomeEvent {
  const HomeLoadData();
}

/// Event to refresh home data
class HomeRefresh extends HomeEvent {
  const HomeRefresh();
}

/// Event to change selected city
class HomeChangeCity extends HomeEvent {
  final City city;

  const HomeChangeCity(this.city);

  @override
  List<Object?> get props => [city];
}

/// Event to refresh only the ticket balance (lightweight)
class HomeRefreshBalance extends HomeEvent {
  const HomeRefreshBalance();
}
