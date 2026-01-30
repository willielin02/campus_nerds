import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';

/// Auth state notifier for GoRouter refresh
///
/// Listens to Supabase auth changes and notifies the router
/// to rebuild when auth state changes.
class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier._() {
    _initialize();
  }

  static AuthStateNotifier? _instance;
  static AuthStateNotifier get instance => _instance ??= AuthStateNotifier._();

  StreamSubscription<AuthState>? _authSubscription;

  User? _user;
  bool _showSplashImage = true;
  String? _redirectLocation;
  bool _notifyOnAuthChange = true;
  bool _initialized = false;

  /// Current user (null if not authenticated)
  User? get user => _user;

  /// Whether the app is still loading (splash screen)
  bool get loading => !_initialized || _showSplashImage;

  /// Whether user is logged in
  bool get loggedIn => _user != null;

  /// Whether there's a pending redirect
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  /// Get and clear redirect location
  String? consumeRedirectLocation() {
    final location = _redirectLocation;
    _redirectLocation = null;
    return location;
  }

  /// Set redirect location if not already set
  void setRedirectLocationIfUnset(String location) {
    _redirectLocation ??= location;
  }

  /// Clear redirect location
  void clearRedirectLocation() {
    _redirectLocation = null;
  }

  /// Temporarily disable auth change notifications
  ///
  /// Useful when signing in/out and performing navigation
  /// to prevent multiple rebuilds.
  void updateNotifyOnAuthChange(bool notify) {
    _notifyOnAuthChange = notify;
  }

  /// Stop showing splash image
  void stopShowingSplashImage() {
    _showSplashImage = false;
    notifyListeners();
  }

  void _initialize() {
    // Get initial auth state
    _user = SupabaseService.currentUser;
    _initialized = true;

    // Listen to auth changes
    _authSubscription = SupabaseService.authStateChanges.listen(
      _onAuthStateChange,
      onError: (error) {
        debugPrint('Auth state error: $error');
      },
    );
  }

  void _onAuthStateChange(AuthState state) {
    final newUser = state.session?.user;
    final shouldUpdate = _user?.id != newUser?.id;

    _user = newUser;

    // Notify listeners on auth change unless explicitly disabled
    if (_notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }

    // Re-enable notifications after processing
    _notifyOnAuthChange = true;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
