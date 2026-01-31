import 'package:equatable/equatable.dart';

import '../../../../domain/entities/user.dart';

/// Status for account page loading
enum AccountStatus {
  initial,
  loading,
  loaded,
  error,
  loggingOut,
  loggedOut,
}

/// State for account BLoC
class AccountState extends Equatable {
  final AccountStatus status;
  final UserProfile? profile;
  final String? errorMessage;
  final bool isRefreshing;

  const AccountState({
    this.status = AccountStatus.initial,
    this.profile,
    this.errorMessage,
    this.isRefreshing = false,
  });

  /// Check if profile is loaded
  bool get isLoaded => status == AccountStatus.loaded && profile != null;

  AccountState copyWith({
    AccountStatus? status,
    UserProfile? profile,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return AccountState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage, isRefreshing];
}
