import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/booking.dart';

/// Card widget displaying a group member's study plans (3 goals)
class StudyPlanCard extends StatelessWidget {
  const StudyPlanCard({
    super.key,
    required this.plan,
    required this.onGoalTap,
    this.canEdit = false,
  });

  final GroupFocusedPlan plan;
  final void Function(int slot, String? planId, String? content, bool isDone) onGoalTap;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: plan.isMe ? colors.primary.withOpacity(0.5) : colors.tertiary,
          width: plan.isMe ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and completion stats
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: plan.isMe ? colors.primary : colors.tertiary,
                child: Icon(
                  Icons.person,
                  size: 18,
                  color: plan.isMe ? Colors.white : colors.secondaryText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      plan.displayName,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (plan.isMe) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '我',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Completion indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: plan.allDone
                      ? colors.success.withOpacity(0.1)
                      : colors.tertiary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${plan.completedCount}/${plan.totalGoals}',
                  style: textTheme.bodySmall?.copyWith(
                    color: plan.allDone ? colors.success : colors.secondaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Goals list
          _buildGoalRow(context, 1, plan.plan1Id, plan.plan1Content, plan.plan1Done),
          const SizedBox(height: 8),
          _buildGoalRow(context, 2, plan.plan2Id, plan.plan2Content, plan.plan2Done),
          const SizedBox(height: 8),
          _buildGoalRow(context, 3, plan.plan3Id, plan.plan3Content, plan.plan3Done),
        ],
      ),
    );
  }

  Widget _buildGoalRow(
    BuildContext context,
    int slot,
    String? planId,
    String? content,
    bool isDone,
  ) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final hasContent = content != null && content.isNotEmpty;
    final isEditable = plan.isMe && canEdit;

    return InkWell(
      onTap: isEditable ? () => onGoalTap(slot, planId, content, isDone) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDone
              ? colors.success.withOpacity(0.05)
              : colors.primaryBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDone ? colors.success.withOpacity(0.3) : colors.alternate,
          ),
        ),
        child: Row(
          children: [
            // Checkbox indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone ? colors.success : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDone ? colors.success : colors.secondaryText,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),

            // Goal content
            Expanded(
              child: hasContent
                  ? Text(
                      content,
                      style: textTheme.bodyMedium?.copyWith(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? colors.secondaryText : colors.primaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      '待辦事項 $slot',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.secondaryText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),

            // Edit indicator for own goals
            if (isEditable)
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: colors.secondaryText,
              ),
          ],
        ),
      ),
    );
  }
}
