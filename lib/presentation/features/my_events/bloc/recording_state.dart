import 'package:equatable/equatable.dart';

import '../../../../domain/entities/learning_report.dart';

/// 錄音流程的各個階段
enum RecordingPhase {
  initial,
  idle,
  recording,
  paused,
  stopped,
  uploading,
  analyzing,
  completed,
  error,
}

/// 本地暫存的錄音段落資訊
class LocalSegment extends Equatable {
  final String filePath;
  final int durationSeconds;
  final int sequence;
  final int fileSizeBytes;

  const LocalSegment({
    required this.filePath,
    required this.durationSeconds,
    required this.sequence,
    required this.fileSizeBytes,
  });

  @override
  List<Object?> get props => [filePath, durationSeconds, sequence, fileSizeBytes];
}

/// 錄音 BLoC 的狀態
class RecordingState extends Equatable {
  final RecordingPhase phase;
  final String? bookingId;
  final int currentSegmentSeconds;
  final List<LocalSegment> completedSegments;
  final int totalRecordedSeconds;
  final int uploadedCount;
  final LearningReport? learningReport;
  final bool hasPermission;
  final String? errorMessage;

  const RecordingState({
    this.phase = RecordingPhase.initial,
    this.bookingId,
    this.currentSegmentSeconds = 0,
    this.completedSegments = const [],
    this.totalRecordedSeconds = 0,
    this.uploadedCount = 0,
    this.learningReport,
    this.hasPermission = false,
    this.errorMessage,
  });

  /// 是否有段落可以上傳
  bool get hasSegmentsToUpload => completedSegments.isNotEmpty;

  /// 目前錄音中或暫停中
  bool get isRecordingActive =>
      phase == RecordingPhase.recording || phase == RecordingPhase.paused;

  /// 格式化的當前段錄音時長 MM:SS
  String get formattedCurrentDuration {
    final minutes = currentSegmentSeconds ~/ 60;
    final seconds = currentSegmentSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 格式化的總錄音時長 MM:SS
  String get formattedTotalDuration {
    final total = totalRecordedSeconds + currentSegmentSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  RecordingState copyWith({
    RecordingPhase? phase,
    String? bookingId,
    int? currentSegmentSeconds,
    List<LocalSegment>? completedSegments,
    int? totalRecordedSeconds,
    int? uploadedCount,
    LearningReport? learningReport,
    bool clearLearningReport = false,
    bool? hasPermission,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RecordingState(
      phase: phase ?? this.phase,
      bookingId: bookingId ?? this.bookingId,
      currentSegmentSeconds: currentSegmentSeconds ?? this.currentSegmentSeconds,
      completedSegments: completedSegments ?? this.completedSegments,
      totalRecordedSeconds: totalRecordedSeconds ?? this.totalRecordedSeconds,
      uploadedCount: uploadedCount ?? this.uploadedCount,
      learningReport: clearLearningReport
          ? null
          : (learningReport ?? this.learningReport),
      hasPermission: hasPermission ?? this.hasPermission,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        phase,
        bookingId,
        currentSegmentSeconds,
        completedSegments,
        totalRecordedSeconds,
        uploadedCount,
        learningReport,
        hasPermission,
        errorMessage,
      ];
}
