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

/// Abstract repository for Facebook operations
abstract class FacebookRepository {
  /// Check if current user has Facebook linked
  Future<bool> isFacebookLinked();

  /// Get Facebook user ID if linked
  Future<String?> getFacebookUserId();

  /// Link Facebook account and sync friends
  /// Friends are synced automatically during:
  /// 1. Initial binding (handled internally by linkFacebookAccount)
  /// 2. Auto-grouping cron job (via Edge Function)
  /// 3. Staff confirmation (via Edge Function)
  Future<FacebookLinkResult> linkFacebookAccount();

  /// Unlink Facebook account
  Future<void> unlinkFacebookAccount();
}
