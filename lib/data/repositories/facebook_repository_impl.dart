import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import '../../core/services/supabase_service.dart';
import '../../domain/repositories/facebook_repository.dart';

/// Implementation of FacebookRepository using Facebook SDK and Supabase
class FacebookRepositoryImpl implements FacebookRepository {
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  @override
  Future<bool> isFacebookLinked() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return false;

    try {
      final response = await SupabaseService.from('users')
          .select('fb_user_id')
          .eq('id', userId)
          .maybeSingle();

      return response?['fb_user_id'] != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getFacebookUserId() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;

    try {
      final response = await SupabaseService.from('users')
          .select('fb_user_id')
          .eq('id', userId)
          .maybeSingle();

      return response?['fb_user_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<FacebookLinkResult> linkFacebookAccount() async {
    try {
      // Login with Facebook
      // Note: user_friends permission requires Facebook App Review
      // For now, we'll request it but it may only work in development mode
      final LoginResult result = await _facebookAuth.login(
        permissions: ['public_profile', 'user_friends'],
      );

      if (result.status != LoginStatus.success) {
        return FacebookLinkResult.failure(_getErrorMessage(result.status));
      }

      final accessToken = result.accessToken!.tokenString;

      // Get user's Facebook ID
      final userData = await _facebookAuth.getUserData();
      final fbUserId = userData['id'] as String?;

      if (fbUserId == null) {
        return FacebookLinkResult.failure('無法取得 Facebook 用戶 ID');
      }

      // Update user record with Facebook info
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        return FacebookLinkResult.failure('用戶未登入');
      }

      await SupabaseService.from('users').update({
        'fb_user_id': fbUserId,
        'fb_connected_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Sync friends via Edge Function
      await _syncFriendsToBackend(accessToken);

      return FacebookLinkResult.success(fbUserId);
    } catch (e) {
      return FacebookLinkResult.failure('臉書綁定失敗：${e.toString()}');
    }
  }

  @override
  Future<void> unlinkFacebookAccount() async {
    // Logout from Facebook SDK
    await _facebookAuth.logOut();

    // Clear Facebook data in database (including stored access token)
    final userId = SupabaseService.currentUserId;
    if (userId != null) {
      await SupabaseService.from('users').update({
        'fb_user_id': null,
        'fb_connected_at': null,
        'fb_last_sync_at': null,
        'fb_last_sync_status': null,
        'fb_access_token': null,
      }).eq('id', userId);
    }
  }

  /// Syncs friends to backend via Edge Function (internal use only)
  /// This is called when user first binds Facebook account
  Future<void> _syncFriendsToBackend(
    String accessToken, {
    bool storeToken = true, // Default to true for background sync support
  }) async {
    // Call Supabase Edge Function to sync friends
    // store_token: if true, exchanges for long-lived token and stores it
    // for background sync during auto-grouping (requires FB_APP_SECRET on server)
    await SupabaseService.client.functions.invoke(
      'sync-facebook-friends',
      body: {
        'access_token': accessToken,
        'store_token': storeToken,
      },
    );
    // Errors are logged on server side; we don't need to handle them here
    // since the binding was successful regardless of sync result
  }

  String _getErrorMessage(LoginStatus status) {
    switch (status) {
      case LoginStatus.cancelled:
        return '已取消臉書登入';
      case LoginStatus.failed:
        return '臉書登入失敗';
      case LoginStatus.operationInProgress:
        return '登入作業進行中';
      default:
        return '未知錯誤';
    }
  }
}
