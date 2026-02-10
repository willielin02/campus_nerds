import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'app/router/router.dart';
import 'app/theme/app_theme.dart';
import 'core/di/injection.dart';
import 'core/services/supabase_service.dart';
import 'core/utils/app_clock.dart';
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

class _CampusNerdsAppState extends State<CampusNerdsApp> {
  ThemeMode _themeMode = AppTheme.themeMode;

  /// Update theme mode
  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    AppTheme.saveThemeMode(mode);
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
