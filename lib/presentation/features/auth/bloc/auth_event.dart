import 'package:equatable/equatable.dart';

/// Base class for auth events
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Sign in with email and password
class AuthSignInWithEmail extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInWithEmail({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Create account with email and password
class AuthCreateAccount extends AuthEvent {
  final String email;
  final String password;

  const AuthCreateAccount({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Sign in with Google
class AuthSignInWithGoogle extends AuthEvent {
  const AuthSignInWithGoogle();
}

/// Sign in with Apple
class AuthSignInWithApple extends AuthEvent {
  const AuthSignInWithApple();
}

/// Sign out
class AuthSignOut extends AuthEvent {
  const AuthSignOut();
}

/// Reset password
class AuthResetPassword extends AuthEvent {
  final String email;

  const AuthResetPassword({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Check current auth status and profile
class AuthCheckStatus extends AuthEvent {
  const AuthCheckStatus();
}

/// Clear error state
class AuthClearError extends AuthEvent {
  const AuthClearError();
}
