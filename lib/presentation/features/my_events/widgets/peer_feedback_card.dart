import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/booking.dart';
import 'rating_bar.dart';

/// 同儕評價卡片（含 noShow toggle、投入程度、不舒服行為、個人資料不符）
class PeerFeedbackCard extends StatefulWidget {
  final GroupMember member;
  final ValueChanged<PeerFeedbackCardData> onChanged;

  const PeerFeedbackCard({
    super.key,
    required this.member,
    required this.onChanged,
  });

  @override
  State<PeerFeedbackCard> createState() => _PeerFeedbackCardState();
}

class _PeerFeedbackCardState extends State<PeerFeedbackCard> {
  bool _noShow = false;
  int _focusRating = 0;
  bool _hasDiscomfort = false;
  bool _hasProfileMismatch = false;
  final _discomfortController = TextEditingController();
  final _mismatchController = TextEditingController();
  final _commentController = TextEditingController();

  void _notifyChanged() {
    widget.onChanged(PeerFeedbackCardData(
      noShow: _noShow,
      focusRating: _noShow ? null : (_focusRating > 0 ? _focusRating : null),
      hasDiscomfortBehavior: _noShow ? false : _hasDiscomfort,
      discomfortBehaviorNote:
          _hasDiscomfort ? _discomfortController.text : null,
      hasProfileMismatch: _noShow ? false : _hasProfileMismatch,
      profileMismatchNote:
          _hasProfileMismatch ? _mismatchController.text : null,
      comment: _commentController.text.isEmpty ? null : _commentController.text,
    ));
  }

  @override
  void dispose() {
    _discomfortController.dispose();
    _mismatchController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        border: Border.all(color: colors.tertiary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '書呆子 ${widget.member.displayName}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 12),

          // 未出席 toggle
          _buildToggleRow(
            label: '未出席',
            value: _noShow,
            onChanged: (v) {
              setState(() => _noShow = v);
              _notifyChanged();
            },
            colors: colors,
          ),

          if (!_noShow) ...[
            const SizedBox(height: 12),

            // 投入程度
            RatingBar(
              label: '投入程度',
              rating: _focusRating,
              onRatingChanged: (v) {
                setState(() => _focusRating = v);
                _notifyChanged();
              },
            ),
            const SizedBox(height: 12),

            // 有不舒服行為
            _buildToggleRow(
              label: '有不舒服行為',
              value: _hasDiscomfort,
              onChanged: (v) {
                setState(() => _hasDiscomfort = v);
                _notifyChanged();
              },
              colors: colors,
            ),
            if (_hasDiscomfort) ...[
              const SizedBox(height: 8),
              _buildTextField(
                controller: _discomfortController,
                hint: '請描述不舒服的行為（必填）',
                colors: colors,
              ),
            ],
            const SizedBox(height: 12),

            // 個人資料不符
            _buildToggleRow(
              label: '個人資料不符',
              value: _hasProfileMismatch,
              onChanged: (v) {
                setState(() => _hasProfileMismatch = v);
                _notifyChanged();
              },
              colors: colors,
            ),
            if (_hasProfileMismatch) ...[
              const SizedBox(height: 8),
              _buildTextField(
                controller: _mismatchController,
                hint: '請說明不符之處（必填）',
                colors: colors,
              ),
            ],
            const SizedBox(height: 12),

            // 留言
            _buildTextField(
              controller: _commentController,
              hint: '留言（選填）',
              colors: colors,
              onChanged: (_) => _notifyChanged(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required AppColorsTheme colors,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: colors.primaryText),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: colors.tertiaryText,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required AppColorsTheme colors,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: 2,
      style: TextStyle(fontSize: 14, color: colors.primaryText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: colors.tertiaryText),
        filled: true,
        fillColor: colors.alternate,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// 卡片回傳的資料
class PeerFeedbackCardData {
  final bool noShow;
  final int? focusRating;
  final bool hasDiscomfortBehavior;
  final String? discomfortBehaviorNote;
  final bool hasProfileMismatch;
  final String? profileMismatchNote;
  final String? comment;

  const PeerFeedbackCardData({
    required this.noShow,
    this.focusRating,
    this.hasDiscomfortBehavior = false,
    this.discomfortBehaviorNote,
    this.hasProfileMismatch = false,
    this.profileMismatchNote,
    this.comment,
  });
}
