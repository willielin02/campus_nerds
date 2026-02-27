import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../domain/repositories/my_events_repository.dart';
import 'recording_event.dart';
import 'recording_state.dart';

class RecordingBloc extends Bloc<RecordingEvent, RecordingState> {
  final MyEventsRepository repository;

  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  Timer? _pollTimer;
  int _nextSequence = 1;

  RecordingBloc({required this.repository}) : super(const RecordingState()) {
    on<RecordingInitialize>(_onInitialize);
    on<RecordingStart>(_onStart);
    on<RecordingPause>(_onPause);
    on<RecordingResume>(_onResume);
    on<RecordingStop>(_onStop);
    on<RecordingTimerTick>(_onTimerTick);
    on<RecordingUploadAndAnalyze>(_onUploadAndAnalyze);
    on<RecordingLoadReport>(_onLoadReport);
  }

  Future<void> _onInitialize(
    RecordingInitialize event,
    Emitter<RecordingState> emit,
  ) async {
    // 檢查是否已有報告
    final report = await repository.getLearningReport(event.bookingId);
    if (report != null) {
      if (report.isCompleted) {
        emit(state.copyWith(
          phase: RecordingPhase.completed,
          bookingId: event.bookingId,
          learningReport: report,
          hasPermission: true,
        ));
        return;
      }
      if (report.isProcessing) {
        emit(state.copyWith(
          phase: RecordingPhase.analyzing,
          bookingId: event.bookingId,
          learningReport: report,
          hasPermission: true,
        ));
        _startPollTimer(event.bookingId);
        return;
      }
    }

    // 不在初始化時請求權限，等使用者按錄音按鈕時再問
    emit(state.copyWith(
      phase: RecordingPhase.idle,
      bookingId: event.bookingId,
      hasPermission: false,
      learningReport: report,
    ));
  }

  Future<void> _onStart(
    RecordingStart event,
    Emitter<RecordingState> emit,
  ) async {
    if (!state.hasPermission) {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        emit(state.copyWith(
          errorMessage: '需要麥克風權限才能錄音',
          hasPermission: false,
        ));
        return;
      }
      emit(state.copyWith(hasPermission: true));
    }

    try {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/recording_${state.bookingId}_$_nextSequence.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      emit(state.copyWith(
        phase: RecordingPhase.recording,
        currentSegmentSeconds: 0,
        clearError: true,
      ));

      _startTimer();
    } catch (e) {
      debugPrint('開始錄音失敗: $e');
      emit(state.copyWith(
        errorMessage: '開始錄音失敗',
      ));
    }
  }

  Future<void> _onPause(
    RecordingPause event,
    Emitter<RecordingState> emit,
  ) async {
    try {
      await _recorder.pause();
      _stopTimer();
      emit(state.copyWith(phase: RecordingPhase.paused));
    } catch (e) {
      debugPrint('暫停錄音失敗: $e');
    }
  }

  Future<void> _onResume(
    RecordingResume event,
    Emitter<RecordingState> emit,
  ) async {
    try {
      await _recorder.resume();
      emit(state.copyWith(phase: RecordingPhase.recording));
      _startTimer();
    } catch (e) {
      debugPrint('繼續錄音失敗: $e');
    }
  }

  Future<void> _onStop(
    RecordingStop event,
    Emitter<RecordingState> emit,
  ) async {
    _stopTimer();

    try {
      final path = await _recorder.stop();
      if (path == null) return;

      final file = File(path);
      final fileSize = await file.length();
      final duration = state.currentSegmentSeconds;

      final segment = LocalSegment(
        filePath: path,
        durationSeconds: duration,
        sequence: _nextSequence,
        fileSizeBytes: fileSize,
      );

      _nextSequence++;

      emit(state.copyWith(
        phase: RecordingPhase.stopped,
        completedSegments: [...state.completedSegments, segment],
        totalRecordedSeconds: state.totalRecordedSeconds + duration,
        currentSegmentSeconds: 0,
      ));
    } catch (e) {
      debugPrint('停止錄音失敗: $e');
      emit(state.copyWith(
        errorMessage: '停止錄音失敗',
      ));
    }
  }

  void _onTimerTick(
    RecordingTimerTick event,
    Emitter<RecordingState> emit,
  ) {
    emit(state.copyWith(
      currentSegmentSeconds: state.currentSegmentSeconds + 1,
    ));
  }

  Future<void> _onUploadAndAnalyze(
    RecordingUploadAndAnalyze event,
    Emitter<RecordingState> emit,
  ) async {
    if (!state.hasSegmentsToUpload) return;

    final bookingId = state.bookingId;
    if (bookingId == null) return;

    emit(state.copyWith(
      phase: RecordingPhase.uploading,
      uploadedCount: 0,
    ));

    // 逐段上傳
    for (final segment in state.completedSegments) {
      final result = await repository.uploadRecordingSegment(
        bookingId: bookingId,
        filePath: segment.filePath,
        durationSeconds: segment.durationSeconds,
        sequence: segment.sequence,
        fileSizeBytes: segment.fileSizeBytes,
      );

      if (!result.success) {
        emit(state.copyWith(
          phase: RecordingPhase.error,
          errorMessage: result.errorMessage ?? '上傳錄音失敗',
        ));
        return;
      }

      emit(state.copyWith(uploadedCount: state.uploadedCount + 1));
    }

    // 觸發 AI 分析
    emit(state.copyWith(phase: RecordingPhase.analyzing));

    final analysisResult = await repository.triggerAnalysis(bookingId: bookingId);
    if (!analysisResult.success) {
      emit(state.copyWith(
        phase: RecordingPhase.error,
        errorMessage: analysisResult.errorMessage ?? '觸發分析失敗',
      ));
      return;
    }

    // 開始輪詢報告狀態
    _startPollTimer(bookingId);

    // 清除本地暫存檔
    _cleanupLocalFiles();
  }

  Future<void> _onLoadReport(
    RecordingLoadReport event,
    Emitter<RecordingState> emit,
  ) async {
    final report = await repository.getLearningReport(event.bookingId);
    if (report == null) return;

    if (report.isCompleted) {
      _stopPollTimer();
      emit(state.copyWith(
        phase: RecordingPhase.completed,
        learningReport: report,
      ));
    } else if (report.isFailed) {
      _stopPollTimer();
      emit(state.copyWith(
        phase: RecordingPhase.error,
        learningReport: report,
        errorMessage: report.errorMessage ?? '分析失敗',
      ));
    } else {
      emit(state.copyWith(
        phase: RecordingPhase.analyzing,
        learningReport: report,
      ));
    }
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const RecordingTimerTick());
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _startPollTimer(String bookingId) {
    _stopPollTimer();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      add(RecordingLoadReport(bookingId));
    });
  }

  void _stopPollTimer() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _cleanupLocalFiles() {
    for (final segment in state.completedSegments) {
      try {
        final file = File(segment.filePath);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }
  }

  @override
  Future<void> close() async {
    _stopTimer();
    _stopPollTimer();
    _cleanupLocalFiles();
    await _recorder.dispose();
    return super.close();
  }
}
