import 'package:equatable/equatable.dart';

/// Learning report status types
enum LearningReportStatus {
  pending('pending'),
  transcribing('transcribing'),
  analyzing('analyzing'),
  completed('completed'),
  failed('failed');

  final String value;
  const LearningReportStatus(this.value);

  static LearningReportStatus fromString(String value) {
    return LearningReportStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LearningReportStatus.pending,
    );
  }
}

/// A single fix example (original sentence → better alternative)
class FixExample extends Equatable {
  final String original;
  final String better;

  const FixExample({required this.original, required this.better});

  factory FixExample.fromJson(Map<String, dynamic> json) => FixExample(
        original: json['original'] as String? ?? '',
        better: json['better'] as String? ?? '',
      );

  @override
  List<Object?> get props => [original, better];
}

/// One of the top 3 recurring habits to fix
class TopFix extends Equatable {
  final String habit;
  final String frequency;
  final List<FixExample> examples;
  final String why;

  const TopFix({
    required this.habit,
    required this.frequency,
    required this.examples,
    required this.why,
  });

  factory TopFix.fromJson(Map<String, dynamic> json) => TopFix(
        habit: json['habit'] as String? ?? '',
        frequency: json['frequency'] as String? ?? '',
        examples: (json['examples'] as List<dynamic>?)
                ?.map((e) => FixExample.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        why: json['why'] as String? ?? '',
      );

  @override
  List<Object?> get props => [habit, frequency, examples, why];
}

/// AI-generated learning report for an English Games session
class LearningReport extends Equatable {
  final String id;
  final String bookingId;
  final String userId;
  final LearningReportStatus status;
  final String? transcript;
  final String? errorMessage;
  final List<String> strengths;
  final List<TopFix> topFixes;
  final String? summary;
  final int totalDurationSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LearningReport({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.status,
    this.transcript,
    this.errorMessage,
    this.strengths = const [],
    this.topFixes = const [],
    this.summary,
    this.totalDurationSeconds = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether the report is still being processed
  bool get isProcessing =>
      status == LearningReportStatus.transcribing ||
      status == LearningReportStatus.analyzing;

  /// Whether the report is completed
  bool get isCompleted => status == LearningReportStatus.completed;

  /// Whether the report has failed
  bool get isFailed => status == LearningReportStatus.failed;

  /// Formatted total duration as MM:SS
  String get formattedDuration {
    final minutes = totalDurationSeconds ~/ 60;
    final seconds = totalDurationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        userId,
        status,
        transcript,
        errorMessage,
        strengths,
        topFixes,
        summary,
        totalDurationSeconds,
        createdAt,
        updatedAt,
      ];
}
