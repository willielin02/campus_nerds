import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/repositories/support_repository.dart';
import 'support_event.dart';
import 'support_state.dart';

class SupportBloc extends Bloc<SupportEvent, SupportState> {
  final SupportRepository _supportRepository;

  SupportBloc({
    required SupportRepository supportRepository,
  })  : _supportRepository = supportRepository,
        super(const SupportState()) {
    on<SupportLoadTickets>(_onLoadTickets);
    on<SupportLoadMessages>(_onLoadMessages);
    on<SupportCreateTicket>(_onCreateTicket);
    on<SupportSendMessage>(_onSendMessage);
    on<SupportClearError>(_onClearError);
  }

  Future<void> _onLoadTickets(
    SupportLoadTickets event,
    Emitter<SupportState> emit,
  ) async {
    emit(state.copyWith(status: SupportStatus.loading));

    try {
      final tickets = await _supportRepository.getMyTickets();
      emit(state.copyWith(
        status: SupportStatus.loaded,
        tickets: tickets,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SupportStatus.error,
        errorMessage: '載入工單失敗',
      ));
    }
  }

  Future<void> _onLoadMessages(
    SupportLoadMessages event,
    Emitter<SupportState> emit,
  ) async {
    emit(state.copyWith(
      status: SupportStatus.loading,
      selectedTicketId: event.ticketId,
    ));

    try {
      final messages =
          await _supportRepository.getTicketMessages(event.ticketId);
      emit(state.copyWith(
        status: SupportStatus.loaded,
        messages: messages,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SupportStatus.error,
        errorMessage: '載入訊息失敗',
      ));
    }
  }

  Future<void> _onCreateTicket(
    SupportCreateTicket event,
    Emitter<SupportState> emit,
  ) async {
    emit(state.copyWith(isCreating: true));

    try {
      await _supportRepository.createTicket(
        category: event.category,
        subject: event.subject,
        message: event.message,
        imagePath: event.imagePath,
      );

      // 重新載入工單列表
      final tickets = await _supportRepository.getMyTickets();
      emit(state.copyWith(
        isCreating: false,
        tickets: tickets,
        successMessage: '工單已建立',
      ));
    } catch (e) {
      emit(state.copyWith(
        isCreating: false,
        errorMessage: '建立工單失敗',
      ));
    }
  }

  Future<void> _onSendMessage(
    SupportSendMessage event,
    Emitter<SupportState> emit,
  ) async {
    emit(state.copyWith(isSending: true));

    try {
      final newMessage = await _supportRepository.sendMessage(
        ticketId: event.ticketId,
        content: event.content,
        imagePath: event.imagePath,
      );

      final updatedMessages = [...state.messages, newMessage];
      emit(state.copyWith(
        isSending: false,
        messages: updatedMessages,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSending: false,
        errorMessage: '發送訊息失敗',
      ));
    }
  }

  void _onClearError(
    SupportClearError event,
    Emitter<SupportState> emit,
  ) {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }
}
