import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../domain/entities/event.dart';
import '../../presentation/features/ticket_history/bloc/bloc.dart';
import '../../presentation/features/account/pages/account_page.dart';
import '../../presentation/features/auth/pages/login_page.dart';
import '../../presentation/features/checkout/pages/checkout_page.dart';
import '../../presentation/features/checkout/pages/payment_web_view_page.dart';
import '../../presentation/features/home/pages/games_booking_confirmation_page.dart';
import '../../presentation/features/home/pages/home_page.dart';
import '../../presentation/features/home/pages/study_booking_confirmation_page.dart';
import '../../presentation/features/my_events/pages/event_details_page.dart';
import '../../presentation/features/my_events/pages/my_events_page.dart';
import '../../presentation/features/onboarding/pages/basic_info_page.dart';
import '../../presentation/features/onboarding/pages/school_email_verification_page.dart';
import '../../presentation/features/ticket_history/pages/ticket_history_page.dart';
import 'app_routes.dart';
import 'auth_state_notifier.dart';

/// Global navigator key for accessing navigator state
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// App router configuration
///
/// Centralizes all route definitions and navigation logic.
/// Uses GoRouter with auth guards and shell routes for bottom navigation.
class AppRouter {
  AppRouter._();

  static GoRouter? _router;

  /// Get the router instance
  static GoRouter get router => _router ??= _createRouter();

  static GoRouter _createRouter() {
    final authNotifier = AuthStateNotifier.instance;

    return GoRouter(
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: true,
      navigatorKey: appNavigatorKey,
      refreshListenable: authNotifier,
      redirect: _globalRedirect,
      errorBuilder: _errorBuilder,
      routes: _routes,
    );
  }

  /// Global redirect logic
  static String? _globalRedirect(BuildContext context, GoRouterState state) {
    final authNotifier = AuthStateNotifier.instance;
    final isLoggedIn = authNotifier.loggedIn;
    final currentPath = state.matchedLocation;

    // Auth routes that don't require login
    final authRoutes = [
      AppRoutes.splash,
      AppRoutes.login,
    ];

    // Onboarding routes (require login but not complete profile)
    // Note: Used for future profile completion checks
    final onboardingRoutes = [
      AppRoutes.basicInfo,
      AppRoutes.schoolEmailVerification,
    ];

    final isAuthRoute = authRoutes.contains(currentPath);
    // ignore: unused_local_variable
    final isOnboardingRoute = onboardingRoutes.contains(currentPath);

    // Handle pending redirect after login
    if (authNotifier.shouldRedirect) {
      final redirect = authNotifier.consumeRedirectLocation();
      if (redirect != null && redirect != currentPath) {
        return redirect;
      }
    }

    // Not logged in - redirect to login for protected routes
    if (!isLoggedIn && !isAuthRoute) {
      authNotifier.setRedirectLocationIfUnset(currentPath);
      return AppRoutes.login;
    }

    // Logged in but on auth route - redirect to home
    if (isLoggedIn && isAuthRoute && currentPath != AppRoutes.splash) {
      return AppRoutes.home;
    }

    // Splash route - redirect based on auth state
    if (currentPath == AppRoutes.splash) {
      if (authNotifier.loading) {
        return null; // Stay on splash while loading
      }
      return isLoggedIn ? AppRoutes.home : AppRoutes.login;
    }

    return null;
  }

