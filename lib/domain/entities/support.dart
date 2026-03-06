import 'package:equatable/equatable.dart';

/// Support ticket category
enum TicketCategory {
  schoolVerification('school_verification', '學校驗證'),
  payment('payment', '付款問題'),
  bugReport('bug_report', 'Bug 回報'),
  other('other', '其他');

  final String value;
  final String label;
  const TicketCategory(this.value, this.label);

  static TicketCategory fromString(String value) {
    return TicketCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TicketCategory.other,
    );
  }
}

/// Support ticket status
enum TicketStatus {
  open('open', '待處理'),
  inProgress('in_progress', '處理中'),
  resolved('resolved', '已解決'),
  closed('closed', '已關閉');

  final String value;
  final String label;
  const TicketStatus(this.value, this.label);

  static TicketStatus fromString(String value) {
    return TicketStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TicketStatus.open,
    );
  }

  bool get isClosed => this == resolved || this == closed;
}

/// Support ticket entity
class SupportTicket extends Equatable {
  final String id;
  final String userId;
  final TicketCategory category;
  final String subject;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.category,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  @override
  List<Object?> get props => [id, userId, category, subject, status, createdAt, updatedAt, resolvedAt];
}

/// Support message entity
class SupportMessage extends Equatable {
  final String id;
  final String ticketId;
  final String senderType;
  final String senderId;
  final String? content;
  final String? imagePath;
  final String? imageUrl;
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderType,
    required this.senderId,
    this.content,
    this.imagePath,
    this.imageUrl,
    required this.createdAt,
  });

  bool get isUser => senderType == 'user';
  bool get isAdmin => senderType == 'admin';
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  @override
  List<Object?> get props => [id, ticketId, senderType, senderId, content, imagePath, createdAt];
}
