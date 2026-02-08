import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/booking.dart';

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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.tertiary,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Header: "書呆子 [displayName]"
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '書呆子 ${plan.displayName}',
                    style: textTheme.labelLarge?.copyWith(
                      fontFamily: fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            // Goal 1
            _buildGoalRow(context, 1, plan.plan1Id, plan.plan1Content, plan.plan1Done),
            // Goal 2
            _buildGoalRow(context, 2, plan.plan2Id, plan.plan2Content, plan.plan2Done),
            // Goal 3 (extra bottom padding)
            _buildGoalRow(context, 3, plan.plan3Id, plan.plan3Content, plan.plan3Done,
                bottomPadding: 18),
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
    bool isDone, {
    double bottomPadding = 0,
  }) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number prefix
          Text(
            '$slot. ',
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: fontFamily,
            ),
          ),
          // Goal content
          Expanded(
            child: Text(
              content ?? '',
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: fontFamily,
              ),
            ),
          ),
          // Check/edit icon
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _buildGoalIcon(colors, isDone, planId, content, slot),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalIcon(
    AppColorsTheme colors,
    bool isDone,
    String? planId,
    String? content,
    int slot,
  ) {
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

    // If is_me && not done && (canEditContent || canCheckGoal) → show edit icon
    if (plan.isMe && (canEditGoalContent || canCheckGoal)) {
      return InkWell(
        onTap: () => onGoalTap(slot, planId, content, isDone),
        child: Icon(
          Icons.edit_rounded,
          color: colors.primaryText,
          size: 24,
        ),
      );
    }

    // Otherwise → empty space to maintain alignment
    return const SizedBox(width: 24, height: 24);
  }
}
