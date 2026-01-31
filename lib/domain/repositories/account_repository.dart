import '../entities/user.dart';

/// Repository interface for account operations
abstract class AccountRepository {
  /// Get current user profile
  Future<UserProfile?> getUserProfile();

  /// Sign out the current user
  Future<void> logout();
}
