import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../../domain/entities/event.dart';
import '../../presentation/features/my_events/bloc/bloc.dart';
import '../../presentation/features/account/pages/account_page.dart';
import '../../presentation/features/auth/pages/login_page.dart';
import '../../presentation/features/checkout/pages/checkout_page.dart';
import '../../presentation/features/home/pages/games_booking_confirmation_page.dart';
import '../../presentation/features/home/pages/home_page.dart';
import '../../presentation/features/home/pages/study_booking_confirmation_page.dart';
import '../../presentation/features/my_events/pages/event_details_page.dart';
import '../../presentation/features/my_events/pages/my_events_page.dart';
import '../../presentation/features/onboarding/pages/basic_info_page.dart';
import '../../presentation/features/onboarding/pages/school_email_verification_page.dart';
import '../../presentation/features/ticket_history/pages/ticket_history_page.dart';
import '../../presentation/features/facebook_binding/pages/facebook_binding_page.dart';
import '../../presentation/features/account/pages/contact_support_page.dart';
import '../../presentation/features/account/pages/faq_page.dart';
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
    final onboardingRoutes = [
      AppRoutes.basicInfo,
      AppRoutes.schoolEmailVerification,
    ];

    final isAuthRoute = authRoutes.contains(currentPath);
    final isOnboardingRoute = onboardingRoutes.contains(currentPath);

    // Splash route - redirect based on auth state
    if (currentPath == AppRoutes.splash) {
      if (authNotifier.loading) {
        return null; // Stay on splash while loading
      }
      if (!isLoggedIn) {
        return AppRoutes.login;
      }
      // For authenticated non-guest users, wait for profile check before
      // proceeding. Without this, the user would land on /home before the
      // async profile fetch completes, bypassing onboarding enforcement.
      if (!authNotifier.isGuestMode && !authNotifier.profileChecked) {
        return null; // Stay on splash until profile is checked
      }
      return AppRoutes.home;
    }

    // Not logged in - redirect to login for protected routes
    if (!isLoggedIn && !isAuthRoute) {
      authNotifier.setRedirectLocationIfUnset(currentPath);
      return AppRoutes.login;
    }

    // Logged in but on auth route - redirect to home (or onboarding)
    if (isLoggedIn && isAuthRoute) {
      // Wait for profile check before leaving auth route, so the user
      // doesn't briefly flash through /home before being sent to onboarding.
      if (!authNotifier.isGuestMode && !authNotifier.profileChecked) {
        return null; // Stay on current auth route until profile is checked
      }
      return AppRoutes.home;
    }

    // Onboarding enforcement (skip for guest mode, skip if profile not yet loaded)
    if (isLoggedIn && !authNotifier.isGuestMode && authNotifier.profileChecked) {
      final needsSchool = authNotifier.needsSchoolVerification;
      final needsBasic = authNotifier.needsBasicInfo;

      // Must verify school email first
      if (needsSchool && currentPath != AppRoutes.schoolEmailVerification) {
        return AppRoutes.schoolEmailVerification;
      }

      // Must fill basic info (nickname, birthday, gender, OS)
      if (needsBasic && currentPath != AppRoutes.basicInfo) {
        return AppRoutes.basicInfo;
      }

      // Fully onboarded but still on onboarding route → go home
      if (!needsSchool && !needsBasic && isOnboardingRoute) {
        return AppRoutes.home;
      }
    }

    // Handle pending redirect after login
    if (authNotifier.shouldRedirect) {
      final redirect = authNotifier.consumeRedirectLocation();
      if (redirect != null && redirect != currentPath) {
        return redirect;
      }
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
            final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
            return EventDetailsPage(
              bookingId: bookingId,
              isFocusedStudy: true,
              initialTab: tab,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.eventDetailsGames,
          name: AppRouteNames.eventDetailsGames,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) {
            final bookingId = state.uri.queryParameters['bookingId'] ?? '';
            final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
            return EventDetailsPage(
              bookingId: bookingId,
              isFocusedStudy: false,
              initialTab: tab,
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
        // Ticket History route (use root navigator - no navbar)
        // BLoC is provided at app level in main.dart (singleton)
        GoRoute(
          path: AppRoutes.ticketHistory,
          name: AppRouteNames.ticketHistory,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const TicketHistoryPage(),
        ),

        // Facebook Binding route (use root navigator - no navbar)
        GoRoute(
          path: AppRoutes.facebookBinding,
          name: AppRouteNames.facebookBinding,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const FacebookBindingPage(),
        ),

        // Contact Support route (use root navigator - no navbar)
        GoRoute(
          path: AppRoutes.contactSupport,
          name: AppRouteNames.contactSupport,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const ContactSupportPage(),
        ),

        // FAQ route (use root navigator - no navbar)
        GoRoute(
          path: AppRoutes.faq,
          name: AppRouteNames.faq,
          parentNavigatorKey: appNavigatorKey,
          builder: (context, state) => const FaqPage(),
        ),
      ];
}

/// Main shell with bottom navigation
class _MainShell extends StatefulWidget {
  const _MainShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..value = 1.0;
    _offsetAnimation = _buildOffsetAnimation(true);
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    // 預先載入 MyEvents 資料（含未讀訊息數）以供 navbar badge 使用
    final bloc = context.read<MyEventsBloc>();
    if (bloc.state.status == MyEventsStatus.initial) {
      bloc.add(const MyEventsLoadData());
    }
  }

  Animation<Offset> _buildOffsetAnimation(bool isForward) {
    return Tween<Offset>(
      begin: Offset(isForward ? 0.25 : -0.25, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIndex = oldWidget.navigationShell.currentIndex;
    final newIndex = widget.navigationShell.currentIndex;
    if (oldIndex != newIndex) {
      _offsetAnimation = _buildOffsetAnimation(newIndex > oldIndex);
      _animController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MyEventsBloc, MyEventsState, int>(
      selector: (state) => state.totalUnreadMessageCount,
      builder: (context, unreadCount) {
        return Scaffold(
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _offsetAnimation,
              child: widget.navigationShell,
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFFEEEEF1),
            selectedItemColor: const Color(0xFF57636C),
            unselectedItemColor: const Color(0xFFDBDBDD),
            currentIndex: widget.navigationShell.currentIndex,
            onTap: (index) => widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            ),
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 32),
                activeIcon: Icon(Icons.home, size: 32),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _buildMyEventsIcon(Icons.event_outlined, unreadCount),
                activeIcon: _buildMyEventsIcon(Icons.event, unreadCount),
                label: '',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outlined, size: 32),
                activeIcon: Icon(Icons.person, size: 32),
                label: '',
              ),
            ],
          ),
        );
      },
    );
  }

  /// 建立 MyEvents 圖示，含未讀訊息 badge
  Widget _buildMyEventsIcon(IconData iconData, int unreadCount) {
    if (unreadCount <= 0) return Icon(iconData, size: 32);

    final colors = context.appColors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(iconData, size: 32),
        Positioned(
          top: -6,
          right: -8,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: colors.tertiaryText,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: TextStyle(
                fontFamily: GoogleFonts.notoSansTc().fontFamily,
                color: colors.secondaryBackground,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
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
