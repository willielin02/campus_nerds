import 'package:equatable/equatable.dart';

/// 問卷提交的狀態
enum FeedbackStatus {
  initial,
  submitting,
  success,
  error,
}

class FeedbackState extends Equatable {
  final FeedbackStatus status;
  final String? errorMessage;

  const FeedbackState({
    this.status = FeedbackStatus.initial,
    this.errorMessage,
  });

  bool get isSubmitting => status == FeedbackStatus.submitting;
  bool get isSuccess => status == FeedbackStatus.success;

  FeedbackState copyWith({
    FeedbackStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FeedbackState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
