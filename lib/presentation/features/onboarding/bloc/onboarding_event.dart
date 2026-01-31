import 'package:equatable/equatable.dart';

/// Base class for onboarding events
abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

/// Event to validate school email domain
class OnboardingValidateEmail extends OnboardingEvent {
  final String email;

  const OnboardingValidateEmail(this.email);

  @override
  List<Object?> get props => [email];
}

/// Event to send verification code to school email
class OnboardingSendCode extends OnboardingEvent {
  final String schoolEmail;

  const OnboardingSendCode(this.schoolEmail);

  @override
  List<Object?> get props => [schoolEmail];
}

/// Event to verify the code entered by user
class OnboardingVerifyCode extends OnboardingEvent {
  final String schoolEmail;
  final String code;

  const OnboardingVerifyCode({
    required this.schoolEmail,
    required this.code,
  });

  @override
  List<Object?> get props => [schoolEmail, code];
}

/// Event to update basic info (nickname, gender and birthday)
class OnboardingUpdateBasicInfo extends OnboardingEvent {
  final String nickname;
  final String gender;
  final DateTime birthday;

  const OnboardingUpdateBasicInfo({
    required this.nickname,
    required this.gender,
    required this.birthday,
  });

  @override
  List<Object?> get props => [nickname, gender, birthday];
}

/// Event to clear any error state
class OnboardingClearError extends OnboardingEvent {
  const OnboardingClearError();
}

/// Event to reset the onboarding state
class OnboardingReset extends OnboardingEvent {
  const OnboardingReset();
}

/// Event to update cooldown timer
class OnboardingUpdateCooldown extends OnboardingEvent {
  final int seconds;

  const OnboardingUpdateCooldown(this.seconds);

  @override
  List<Object?> get props => [seconds];
}
