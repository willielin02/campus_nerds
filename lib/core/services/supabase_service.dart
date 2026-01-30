import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration and service
///
/// Provides centralized access to Supabase client throughout the app.
/// Initialize this service before running the app.
class SupabaseService {
  SupabaseService._();

  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  // Supabase project configuration
  // Note: These are public keys, safe to include in client code
  static const String _supabaseUrl = 'https://lzafwlmznlkvmbdxcxop.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6YWZ3bG16bmxrdm1iZHhjeG9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwNTcyODIsImV4cCI6MjA4MTYzMzI4Mn0.5i_r7IRg1ZDjFIvlki_Oy9IYQ6dCXeA5PrCZ-g-XAFQ';

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
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      headers: {
        'X-Client-Info': 'campus_nerds',
      },
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
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
