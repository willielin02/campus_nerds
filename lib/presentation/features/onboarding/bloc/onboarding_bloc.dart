import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/repositories/auth_repository.dart';
import '../../../../domain/repositories/onboarding_repository.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// Onboarding BLoC for managing school email verification and basic info
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingRepository _onboardingRepository;
  final AuthRepository _authRepository;
  Timer? _cooldownTimer;

  OnboardingBloc({
    required OnboardingRepository onboardingRepository,
    required AuthRepository authRepository,
  })  : _onboardingRepository = onboardingRepository,
        _authRepository = authRepository,
        super(const OnboardingState()) {
    on<OnboardingValidateEmail>(_onValidateEmail);
    on<OnboardingSendCode>(_onSendCode);
    on<OnboardingVerifyCode>(_onVerifyCode);
    on<OnboardingUpdateBasicInfo>(_onUpdateBasicInfo);
    on<OnboardingClearError>(_onClearError);
    on<OnboardingReset>(_onReset);
    on<OnboardingUpdateCooldown>(_onUpdateCooldown);
  }

  /// Validate email domain against supported universities
  Future<void> _onValidateEmail(
    OnboardingValidateEmail event,
    Emitter<OnboardingState> emit,
  ) async {
    if (event.email.isEmpty) {
      emit(state.copyWith(
        status: OnboardingStatus.initial,
        schoolEmail: null,
        university: null,
      ));
      return;
    }

    emit(state.copyWith(
      status: OnboardingStatus.emailValidating,
      isLoading: true,
    ));

    final university =
        await _onboardingRepository.getUniversityByEmailDomain(event.email);

    if (university != null) {
      emit(state.copyWith(
        status: OnboardingStatus.emailValid,
        schoolEmail: event.email,
        university: university,
        isLoading: false,
      ));
    } else {
      emit(state.copyWith(
        status: OnboardingStatus.emailInvalid,
        schoolEmail: event.email,
        university: null,
        errorMessage: '此電子郵件網域不屬於任何支援的大學',
        isLoading: false,
      ));
    }
  }

  /// Send verification code to school email
  Future<void> _onSendCode(
    OnboardingSendCode event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(
      status: OnboardingStatus.loading,
      isLoading: true,
      cooldownSeconds: 60,
    ));

    final result = await _onboardingRepository.sendVerificationCode(
      schoolEmail: event.schoolEmail,
    );

    if (result.success) {
      emit(state.copyWith(
        status: OnboardingStatus.codeSent,
        schoolEmail: event.schoolEmail,
        isLoading: false,
      ));
      _startCooldownTimer();
    } else {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: result.errorMessage ?? '發送驗證碼失敗',
        isLoading: false,
        cooldownSeconds: 0,
      ));
    }
  }

  /// Verify the code entered by user
  /// After verification, checks if user already has basic info:
  /// - If yes, navigates to Home (via completed status)
  /// - If no, navigates to BasicInfo (via codeVerified status)
  Future<void> _onVerifyCode(
    OnboardingVerifyCode event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(
      status: OnboardingStatus.codeVerifying,
      isLoading: true,
    ));

    final result = await _onboardingRepository.verifyCode(
      schoolEmail: event.schoolEmail,
      code: event.code,
    );

    if (result.success) {
      _cancelCooldownTimer();

      // Check if user already has basic info (matching FlutterFlow logic)
      // If user has gender, birthday, nickname, os -> go to Home
      // Otherwise -> go to BasicInfo
      final profileStatus = await _authRepository.getUserProfileStatus();

      if (profileStatus != null && profileStatus.hasBasicInfo) {
        // User already has basic info, go directly to Home
        emit(state.copyWith(
          status: OnboardingStatus.completed,
          isLoading: false,
          cooldownSeconds: 0,
        ));
      } else {
        // User needs to fill basic info
        emit(state.copyWith(
          status: OnboardingStatus.codeVerified,
          isLoading: false,
          cooldownSeconds: 0,
        ));
      }
    } else {
      emit(state.copyWith(
        status: OnboardingStatus.codeSent, // Stay on code entry
        errorMessage: result.errorMessage ?? '驗證碼無效',
        isLoading: false,
      ));
    }
  }

  /// Update user's basic info
  Future<void> _onUpdateBasicInfo(
    OnboardingUpdateBasicInfo event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(
      status: OnboardingStatus.basicInfoUpdating,
      isLoading: true,
    ));

    final result = await _onboardingRepository.updateBasicInfo(
      nickname: event.nickname,
      gender: event.gender,
      birthday: event.birthday,
    );

    if (result.success) {
      emit(state.copyWith(
        status: OnboardingStatus.completed,
        isLoading: false,
      ));
    } else {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: result.errorMessage ?? '更新資料失敗',
        isLoading: false,
      ));
    }
  }

  /// Clear error state
  void _onClearError(
    OnboardingClearError event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.clearError());
  }

  /// Reset onboarding state
  void _onReset(
    OnboardingReset event,
    Emitter<OnboardingState> emit,
  ) {
    _cancelCooldownTimer();
    emit(const OnboardingState());
  }

  /// Update cooldown timer
  void _onUpdateCooldown(
    OnboardingUpdateCooldown event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(cooldownSeconds: event.seconds));
  }

  void _startCooldownTimer() {
    _cancelCooldownTimer();
    _cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        final newCooldown = state.cooldownSeconds - 1;
        if (newCooldown <= 0) {
          timer.cancel();
          add(const OnboardingUpdateCooldown(0));
        } else {
          add(OnboardingUpdateCooldown(newCooldown));
        }
      },
    );
  }

  void _cancelCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
  }

  @override
  Future<void> close() {
    _cancelCooldownTimer();
    return super.close();
  }
}
