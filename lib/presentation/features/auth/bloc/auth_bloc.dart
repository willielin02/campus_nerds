import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent, AuthState;

import '../../../../app/router/auth_state_notifier.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth BLoC for managing authentication state
class AuthBloc extends Bloc<AuthEvent, AuthBlocState> {
  final AuthRepository _authRepository;
  StreamSubscription<AuthState>? _authStateSubscription;

  AuthBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(AuthBlocState.initial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthSignInWithEmail>(_onSignInWithEmail);
    on<AuthCreateAccount>(_onCreateAccount);
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
    on<AuthSignInWithApple>(_onSignInWithApple);
    on<AuthSignOut>(_onSignOut);
    on<AuthResetPassword>(_onResetPassword);
    on<AuthClearError>(_onClearError);

    // Listen to auth state changes
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (authState) {
        if (authState.event == AuthChangeEvent.signedIn ||
            authState.event == AuthChangeEvent.tokenRefreshed ||
            authState.event == AuthChangeEvent.initialSession) {
          add(const AuthCheckStatus());
        } else if (authState.event == AuthChangeEvent.signedOut) {
          // Use event to trigger state change instead of direct emit
          add(const AuthCheckStatus());
        }
      },
    );

    // Proactively check status if a session already exists (e.g. hot restart
    // or app relaunch). The initialSession event from Supabase's broadcast
    // stream may have fired before this subscription was set up.
    if (_authRepository.currentUser != null) {
      add(const AuthCheckStatus());
    }
  }

  /// Sync profile status to AuthStateNotifier so GoRouter can enforce onboarding.
  /// Only syncs when we have real data — null means the check failed and we
  /// should NOT mark as checked (avoids bypassing onboarding).
  void _syncProfileToRouter(UserProfileStatus? profileStatus) {
    if (profileStatus == null) return;
    AuthStateNotifier.instance.updateProfileStatus(
      needsBasicInfo: profileStatus.needsBasicInfo,
      needsSchoolVerification: profileStatus.needsSchoolVerification,
    );
  }

  /// Check current auth status
  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthBlocState> emit,
  ) async {
    final user = _authRepository.currentUser;
    if (user == null) {
      emit(AuthBlocState.unauthenticated());
      return;
    }

    try {
      // Get profile status to determine routing
      final profileStatus = await _authRepository.getUserProfileStatus();
      _syncProfileToRouter(profileStatus);
      emit(state.copyWithAuthenticated(
        user: user,
        profileStatus: profileStatus,
      ));
    } catch (e) {
      // On failure, assume user needs full onboarding (restrictive default).
      // This prevents the user from being stuck on splash forever, and
      // ensures they cannot bypass onboarding if the network call fails.
      const fallback = UserProfileStatus(
        hasUniversity: false,
        hasBasicInfo: false,
      );
      _syncProfileToRouter(fallback);
      emit(state.copyWithAuthenticated(user: user, profileStatus: fallback));
    }
  }

  /// Sign in with email
  Future<void> _onSignInWithEmail(
    AuthSignInWithEmail event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWithLoading());

    final result = await _authRepository.signInWithEmail(
      email: event.email,
      password: event.password,
    );

    if (result.success && result.user != null) {
      // Get profile status to determine routing
      final profileStatus = await _authRepository.getUserProfileStatus();
      _syncProfileToRouter(profileStatus);
      emit(state.copyWithAuthenticated(
        user: result.user!,
        profileStatus: profileStatus,
      ));
    } else {
      emit(state.copyWithError(result.errorMessage ?? '登入失敗'));
    }
  }

  /// Create account with email
  Future<void> _onCreateAccount(
    AuthCreateAccount event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWithLoading());

    final result = await _authRepository.createAccountWithEmail(
      email: event.email,
      password: event.password,
    );

    if (result.success && result.user != null) {
      // New accounts always need onboarding
      const profileStatus = UserProfileStatus(
        hasUniversity: false,
        hasBasicInfo: false,
      );
      _syncProfileToRouter(profileStatus);
      emit(state.copyWithAuthenticated(
        user: result.user!,
        profileStatus: profileStatus,
      ));
    } else {
      emit(state.copyWithError(result.errorMessage ?? '註冊失敗'));
    }
  }

  /// Sign in with Google
  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogle event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWithLoading());

    final result = await _authRepository.signInWithGoogle();

    if (result.success && result.user != null) {
      final profileStatus = await _authRepository.getUserProfileStatus();
      _syncProfileToRouter(profileStatus);
      emit(state.copyWithAuthenticated(
        user: result.user!,
        profileStatus: profileStatus,
      ));
    } else {
      emit(state.copyWithError(result.errorMessage ?? 'Google 登入失敗'));
    }
  }

  /// Sign in with Apple
  Future<void> _onSignInWithApple(
    AuthSignInWithApple event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWithLoading());

    final result = await _authRepository.signInWithApple();

    if (result.success && result.user != null) {
      final profileStatus = await _authRepository.getUserProfileStatus();
      _syncProfileToRouter(profileStatus);
      emit(state.copyWithAuthenticated(
        user: result.user!,
        profileStatus: profileStatus,
      ));
    } else {
      emit(state.copyWithError(result.errorMessage ?? 'Apple 登入失敗'));
    }
  }

  /// Sign out
  Future<void> _onSignOut(
    AuthSignOut event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWithLoading());
    await _authRepository.signOut();
    emit(AuthBlocState.unauthenticated());
  }

  /// Reset password
  Future<void> _onResetPassword(
    AuthResetPassword event,
    Emitter<AuthBlocState> emit,
  ) async {
    emit(state.copyWithLoading());

    final result = await _authRepository.resetPassword(email: event.email);

    if (result.success) {
      // Stay in current state but clear loading
      emit(AuthBlocState(
        status: state.status,
        user: state.user,
        profileStatus: state.profileStatus,
        errorMessage: null,
        isLoading: false,
      ));
    } else {
      emit(state.copyWithError(result.errorMessage ?? '重設密碼失敗'));
    }
  }

  /// Clear error
  void _onClearError(
    AuthClearError event,
    Emitter<AuthBlocState> emit,
  ) {
    emit(state.clearError());
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
