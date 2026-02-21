import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent, AuthState;

import 'app/router/router.dart';
import 'app/theme/app_theme.dart';
import 'core/di/injection.dart';
import 'core/firebase/firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'core/utils/app_clock.dart';
import 'domain/entities/app_notification.dart';
import 'domain/repositories/notification_repository.dart';
import 'presentation/common/widgets/notification_dialog.dart';
import 'presentation/features/account/bloc/bloc.dart';
import 'presentation/features/auth/bloc/bloc.dart';
import 'presentation/features/chat/bloc/bloc.dart';
import 'presentation/features/checkout/bloc/bloc.dart';
import 'presentation/features/home/bloc/bloc.dart';
import 'presentation/features/my_events/bloc/bloc.dart';
import 'presentation/features/onboarding/bloc/bloc.dart';
import 'presentation/features/facebook_binding/bloc/bloc.dart';
import 'presentation/features/ticket_history/bloc/bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable URL reflection for GoRouter
  GoRouter.optionURLReflectsImperativeAPIs = true;

  // Initialize services
  await _initializeServices();

  runApp(const CampusNerdsApp());
}

/// Initialize all app services
Future<void> _initializeServices() async {
  // Initialize Firebase (skip on web — no web config)
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Initialize Supabase
  await SupabaseService.initialize();

  // Sync clock with server (supports mock time for testing)
  await AppClock.syncWithServer();

  // Initialize theme (SharedPreferences)
  await AppTheme.initialize();

  // Initialize dependency injection
  await configureDependencies();
}

/// Root application widget
class CampusNerdsApp extends StatefulWidget {
  const CampusNerdsApp({super.key});

  @override
  State<CampusNerdsApp> createState() => _CampusNerdsAppState();

  /// Access app state from anywhere in widget tree
  static _CampusNerdsAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_CampusNerdsAppState>()!;
}

class _CampusNerdsAppState extends State<CampusNerdsApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = AppTheme.themeMode;
  StreamSubscription<AppNotification>? _realtimeNotifSub;
  StreamSubscription<List<AppNotification>>? _unreadNotifSub;
  StreamSubscription<AuthState>? _authSub;
  bool _notificationsInitialized = false;
  bool _isShowingNotification = false;

  /// Update theme mode
  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    AppTheme.saveThemeMode(mode);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen to auth state to init/dispose notification service
    _authSub = SupabaseService.authStateChanges.listen((authState) {
      final event = authState.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        _initNotifications();
      } else if (event == AuthChangeEvent.signedOut) {
        _disposeNotifications();
      }
    });

    // If already authenticated, init notifications
    if (SupabaseService.isAuthenticated) {
      // Delay to ensure navigator is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initNotifications();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _realtimeNotifSub?.cancel();
    _unreadNotifSub?.cancel();
    _authSub?.cancel();
    NotificationService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _notificationsInitialized) {
      // Only check notifications on appropriate pages (main tabs + event details)
      // Avoid interrupting active flows like booking, checkout, or Facebook binding
      if (_canShowNotificationOnCurrentRoute()) {
        NotificationService.instance.checkUnreadNotifications();
      }
    }
  }

  /// Check if the current route is appropriate for showing notification dialogs.
  /// Only show on "resting" pages, not during active flows.
  bool _canShowNotificationOnCurrentRoute() {
    try {
      final path = AppRouter.router.routeInformationProvider.value.uri.path;
      const allowedRoutes = [
        AppRoutes.home,
        AppRoutes.myEvents,
        AppRoutes.account,
        AppRoutes.eventDetailsStudy,
        AppRoutes.eventDetailsGames,
      ];
      return allowedRoutes.any((route) => path.startsWith(route));
    } catch (_) {
      return false;
    }
  }

  Future<void> _initNotifications() async {
    if (_notificationsInitialized) return;
    _notificationsInitialized = true;

    final repository = getIt<NotificationRepository>();
    await NotificationService.instance.initialize(repository);

    // Listen for realtime notifications (foreground)
    _realtimeNotifSub = NotificationService.instance.onNotification.listen(
      (notification) => _showNotificationDialog(notification),
    );

    // Listen for unread notifications (on init / app resume)
    _unreadNotifSub = NotificationService.instance.onUnreadNotifications.listen(
      (notifications) {
        if (notifications.isNotEmpty) {
          _showNotificationDialog(notifications.first);
        }
      },
    );
  }

  Future<void> _disposeNotifications() async {
    _notificationsInitialized = false;
    _realtimeNotifSub?.cancel();
    _realtimeNotifSub = null;
    _unreadNotifSub?.cancel();
    _unreadNotifSub = null;
    await NotificationService.instance.dispose();
  }

  void _showNotificationDialog(AppNotification notification) async {
    // Prevent duplicate dialogs
    if (_isShowingNotification) return;

    // Only show on appropriate pages (not during active flows)
    if (!_canShowNotificationOnCurrentRoute()) return;

    final navigatorContext = appNavigatorKey.currentContext;
    if (navigatorContext == null) return;

    _isShowingNotification = true;

    try {
      await showNotificationDialog(
        context: navigatorContext,
        notification: notification,
        onDismiss: (notif) {
          // Mark as read
          NotificationService.instance.markAsRead(notif.id);

          // Navigate to event details page
          if (notif.bookingId != null) {
            final category = notif.data?['category'] as String?;
            final isFocusedStudy = category != 'english_games';
            final route = isFocusedStudy
                ? AppRoutes.eventDetailsStudy
                : AppRoutes.eventDetailsGames;
            final tab = notif.type == NotificationType.chatOpen ? 1 : 0;
            appNavigatorKey.currentContext?.go(
              '$route?bookingId=${notif.bookingId}&tab=$tab',
            );
          }
        },
      );
    } catch (_) {
      // Dialog show failed (e.g., invalid context)
    } finally {
      _isShowingNotification = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          lazy: false,
          create: (_) => getIt<AuthBloc>()..add(const AuthCheckStatus()),
        ),
        BlocProvider<OnboardingBloc>(
          create: (_) => getIt<OnboardingBloc>(),
        ),
        BlocProvider<HomeBloc>(
          create: (_) => getIt<HomeBloc>(),
        ),
        BlocProvider<MyEventsBloc>(
          create: (_) => getIt<MyEventsBloc>(),
        ),
        BlocProvider<CheckoutBloc>(
          create: (_) => getIt<CheckoutBloc>(),
        ),
        BlocProvider<ChatBloc>(
          create: (_) => getIt<ChatBloc>(),
        ),
        BlocProvider<AccountBloc>(
          create: (_) => getIt<AccountBloc>(),
        ),
        BlocProvider<TicketHistoryBloc>(
          create: (_) => getIt<TicketHistoryBloc>(),
        ),
        BlocProvider<FacebookBindingBloc>(
          create: (_) => getIt<FacebookBindingBloc>(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Campus Nerds',
        scrollBehavior: _AppScrollBehavior(),

        // Localization - Traditional Chinese (Taiwan)
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
          Locale('en'),
        ],
        locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),

        // Theme
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,

        // Router
        routerConfig: AppRouter.router,
      ),
    );
  }
}

/// Custom scroll behavior to enable mouse drag on desktop
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
