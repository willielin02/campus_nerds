import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/booking.dart';
import '../../../common/widgets/profile_popup.dart';

/// Card widget displaying a group member's study plans (3 goals)
/// Matches FlutterFlow EventDetailsStudy design
class StudyPlanCard extends StatelessWidget {
  const StudyPlanCard({
    super.key,
    required this.plan,
    required this.onGoalTap,
    this.canEditGoalContent = false,
    this.canCheckGoal = false,
  });

  final GroupFocusedPlan plan;
  final void Function(int slot, String? planId, String? content, bool isDone) onGoalTap;
  final bool canEditGoalContent;
  final bool canCheckGoal;

  bool get _canEdit => plan.isMe && (canEditGoalContent || canCheckGoal);

  static Widget _slotBadge(int slot, Color badgeColor, Color textColor, TextTheme textTheme, String? fontFamily) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '$slot',
        style: textTheme.bodyMedium?.copyWith(
          fontFamily: fontFamily,
          color: textColor,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }

  void _showProfilePopup(BuildContext context, GlobalKey headerKey) {
    showProfilePopup(
      context,
      headerKey,
      ProfilePopupData(
        displayName: plan.displayName,
        gender: plan.gender,
        universityName: plan.universityName,
        age: plan.age,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;
    final accentColor = plan.isMe ? colors.secondaryText : colors.tertiaryText;
    final headerKey = GlobalKey();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: plan.isMe ? colors.quaternary : colors.tertiary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "書呆子 [displayName] 的待辦事項"
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: GestureDetector(
                key: headerKey,
                onTap: () => _showProfilePopup(context, headerKey),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '書呆子 ${plan.displayName}',
                        style: textTheme.labelLarge?.copyWith(
                          fontFamily: fontFamily,
                          color: plan.isMe ? null : colors.secondaryText,
                        ),
                      ),
                      TextSpan(
                        text: ' 的待辦事項',
                        style: textTheme.labelLarge?.copyWith(
                          fontFamily: fontFamily,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Goal 1
            _buildGoalRow(context, 1, plan.plan1Id, plan.plan1Content, plan.plan1Done, accentColor,
                topPadding: 16, bottomPadding: 12),
            Divider(thickness: 1, indent: 0, endIndent: 0, color: colors.alternate, height: 1),
            // Goal 2
            _buildGoalRow(context, 2, plan.plan2Id, plan.plan2Content, plan.plan2Done, accentColor,
                topPadding: 12, bottomPadding: 12),
            Divider(thickness: 1, indent: 0, endIndent: 0, color: colors.alternate, height: 1),
            // Goal 3 (extra bottom padding)
            _buildGoalRow(context, 3, plan.plan3Id, plan.plan3Content, plan.plan3Done, accentColor,
                topPadding: 12, bottomPadding: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalRow(
    BuildContext context,
    int slot,
    String? planId,
    String? content,
    bool isDone,
    Color accentColor, {
    double topPadding = 8,
    double bottomPadding = 8,
  }) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;
    final isEmpty = content == null || content.isEmpty;

    Widget row = Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal number badge
          Padding(
            padding: const EdgeInsets.only(top: 1, right: 8),
            child: _slotBadge(slot, accentColor, colors.secondaryBackground, textTheme, fontFamily),
          ),
          // Goal content (or placeholder if empty)
          Expanded(
            child: isEmpty
                ? Text(
                    _canEdit ? '點擊以新增' : '',
                    style: textTheme.bodyLarge?.copyWith(
                      fontFamily: fontFamily,
                      color: colors.quaternary,
                    ),
                  )
                : Text(
                    content,
                    style: textTheme.bodyLarge?.copyWith(
                      fontFamily: fontFamily,
                      color: plan.isMe ? null : colors.secondaryText,
                    ),
                  ),
          ),
          // Check/edit icon
          _buildGoalIcon(colors, isDone, accentColor),
        ],
      ),
    );

    // Make entire row tappable when editable
    if (_canEdit && !isDone) {
      return InkWell(
        onTap: () => onGoalTap(slot, planId, content, isDone),
        child: row,
      );
    }

    return row;
  }

  Widget _buildGoalIcon(AppColorsTheme colors, bool isDone, Color accentColor) {
    // If done → show checkmark
    if (isDone) {
      return Container(
        decoration: BoxDecoration(
          color: colors.secondaryText,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.check_rounded,
          color: colors.secondaryBackground,
          size: 24,
        ),
      );
    }

    // If editable → show edit icon (tap handled by parent InkWell)
    if (_canEdit) {
      return Icon(
        Icons.edit_rounded,
        color: accentColor,
        size: 24,
      );
    }

    // Otherwise → empty space to maintain alignment
    return const SizedBox(width: 24, height: 24);
  }
}

