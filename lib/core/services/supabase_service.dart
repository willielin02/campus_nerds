import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Supabase configuration and service
///
/// Provides centralized access to Supabase client throughout the app.
/// Initialize this service before running the app.
class SupabaseService {
  SupabaseService._();

  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get current user (null if not authenticated)
  static User? get currentUser => client.auth.currentUser;

  /// Get current session (null if not authenticated)
  static Session? get currentSession => client.auth.currentSession;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get current user ID (null if not authenticated)
  static String? get currentUserId => currentUser?.id;

  /// Get current user email (null if not authenticated)
  static String? get currentUserEmail => currentUser?.email;

  /// Get auth state changes stream
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Initialize Supabase
  ///
  /// Must be called before using any Supabase features.
  /// Typically called in main() before runApp().
  static Future<void> initialize() async {
    debugPrint('Supabase ENV: ${AppConfig.envName} → ${AppConfig.supabaseUrl}');

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      headers: {
        'X-Client-Info': 'campus_nerds',
      },
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );

    // 環境切換保護：如果本地存的 JWT 來自不同專案，自動登出
    await _clearSessionIfWrongProject();
  }

  /// 檢查本地 session 的 JWT ref 是否匹配當前環境的專案
  static Future<void> _clearSessionIfWrongProject() async {
    final token = currentSession?.accessToken;
    if (token == null) return;

    try {
      // 解析 JWT payload（不需驗證簽名，只看 ref claim）
      final parts = token.split('.');
      if (parts.length != 3) return;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final claims = jsonDecode(payload) as Map<String, dynamic>;
      final tokenRef = claims['ref'] as String?;

      // 從當前 URL 取得 project ref
      final currentRef = Uri.parse(AppConfig.supabaseUrl).host.split('.').first;

      if (tokenRef != null && tokenRef != currentRef) {
        debugPrint('Session token ref ($tokenRef) != current project ($currentRef), signing out');
        await client.auth.signOut();
      }
    } catch (e) {
      debugPrint('Failed to check session project: $e');
    }
  }

  /// Sign out current user
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Get JWT token for current session
  static String? get jwtToken => currentSession?.accessToken;

  // ============================================
  // Database Query Helpers
  // ============================================

  /// Get a table reference for queries
  static SupabaseQueryBuilder from(String table) => client.from(table);

  /// Call an RPC function
  static PostgrestFilterBuilder<T> rpc<T>(
    String functionName, {
    Map<String, dynamic>? params,
  }) {
    return client.rpc(functionName, params: params);
  }

  // ============================================
  // Realtime Helpers
  // ============================================

  /// Subscribe to realtime changes on a table
  static RealtimeChannel channel(String name) => client.channel(name);

  /// Remove a realtime channel subscription
  static Future<void> removeChannel(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }
}