  /// Error page builder
  static Widget _errorBuilder(BuildContext context, GoRouterState state) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              '找不到頁面',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('返回首頁'),
            ),
          ],
        ),
      ),
    );
  }

  /// All routes
  static List<RouteBase> get _routes => [
        // Splash / Initial route
        GoRoute(
          path: AppRoutes.splash,
          name: AppRouteNames.splash,
          builder: (context, state) => const _SplashPage(),
        ),

        // Auth routes
        GoRoute(
          path: AppRoutes.login,
          name: AppRouteNames.login,
          builder: (context, state) {
            final allowGuest =
                state.uri.queryParameters['allowGuest'] != 'false';
            return LoginPage(allowGuest: allowGuest);
          },
        ),
        GoRoute(
          path: AppRoutes.basicInfo,
          name: AppRouteNames.basicInfo,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const BasicInfoPage(),
        ),
        GoRoute(
          path: AppRoutes.schoolEmailVerification,
          name: AppRouteNames.schoolEmailVerification,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const SchoolEmailVerificationPage(),
        ),

        // Main app with bottom navigation (Shell Route)
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return _MainShell(navigationShell: navigationShell);
          },
          branches: [
            // Home tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  name: AppRouteNames.home,
                  builder: (context, state) => const HomePage(),
                ),
              ],
            ),
            // My Events tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.myEvents,
                  name: AppRouteNames.myEvents,
                  builder: (context, state) => const MyEventsPage(),
                ),
              ],
            ),
            // Account tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.account,
                  name: AppRouteNames.account,
                  builder: (context, state) => const AccountPage(),
                ),
              ],
            ),
          ],
        ),

        // Event details routes (use root navigator - no navbar)
        GoRoute(
          path: AppRoutes.eventDetailsStudy,
          name: AppRouteNames.eventDetailsStudy,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) {
            final bookingId = state.uri.queryParameters['bookingId'] ?? '';
            return EventDetailsPage(
              bookingId: bookingId,
              isFocusedStudy: true,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.eventDetailsGames,
          name: AppRouteNames.eventDetailsGames,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) {
            final bookingId = state.uri.queryParameters['bookingId'] ?? '';
            return EventDetailsPage(
              bookingId: bookingId,
              isFocusedStudy: false,
            );
          },
        ),

        // Booking confirmation routes (use root navigator - no navbar)
        GoRoute(
          path: AppRoutes.studyBookingConfirmation,
          name: AppRouteNames.studyBookingConfirmation,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) {
            final event = state.extra as Event?;
            if (event == null) {
              return const _PlaceholderPage(title: 'Event not found');
            }
            return StudyBookingConfirmationPage(event: event);
          },
        ),
        GoRoute(
          path: AppRoutes.gamesBookingConfirmation,
          name: AppRouteNames.gamesBookingConfirmation,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) {
            final event = state.extra as Event?;
            if (event == null) {
              return const _PlaceholderPage(title: 'Event not found');
            }
            return GamesBookingConfirmationPage(event: event);
          },
        ),

        // Payment routes (use root navigator - no navbar)
        GoRoute(
          path: AppRoutes.checkout,
          name: AppRouteNames.checkout,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) {
            final tabIndex =
                int.tryParse(state.uri.queryParameters['tabIndex'] ?? '0') ?? 0;
            return CheckoutPage(initialTabIndex: tabIndex);
          },
        ),
        GoRoute(
          path: AppRoutes.paymentWebView,
          name: AppRouteNames.paymentWebView,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) {
            final paymentHtml = state.uri.queryParameters['paymentHtml'] ?? '';
            return PaymentWebViewPage(paymentHtml: paymentHtml);
          },
        ),

        // Ticket History route (use root navigator - no navbar)
        GoRoute(
          path: AppRoutes.ticketHistory,
          name: AppRouteNames.ticketHistory,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<TicketHistoryBloc>(),
            child: const TicketHistoryPage(),
          ),
        ),
      ];
}

/// Main shell with bottom navigation
class _MainShell extends StatelessWidget {
  const _MainShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFEEEEF1),
        selectedItemColor: const Color(0xFF57636C),
        unselectedItemColor: const Color(0xFFDBDBDD),
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 32),
            activeIcon: Icon(Icons.home, size: 32),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined, size: 32),
            activeIcon: Icon(Icons.event, size: 32),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined, size: 32),
            activeIcon: Icon(Icons.person, size: 32),
            label: '',
          ),
        ],
      ),
    );
  }
}

/// Splash page shown during initialization
class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    // Hide splash after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      AuthStateNotifier.instance.stopShowingSplashImage();
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Placeholder page for routes not yet implemented
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.title,
    this.params,
  });

  final String title;
  final Map<String, dynamic>? params;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (params != null && params!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Params: ${params.toString()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              '頁面開發中...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
