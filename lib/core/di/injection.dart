import 'package:get_it/get_it.dart';

import '../../data/repositories/account_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/repositories/checkout_repository_impl.dart';
import '../../data/repositories/facebook_repository_impl.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../data/repositories/my_events_repository_impl.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/repositories/ticket_history_repository_impl.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../../domain/repositories/facebook_repository.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/repositories/my_events_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../../domain/repositories/ticket_history_repository.dart';
import '../../presentation/features/account/bloc/account_bloc.dart';
import '../../presentation/features/auth/bloc/auth_bloc.dart';
import '../../presentation/features/chat/bloc/chat_bloc.dart';
import '../../presentation/features/checkout/bloc/checkout_bloc.dart';
import '../../presentation/features/home/bloc/home_bloc.dart';
import '../../presentation/features/my_events/bloc/feedback_bloc.dart';
import '../../presentation/features/my_events/bloc/my_events_bloc.dart';
import '../../presentation/features/my_events/bloc/recording_bloc.dart';
import '../../presentation/features/onboarding/bloc/onboarding_bloc.dart';
import '../../presentation/features/facebook_binding/bloc/facebook_binding_bloc.dart';
import '../../presentation/features/ticket_history/bloc/ticket_history_bloc.dart';

/// Global service locator
final getIt = GetIt.instance;

/// Initialize all dependencies
///
/// Call this in main() before runApp()
Future<void> configureDependencies() async {
  // Register services
  _registerServices();

  // Register repositories
  _registerRepositories();

  // Register BLoCs
  _registerBlocs();
}

void _registerServices() {
  // Services are registered in main.dart initialization
  // Supabase is initialized directly via SupabaseService.initialize()
}

void _registerRepositories() {
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(),
  );

  getIt.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(),
  );

  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(),
  );

  getIt.registerLazySingleton<MyEventsRepository>(
    () => MyEventsRepositoryImpl(),
  );

  getIt.registerLazySingleton<CheckoutRepository>(
    () => CheckoutRepositoryImpl(),
  );

  getIt.registerFactory<ChatRepository>(
    () => ChatRepositoryImpl(),
  );

  getIt.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(),
  );

  getIt.registerLazySingleton<TicketHistoryRepository>(
    () => TicketHistoryRepositoryImpl(),
  );

  getIt.registerLazySingleton<FacebookRepository>(
    () => FacebookRepositoryImpl(),
  );

  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(),
  );
}

void _registerBlocs() {
  // AuthBloc is registered as factory so each widget gets fresh instance
  // but can also be registered as singleton if needed globally
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerFactory<OnboardingBloc>(
    () => OnboardingBloc(
      onboardingRepository: getIt<OnboardingRepository>(),
      authRepository: getIt<AuthRepository>(),
    ),
  );

  getIt.registerFactory<HomeBloc>(
    () => HomeBloc(homeRepository: getIt<HomeRepository>()),
  );

  getIt.registerFactory<MyEventsBloc>(
    () => MyEventsBloc(myEventsRepository: getIt<MyEventsRepository>()),
  );

  // CheckoutBloc is singleton to cache products data across navigations
  getIt.registerLazySingleton<CheckoutBloc>(
    () => CheckoutBloc(
      checkoutRepository: getIt<CheckoutRepository>(),
      myEventsRepository: getIt<MyEventsRepository>(),
    ),
  );

  getIt.registerFactory<ChatBloc>(
    () => ChatBloc(chatRepository: getIt<ChatRepository>()),
  );

  getIt.registerFactory<AccountBloc>(
    () => AccountBloc(accountRepository: getIt<AccountRepository>()),
  );

  // TicketHistoryBloc is singleton to cache history data across navigations
  getIt.registerLazySingleton<TicketHistoryBloc>(
    () => TicketHistoryBloc(
      ticketHistoryRepository: getIt<TicketHistoryRepository>(),
    ),
  );

  // FacebookBindingBloc is singleton to cache binding status across navigations
  getIt.registerLazySingleton<FacebookBindingBloc>(
    () => FacebookBindingBloc(
      facebookRepository: getIt<FacebookRepository>(),
    ),
  );

  // RecordingBloc is factory — each EventDetailsPage gets its own instance
  getIt.registerFactory<RecordingBloc>(
    () => RecordingBloc(repository: getIt<MyEventsRepository>()),
  );

  // FeedbackBloc is factory — each FeedbackPage gets its own instance
  getIt.registerFactory<FeedbackBloc>(
    () => FeedbackBloc(repository: getIt<MyEventsRepository>()),
  );
}
