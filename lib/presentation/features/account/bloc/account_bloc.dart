import 'package:flutter_bloc/flutter_bloc.dart';

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

  /// Load user profile
  Future<void> _onLoadProfile(
    AccountLoadProfile event,
    Emitter<AccountState> emit,
  ) async {
    if (state.status == AccountStatus.loading) return;

    emit(state.copyWith(status: AccountStatus.loading));

    try {
      final profile = await _accountRepository.getUserProfile();

      if (profile != null) {
        emit(state.copyWith(
          status: AccountStatus.loaded,
          profile: profile,
        ));
      } else {
        emit(state.copyWith(
          status: AccountStatus.error,
          errorMessage: '無法載入使用者資料',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AccountStatus.error,
        errorMessage: '載入資料失敗',
      ));
    }
  }

  /// Refresh profile
  Future<void> _onRefresh(
    AccountRefresh event,
    Emitter<AccountState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));

    try {
      final profile = await _accountRepository.getUserProfile();

      if (profile != null) {
        emit(state.copyWith(
          profile: profile,
          isRefreshing: false,
        ));
      } else {
        emit(state.copyWith(
          isRefreshing: false,
          errorMessage: '重新整理失敗',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        errorMessage: '重新整理失敗',
      ));
    }
  }

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
