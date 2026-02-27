import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/repositories/my_events_repository.dart';
import 'feedback_event.dart';
import 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final MyEventsRepository repository;

  FeedbackBloc({required this.repository}) : super(const FeedbackState()) {
    on<FeedbackSubmitAll>(_onSubmitAll);
  }

  Future<void> _onSubmitAll(
    FeedbackSubmitAll event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(state.copyWith(status: FeedbackStatus.submitting, clearError: true));

    try {
      // 1. 提交活動評價
      final eventResult = await repository.submitEventFeedback(
        groupId: event.groupId,
        memberId: event.myMemberId,
        venueRating: event.venueRating,
        flowRating: event.flowRating,
        vibeRating: event.vibeRating,
        comment: event.eventComment,
      );

      if (!eventResult.success) {
        emit(state.copyWith(
          status: FeedbackStatus.error,
          errorMessage: eventResult.errorMessage,
        ));
        return;
      }

      // 2. 逐一提交同儕評價
      for (final peer in event.peerFeedbacks) {
        final peerResult = await repository.submitPeerFeedback(
          groupId: event.groupId,
          fromMemberId: event.myMemberId,
          toMemberId: peer.member.id,
          noShow: peer.noShow,
          focusRating: peer.focusRating,
          hasDiscomfortBehavior: peer.hasDiscomfortBehavior,
          discomfortBehaviorNote: peer.discomfortBehaviorNote,
          hasProfileMismatch: peer.hasProfileMismatch,
          profileMismatchNote: peer.profileMismatchNote,
          comment: peer.comment,
        );

        if (!peerResult.success) {
          debugPrint('同儕評價提交失敗 (${peer.member.displayName}): ${peerResult.errorMessage}');
          // 繼續提交其他同儕的評價，不中斷
        }
      }

      emit(state.copyWith(status: FeedbackStatus.success));
    } catch (e) {
      debugPrint('問卷提交失敗: $e');
      emit(state.copyWith(
        status: FeedbackStatus.error,
        errorMessage: '問卷提交失敗，請稍後再試',
      ));
    }
  }
}
