import 'package:equatable/equatable.dart';

import '../../../../domain/entities/university.dart';

/// Status for onboarding flow
enum OnboardingStatus {
  initial,
  loading,
  emailValidating,
  emailValid,
  emailInvalid,
  codeSent,
  codeVerifying,
  codeVerified,
  basicInfoUpdating,
  completed,
  error,
}

/// State for onboarding BLoC
class OnboardingState extends Equatable {
  final OnboardingStatus status;
  final String? schoolEmail;
  final University? university;
  final String? errorMessage;
  final int cooldownSeconds;
  final bool isLoading;

  const OnboardingState({
    this.status = OnboardingStatus.initial,
    this.schoolEmail,
    this.university,
    this.errorMessage,
    this.cooldownSeconds = 0,
    this.isLoading = false,
  });

  /// Check if user can resend code
  bool get canResendCode => cooldownSeconds <= 0 && !isLoading;

  /// Check if email is validated
  bool get isEmailValidated =>
      status == OnboardingStatus.emailValid ||
      status == OnboardingStatus.codeSent ||
      status == OnboardingStatus.codeVerifying ||
      status == OnboardingStatus.codeVerified;

  /// Check if code was sent successfully
  bool get isCodeSent =>
      status == OnboardingStatus.codeSent ||
      status == OnboardingStatus.codeVerifying ||
      status == OnboardingStatus.codeVerified;

  /// Check if verification is complete
  bool get isVerified => status == OnboardingStatus.codeVerified;

  OnboardingState copyWith({
    OnboardingStatus? status,
    String? schoolEmail,
    University? university,
    String? errorMessage,
    int? cooldownSeconds,
    bool? isLoading,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      schoolEmail: schoolEmail ?? this.schoolEmail,
      university: university ?? this.university,
      errorMessage: errorMessage,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  OnboardingState clearError() {
    return OnboardingState(
      status: status == OnboardingStatus.error
          ? OnboardingStatus.initial
          : status,
      schoolEmail: schoolEmail,
      university: university,
      errorMessage: null,
      cooldownSeconds: cooldownSeconds,
      isLoading: isLoading,
    );
  }

  @override
  List<Object?> get props => [
        status,
        schoolEmail,
        university,
        errorMessage,
        cooldownSeconds,
        isLoading,
      ];
}
