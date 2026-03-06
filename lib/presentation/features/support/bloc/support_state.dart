import 'package:equatable/equatable.dart';

import '../../../../domain/entities/support.dart';

enum SupportStatus { initial, loading, loaded, error }

class SupportState extends Equatable {
  final SupportStatus status;
  final List<SupportTicket> tickets;
  final List<SupportMessage> messages;
  final String? selectedTicketId;
  final bool isSending;
  final bool isCreating;
  final String? errorMessage;
  final String? successMessage;

  const SupportState({
    this.status = SupportStatus.initial,
    this.tickets = const [],
    this.messages = const [],
    this.selectedTicketId,
    this.isSending = false,
    this.isCreating = false,
    this.errorMessage,
    this.successMessage,
  });

  SupportState copyWith({
    SupportStatus? status,
    List<SupportTicket>? tickets,
    List<SupportMessage>? messages,
    String? selectedTicketId,
    bool? isSending,
    bool? isCreating,
    String? errorMessage,
    String? successMessage,
  }) {
    return SupportState(
      status: status ?? this.status,
      tickets: tickets ?? this.tickets,
      messages: messages ?? this.messages,
      selectedTicketId: selectedTicketId ?? this.selectedTicketId,
      isSending: isSending ?? this.isSending,
      isCreating: isCreating ?? this.isCreating,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        tickets,
        messages,
        selectedTicketId,
        isSending,
        isCreating,
        errorMessage,
        successMessage,
      ];
}
