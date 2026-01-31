import 'package:equatable/equatable.dart';

/// Base class for account events
abstract class AccountEvent extends Equatable {
  const AccountEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load user profile
class AccountLoadProfile extends AccountEvent {
  const AccountLoadProfile();
}

/// Event to refresh profile
class AccountRefresh extends AccountEvent {
  const AccountRefresh();
}

/// Event to logout
class AccountLogout extends AccountEvent {
  const AccountLogout();
}

/// Event to clear error state
class AccountClearError extends AccountEvent {
  const AccountClearError();
}
