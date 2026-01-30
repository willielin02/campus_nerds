/// Base class for custom exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Server exception (API errors)
class ServerException extends AppException {
  const ServerException({
    super.message = 'Server error occurred',
    super.code,
    super.originalError,
  });
}

/// Network exception (connection errors)
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network error occurred',
    super.code,
    super.originalError,
  });
}

/// Cache exception (storage errors)
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error occurred',
    super.code,
    super.originalError,
  });
}

/// Authentication exception
class AuthException extends AppException {
  const AuthException({
    super.message = 'Authentication error occurred',
    super.code,
    super.originalError,
  });
}

/// Validation exception
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.originalError,
  });
}
