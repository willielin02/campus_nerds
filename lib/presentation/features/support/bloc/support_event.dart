import 'package:equatable/equatable.dart';

import '../../../../domain/entities/support.dart';

abstract class SupportEvent extends Equatable {
  const SupportEvent();

  @override
  List<Object?> get props => [];
}

/// 載入工單列表
class SupportLoadTickets extends SupportEvent {
  const SupportLoadTickets();
}

/// 載入工單訊息
class SupportLoadMessages extends SupportEvent {
  final String ticketId;
  const SupportLoadMessages(this.ticketId);

  @override
  List<Object?> get props => [ticketId];
}

/// 建立工單
class SupportCreateTicket extends SupportEvent {
  final TicketCategory category;
  final String subject;
  final String message;
  final String? imagePath;

  const SupportCreateTicket({
    required this.category,
    required this.subject,
    required this.message,
    this.imagePath,
  });

  @override
  List<Object?> get props => [category, subject, message, imagePath];
}

/// 發送訊息
class SupportSendMessage extends SupportEvent {
  final String ticketId;
  final String? content;
  final String? imagePath;

  const SupportSendMessage({
    required this.ticketId,
    this.content,
    this.imagePath,
  });

  @override
  List<Object?> get props => [ticketId, content, imagePath];
}

/// 清除錯誤
class SupportClearError extends SupportEvent {
  const SupportClearError();
}
