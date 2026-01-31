import '../entities/university.dart';

/// Result wrapper for onboarding operations
class OnboardingResult {
  final bool success;
  final String? errorMessage;
  final String? data;

  const OnboardingResult._({
    required this.success,
    this.errorMessage,
    this.data,
  });

  factory OnboardingResult.success([String? data]) => OnboardingResult._(
        success: true,
        data: data,
      );

  factory OnboardingResult.failure(String message) => OnboardingResult._(
        success: false,
        errorMessage: message,
      );
}

/// Abstract repository for onboarding operations
abstract class OnboardingRepository {
  /// Get all supported universities
  Future<List<University>> getUniversities();

  /// Get university by email domain
  /// Returns the university if the email domain is supported, null otherwise
  Future<University?> getUniversityByEmailDomain(String email);

  /// Send verification code to school email
  /// Returns success if email was sent, failure with error message otherwise
  Future<OnboardingResult> sendVerificationCode({
    required String schoolEmail,
  });

  /// Verify the code sent to school email
  /// Returns success if code is valid, failure with error message otherwise
  Future<OnboardingResult> verifyCode({
    required String schoolEmail,
    required String code,
  });

  /// Update user's basic info (nickname, gender and birthday)
  Future<OnboardingResult> updateBasicInfo({
    required String nickname,
    required String gender,
    required DateTime birthday,
  });

  /// Get remaining cooldown seconds for resending verification code
  /// Returns 0 if user can resend immediately
  Future<int> getResendCooldownSeconds(String schoolEmail);
}
