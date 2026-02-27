import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../domain/entities/booking.dart';
import '../bloc/feedback_bloc.dart';
import '../bloc/feedback_event.dart';
import '../bloc/feedback_state.dart';
import '../bloc/recording_bloc.dart';
import '../bloc/recording_event.dart';
import '../bloc/recording_state.dart';
import '../bloc/my_events_bloc.dart';
import '../bloc/my_events_event.dart';
import '../widgets/peer_feedback_card.dart';
import '../widgets/rating_bar.dart';

/// 問卷頁面（活動評分 + 同儕評分）
class FeedbackPage extends StatefulWidget {
  final MyEvent event;

  const FeedbackPage({super.key, required this.event});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  late final FeedbackBloc _feedbackBloc;

  // 活動評分
  int _venueRating = 0;
  int _flowRating = 0;
  int _vibeRating = 0;
  final _eventCommentController = TextEditingController();

  // 同儕評價資料
  final Map<String, PeerFeedbackCardData> _peerData = {};

  // 非自己的組員
  List<GroupMember> get _otherMembers =>
      widget.event.groupMembers.where((m) => !m.isCurrentUser).toList();

  // 自己的 member id
  String get _myMemberId =>
      widget.event.groupMembers
          .firstWhere((m) => m.isCurrentUser,
              orElse: () => const GroupMember(id: ''))
          .id;

  @override
  void initState() {
    super.initState();
    _feedbackBloc = getIt<FeedbackBloc>();
  }

  @override
  void dispose() {
    _eventCommentController.dispose();
    _feedbackBloc.close();
    super.dispose();
  }

  bool _validate() {
    if (_venueRating == 0 || _flowRating == 0 || _vibeRating == 0) {
      _showError('請完成活動評分（場地、流程、氛圍各至少 1 顆星）');
      return false;
    }

    for (final member in _otherMembers) {
      final data = _peerData[member.id];
      if (data == null) {
        _showError('請完成對「${member.displayName}」的評價');
        return false;
      }
      if (!data.noShow && (data.focusRating == null || data.focusRating == 0)) {
        _showError('請為「${member.displayName}」的投入程度評分');
        return false;
      }
      if (data.hasDiscomfortBehavior &&
          (data.discomfortBehaviorNote == null ||
              data.discomfortBehaviorNote!.isEmpty)) {
        _showError('請描述「${member.displayName}」的不舒服行為');
        return false;
      }
      if (data.hasProfileMismatch &&
          (data.profileMismatchNote == null ||
              data.profileMismatchNote!.isEmpty)) {
        _showError('請說明「${member.displayName}」的資料不符之處');
        return false;
      }
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _submit() {
    if (!_validate()) return;

    final peerFeedbacks = _otherMembers.map((member) {
      final data = _peerData[member.id]!;
      return PeerFeedbackData(
        member: member,
        noShow: data.noShow,
        focusRating: data.focusRating,
        hasDiscomfortBehavior: data.hasDiscomfortBehavior,
        discomfortBehaviorNote: data.discomfortBehaviorNote,
        hasProfileMismatch: data.hasProfileMismatch,
        profileMismatchNote: data.profileMismatchNote,
        comment: data.comment,
      );
    }).toList();

    _feedbackBloc.add(FeedbackSubmitAll(
      groupId: widget.event.groupId!,
      myMemberId: _myMemberId,
      venueRating: _venueRating,
      flowRating: _flowRating,
      vibeRating: _vibeRating,
      eventComment: _eventCommentController.text.isEmpty
          ? null
          : _eventCommentController.text,
      peerFeedbacks: peerFeedbacks,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocProvider.value(
      value: _feedbackBloc,
      child: BlocListener<FeedbackBloc, FeedbackState>(
        listener: (context, state) {
          if (state.isSuccess) {
            // 刷新 MyEventsBloc
            context
                .read<MyEventsBloc>()
                .add(MyEventsLoadDetails(widget.event.bookingId));

            // 如果有錄音段落，觸發上傳 + 分析
            try {
              final recordingBloc = context.read<RecordingBloc>();
              if (recordingBloc.state.hasSegmentsToUpload) {
                recordingBloc.add(const RecordingUploadAndAnalyze());
              }
            } catch (_) {
              // RecordingBloc 可能不在 tree 中（Focused Study）
            }

            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('問卷已提交'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state.status == FeedbackStatus.error) {
            _showError(state.errorMessage ?? '提交失敗');
          }
        },
        child: Scaffold(
          backgroundColor: colors.primaryBackground,
          appBar: AppBar(
            title: Text(
              '填寫問卷',
              style: TextStyle(
                fontFamily: GoogleFonts.notoSansTc().fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.primaryText,
              ),
            ),
            backgroundColor: colors.secondaryBackground,
            foregroundColor: colors.primaryText,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 活動評價
                _buildSectionTitle('活動評價', colors),
                const SizedBox(height: 12),
                RatingBar(
                  label: '場地',
                  rating: _venueRating,
                  onRatingChanged: (v) => setState(() => _venueRating = v),
                ),
                const SizedBox(height: 8),
                RatingBar(
                  label: '流程',
                  rating: _flowRating,
                  onRatingChanged: (v) => setState(() => _flowRating = v),
                ),
                const SizedBox(height: 8),
                RatingBar(
                  label: '氛圍',
                  rating: _vibeRating,
                  onRatingChanged: (v) => setState(() => _vibeRating = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _eventCommentController,
                  maxLines: 3,
                  style: TextStyle(fontSize: 14, color: colors.primaryText),
                  decoration: InputDecoration(
                    hintText: '留言（選填）',
                    hintStyle:
                        TextStyle(fontSize: 14, color: colors.tertiaryText),
                    filled: true,
                    fillColor: colors.alternate,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Divider(color: colors.tertiary),
                const SizedBox(height: 16),

                // 組員評價
                _buildSectionTitle('組員評價', colors),
                const SizedBox(height: 12),
                ..._otherMembers.map((member) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PeerFeedbackCard(
                        member: member,
                        onChanged: (data) {
                          _peerData[member.id] = data;
                        },
                      ),
                    )),

                const SizedBox(height: 24),

                // 提交按鈕
                BlocBuilder<FeedbackBloc, FeedbackState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: state.isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.alternate,
                          foregroundColor: colors.primaryText,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state.isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.primaryText,
                                ),
                              )
                            : Text(
                                '提交問卷',
                                style: TextStyle(
                                  fontFamily:
                                      GoogleFonts.notoSansTc().fontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppColorsTheme colors) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: GoogleFonts.notoSansTc().fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colors.primaryText,
      ),
    );
  }
}
