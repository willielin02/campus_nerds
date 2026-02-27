import 'package:equatable/equatable.dart';

/// Base class for recording events
abstract class RecordingEvent extends Equatable {
  const RecordingEvent();

  @override
  List<Object?> get props => [];
}

/// 初始化錄音器：請求權限、檢查已有報告
class RecordingInitialize extends RecordingEvent {
  final String bookingId;
  const RecordingInitialize(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

/// 開始錄音
class RecordingStart extends RecordingEvent {
  const RecordingStart();
}

/// 暫停錄音
class RecordingPause extends RecordingEvent {
  const RecordingPause();
}

/// 繼續錄音
class RecordingResume extends RecordingEvent {
  const RecordingResume();
}

/// 停止當前段落
class RecordingStop extends RecordingEvent {
  const RecordingStop();
}

/// 每秒計時器 tick
class RecordingTimerTick extends RecordingEvent {
  const RecordingTimerTick();
}

/// 上傳所有段落 + 觸發 AI 分析
class RecordingUploadAndAnalyze extends RecordingEvent {
  const RecordingUploadAndAnalyze();
}

/// 載入/重新整理報告狀態
class RecordingLoadReport extends RecordingEvent {
  final String bookingId;
  const RecordingLoadReport(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}
