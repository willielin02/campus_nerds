import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/retry_until_success.dart';
import '../../../../domain/entities/user.dart';
import '../../../../domain/repositories/account_repository.dart';
import 'account_event.dart';
import 'account_state.dart';

/// Account BLoC for managing user profile and settings
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AccountRepository _accountRepository;

  AccountBloc({
    required AccountRepository accountRepository,
  })  : _accountRepository = accountRepository,
        super(const AccountState()) {
    on<AccountLoadProfile>(_onLoadProfile);
    on<AccountRefresh>(_onRefresh);
    on<AccountLogout>(_onLogout);
    on<AccountClearError>(_onClearError);
  }

  /// Load user profile — retries indefinitely until success
  Future<void> _onLoadProfile(
    AccountLoadProfile event,
    Emitter<AccountState> emit,
  ) async {
    if (state.status == AccountStatus.loading) return;

    emit(state.copyWith(status: AccountStatus.loading));

    final profile = await _fetchProfileUntilSuccess();

    emit(state.copyWith(
      status: AccountStatus.loaded,
      profile: profile,
    ));
  }

  /// Refresh profile — retries indefinitely until success
  Future<void> _onRefresh(
    AccountRefresh event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));

    final profile = await _fetchProfileUntilSuccess();

    emit(state.copyWith(
      isRefreshing: false,
      profile: profile,
    ));
  }

  /// Keep retrying until profile is fetched successfully
  Future<UserProfile> _fetchProfileUntilSuccess() => retryUntilSuccess(
    () async {
      final profile = await _accountRepository.getUserProfile();
      if (profile == null) throw Exception('Profile not available');
      return profile;
    },
  );

  /// Logout
  Future<void> _onLogout(
    AccountLogout event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(status: AccountStatus.loggingOut));

    try {
      await _accountRepository.logout();
      emit(state.copyWith(status: AccountStatus.loggedOut));
    } catch (e) {
      emit(state.copyWith(
        status: AccountStatus.loaded,
        errorMessage: '登出失敗，請稍後再試',
      ));
    }
  }

  /// Clear error state
  void _onClearError(
    AccountClearError event,
    Emitter<AccountState> emit,
  ) {
    emit(state.copyWith(errorMessage: null));
  }
}
