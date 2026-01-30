import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication result wrapper
class AuthResult {
  final User? user;
  final String? errorMessage;
  final bool success;

  const AuthResult._({
    this.user,
    this.errorMessage,
    required this.success,
  });

  factory AuthResult.success(User user) => AuthResult._(
        user: user,
        success: true,
      );

  factory AuthResult.failure(String message) => AuthResult._(
        errorMessage: message,
        success: false,
      );
}

/// User profile status for routing decisions
class UserProfileStatus {
  final bool hasUniversity;
  final bool hasBasicInfo;
  final String? universityId;
  final String? gender;
  final DateTime? birthday;

  const UserProfileStatus({
    required this.hasUniversity,
    required this.hasBasicInfo,
    this.universityId,
    this.gender,
    this.birthday,
  });

  /// Check if user needs to complete onboarding
  bool get needsOnboarding => !hasUniversity || !hasBasicInfo;

  /// Check if user needs school email verification
  bool get needsSchoolVerification => !hasUniversity;

  /// Check if user needs basic info
  bool get needsBasicInfo => hasUniversity && !hasBasicInfo;
}

/// Abstract repository for authentication operations
abstract class AuthRepository {
  /// Get current user (null if not authenticated)
  User? get currentUser;

  /// Get current user ID (null if not authenticated)
  String? get currentUserId;

  /// Check if user is authenticated
  bool get isAuthenticated;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges;

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  });

  /// Create account with email and password
  Future<AuthResult> createAccountWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle();

  /// Sign in with Apple
  Future<AuthResult> signInWithApple();

  /// Sign out
  Future<void> signOut();

  /// Reset password
  Future<AuthResult> resetPassword({required String email});

  /// Update password
  Future<AuthResult> updatePassword({required String newPassword});

  /// Get user profile status for routing decisions
  Future<UserProfileStatus?> getUserProfileStatus();
}
