import 'package:equatable/equatable.dart';

import '../../../../domain/entities/booking.dart';

/// Base class for feedback events
abstract class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object?> get props => [];
}

/// 提交全部問卷（活動評價 + 所有同儕評價）
class FeedbackSubmitAll extends FeedbackEvent {
  final String groupId;
  final String myMemberId;

  // 活動評價
  final int venueRating;
  final int flowRating;
  final int vibeRating;
  final String? eventComment;

  // 同儕評價列表
  final List<PeerFeedbackData> peerFeedbacks;

  const FeedbackSubmitAll({
    required this.groupId,
    required this.myMemberId,
    required this.venueRating,
    required this.flowRating,
    required this.vibeRating,
    this.eventComment,
    required this.peerFeedbacks,
  });

  @override
  List<Object?> get props => [
        groupId,
        myMemberId,
        venueRating,
        flowRating,
        vibeRating,
        eventComment,
        peerFeedbacks,
      ];
}

/// 單一同儕的評價資料
class PeerFeedbackData extends Equatable {
  final GroupMember member;
  final bool noShow;
  final int? focusRating;
  final bool hasDiscomfortBehavior;
  final String? discomfortBehaviorNote;
  final bool hasProfileMismatch;
  final String? profileMismatchNote;
  final String? comment;

  const PeerFeedbackData({
    required this.member,
    required this.noShow,
    this.focusRating,
    this.hasDiscomfortBehavior = false,
    this.discomfortBehaviorNote,
    this.hasProfileMismatch = false,
    this.profileMismatchNote,
    this.comment,
  });

  @override
  List<Object?> get props => [
        member,
        noShow,
        focusRating,
        hasDiscomfortBehavior,
        discomfortBehaviorNote,
        hasProfileMismatch,
        profileMismatchNote,
        comment,
      ];
}
