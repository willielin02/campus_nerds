import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../domain/repositories/auth_repository.dart';

/// Auth status for UI state
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  needsSchoolVerification,
  needsBasicInfo,
  error,
}

/// Auth BLoC state (named to avoid conflict with Supabase AuthState)
class AuthBlocState extends Equatable {
  final AuthStatus status;
  final User? user;
  final UserProfileStatus? profileStatus;
  final String? errorMessage;
  final bool isLoading;

  const AuthBlocState({
    this.status = AuthStatus.initial,
    this.user,
    this.profileStatus,
    this.errorMessage,
    this.isLoading = false,
  });

  /// Initial state
  factory AuthBlocState.initial() => const AuthBlocState();

  /// Loading state
  AuthBlocState copyWithLoading() => AuthBlocState(
        status: status,
        user: user,
        profileStatus: profileStatus,
        errorMessage: null,
        isLoading: true,
      );

  /// Authenticated state
  AuthBlocState copyWithAuthenticated({
    required User user,
    UserProfileStatus? profileStatus,
  }) {
    AuthStatus newStatus = AuthStatus.authenticated;

    // Determine if user needs onboarding
    if (profileStatus != null) {
      if (profileStatus.needsSchoolVerification) {
        newStatus = AuthStatus.needsSchoolVerification;
      } else if (profileStatus.needsBasicInfo) {
        newStatus = AuthStatus.needsBasicInfo;
      }
    }

    return AuthBlocState(
      status: newStatus,
      user: user,
      profileStatus: profileStatus,
      errorMessage: null,
      isLoading: false,
    );
  }

  /// Unauthenticated state
  factory AuthBlocState.unauthenticated() => const AuthBlocState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );

  /// Error state
  AuthBlocState copyWithError(String message) => AuthBlocState(
        status: AuthStatus.error,
        user: user,
        profileStatus: profileStatus,
        errorMessage: message,
        isLoading: false,
      );

  /// Clear error
  AuthBlocState clearError() => AuthBlocState(
        status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        user: user,
        profileStatus: profileStatus,
        errorMessage: null,
        isLoading: false,
      );

  /// Check if user is fully onboarded
  bool get isFullyOnboarded =>
      status == AuthStatus.authenticated &&
      profileStatus != null &&
      !profileStatus!.needsOnboarding;

  @override
  List<Object?> get props => [status, user, profileStatus, errorMessage, isLoading];
}
