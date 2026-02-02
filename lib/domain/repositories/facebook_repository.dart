/// Result wrapper for Facebook link operations
class FacebookLinkResult {
  final bool success;
  final String? fbUserId;
  final String? errorMessage;

  const FacebookLinkResult._({
    required this.success,
    this.fbUserId,
    this.errorMessage,
  });

  factory FacebookLinkResult.success(String fbUserId) => FacebookLinkResult._(
        success: true,
        fbUserId: fbUserId,
      );

  factory FacebookLinkResult.failure(String message) => FacebookLinkResult._(
        success: false,
        errorMessage: message,
      );
}

/// Result wrapper for Facebook friends sync operations
class FacebookSyncResult {
  final bool success;
  final int friendsCount;
  final bool tokenStored; // Whether long-lived token was stored for background sync
  final String? errorMessage;

  const FacebookSyncResult._({
    required this.success,
    this.friendsCount = 0,
    this.tokenStored = false,
    this.errorMessage,
  });

  factory FacebookSyncResult.success(int friendsCount, {bool tokenStored = false}) =>
      FacebookSyncResult._(
        success: true,
        friendsCount: friendsCount,
        tokenStored: tokenStored,
      );

  factory FacebookSyncResult.failure(String message) => FacebookSyncResult._(
        success: false,
        errorMessage: message,
      );
}

/// Abstract repository for Facebook operations
abstract class FacebookRepository {
  /// Check if current user has Facebook linked
  Future<bool> isFacebookLinked();

  /// Get Facebook user ID if linked
  Future<String?> getFacebookUserId();

  /// Link Facebook account and sync friends
  /// Returns the Facebook user ID on success
  Future<FacebookLinkResult> linkFacebookAccount();

  /// Unlink Facebook account
  Future<void> unlinkFacebookAccount();

  /// Sync Facebook friends to backend
  /// This is called:
  /// 1. When user first links Facebook
  /// 2. Before auto-grouping (2 days before event)
  /// 3. When staff changes groups.status from draft to scheduled
  Future<FacebookSyncResult> syncFacebookFriends();
}
