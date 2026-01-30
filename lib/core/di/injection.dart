import 'package:get_it/get_it.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../presentation/features/auth/bloc/auth_bloc.dart';

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
}

void _registerBlocs() {
  // AuthBloc is registered as factory so each widget gets fresh instance
  // but can also be registered as singleton if needed globally
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );
}
