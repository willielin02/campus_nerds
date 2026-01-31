import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/tables/user_profile_v.dart';

/// Implementation of AuthRepository using Supabase
class AuthRepositoryImpl implements AuthRepository {
  // Google Sign-In client IDs
  static const String _googleClientIdIos =
      '733249908394-55lgm73d9mjpj8hj5p0n28mor6vt9dfe.apps.googleusercontent.com';
  static const String _googleServerClientId =
      '733249908394-9kr063g8q8t1729s0hulherp9j7k5pgc.apps.googleusercontent.com';

  // Apple Sign-In redirect URL for Android (web-based flow)
  static const String _appleRedirectUri =
      'https://lzafwlmznlkvmbdxcxop.supabase.co/auth/v1/callback';

  @override
  User? get currentUser => SupabaseService.currentUser;

  @override
  String? get currentUserId => SupabaseService.currentUserId;

  @override
  bool get isAuthenticated => SupabaseService.isAuthenticated;

  @override
  Stream<AuthState> get authStateChanges => SupabaseService.authStateChanges;

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return AuthResult.success(response.user!);
      }
      return AuthResult.failure('登入失敗');
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('發生未知錯誤，請稍後再試');
    }
  }

  @override
  Future<AuthResult> createAccountWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
      );

      // If email confirmation is required, user.lastSignInAt will be null
      if (response.user?.lastSignInAt == null) {
        return AuthResult.failure('請查看您的電子郵件以驗證帳號');
      }

      if (response.user != null) {
        return AuthResult.success(response.user!);
      }
      return AuthResult.failure('註冊失敗');
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('發生未知錯誤，請稍後再試');
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final success = await SupabaseService.client.auth.signInWithOAuth(
          OAuthProvider.google,
        );
        if (success) {
          // Wait for auth state change
          final user = SupabaseService.currentUser;
          if (user != null) {
            return AuthResult.success(user);
          }
        }
        return AuthResult.failure('Google 登入失敗');
      }

      // Native platform sign-in
      final googleSignIn = GoogleSignIn(
        scopes: ['profile', 'email'],
        clientId: _isAndroid ? null : _googleClientIdIos,
        serverClientId: _googleServerClientId,
      );

      // Sign out first to ensure fresh login
      await googleSignIn.signOut().catchError((_) => null);

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.failure('已取消 Google 登入');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        return AuthResult.failure('無法取得 Google 認證資訊');
      }

      final authResponse = await SupabaseService.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (authResponse.user != null) {
        return AuthResult.success(authResponse.user!);
      }
      return AuthResult.failure('Google 登入失敗');
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('Google 登入失敗：$e');
    }
  }

  @override
  Future<AuthResult> signInWithApple() async {
    try {
      if (kIsWeb) {
        await SupabaseService.client.auth.signInWithOAuth(
          OAuthProvider.apple,
          authScreenLaunchMode: LaunchMode.platformDefault,
        );

        // Wait for auth state change
        final authState = await SupabaseService.authStateChanges
            .timeout(const Duration(minutes: 5))
            .firstWhere((event) => event.event == AuthChangeEvent.signedIn);

        final user = authState.session?.user;
        if (user != null) {
          return AuthResult.success(user);
        }
        return AuthResult.failure('Apple 登入失敗');
      }

      // Native platform sign-in
      final rawNonce = SupabaseService.client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
        // Android requires web authentication options since Apple doesn't have native SDK
        webAuthenticationOptions: _isAndroid
            ? WebAuthenticationOptions(
                clientId: 'com.campusnerds.app.service',
                redirectUri: Uri.parse(_appleRedirectUri),
              )
            : null,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        return AuthResult.failure('無法取得 Apple 認證資訊');
      }

      final authResponse = await SupabaseService.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (authResponse.user != null) {
        return AuthResult.success(authResponse.user!);
      }
      return AuthResult.failure('Apple 登入失敗');
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('Apple 登入失敗：$e');
    }
  }

  @override
  Future<void> signOut() async {
    await SupabaseService.signOut();
  }

  @override
  Future<AuthResult> resetPassword({required String email}) async {
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email);
      return AuthResult.success(currentUser!);
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('發送重設密碼郵件失敗');
    }
  }

  @override
  Future<AuthResult> updatePassword({required String newPassword}) async {
    try {
      final response = await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (response.user != null) {
        return AuthResult.success(response.user!);
      }
      return AuthResult.failure('更新密碼失敗');
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('更新密碼失敗');
    }
  }

  @override
  Future<UserProfileStatus?> getUserProfileStatus() async {
    final userId = currentUserId;
    if (userId == null) return null;

    try {
      final profiles = await UserProfileVTable().queryRows(
        queryFn: (q) => q.eq('id', userId),
        limit: 1,
      );

      if (profiles.isEmpty) {
        // User exists in auth but no profile - needs full onboarding
        return const UserProfileStatus(
          hasUniversity: false,
          hasBasicInfo: false,
        );
      }

      final profile = profiles.first;
      final hasUniversity =
          profile.universityId != null && profile.universityId!.isNotEmpty;
      final hasBasicInfo = profile.gender != null &&
          profile.gender!.isNotEmpty &&
          profile.birthday != null;

      return UserProfileStatus(
        hasUniversity: hasUniversity,
        hasBasicInfo: hasBasicInfo,
        universityId: profile.universityId,
        gender: profile.gender,
        birthday: profile.birthday,
      );
    } catch (e) {
      debugPrint('Error getting user profile status: $e');
      return null;
    }
  }

  /// Translate Supabase auth errors to Chinese
  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return '電子郵件或密碼錯誤';
    }
    if (message.contains('User already registered')) {
      return '此電子郵件已被註冊';
    }
    if (message.contains('Email not confirmed')) {
      return '請先驗證您的電子郵件';
    }
    if (message.contains('Password should be at least')) {
      return '密碼長度至少需要 6 個字元';
    }
    if (message.contains('Invalid email')) {
      return '電子郵件格式不正確';
    }
    return '發生錯誤：$message';
  }

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
}
