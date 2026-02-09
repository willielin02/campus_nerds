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
    final renderBox = headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final position = renderBox.localToGlobal(Offset.zero);
    final headerSize = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    // Determine if popup should appear above or below
    final spaceBelow = screenSize.height - position.dy - headerSize.height;
    final spaceAbove = position.dy;
    final showBelow = spaceBelow >= spaceAbove;

    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (ctx) {
        return _ProfilePopupOverlay(
          plan: plan,
          anchorPosition: position,
          anchorSize: headerSize,
          showBelow: showBelow,
          onDismiss: () => overlayEntry.remove(),
        );
      },
    );

    overlay.insert(overlayEntry);
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
          color: colors.tertiary,
          width: 2,
        ),
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

/// Overlay widget that shows the profile card popup
class _ProfilePopupOverlay extends StatelessWidget {
  const _ProfilePopupOverlay({
    required this.plan,
    required this.anchorPosition,
    required this.anchorSize,
    required this.showBelow,
    required this.onDismiss,
  });

  final GroupFocusedPlan plan;
  final Offset anchorPosition;
  final Size anchorSize;
  final bool showBelow;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Stack(
      children: [
        // Dismiss barrier
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        // Profile card - use horizontal padding matching the parent card layout
        Positioned(
          left: 32,
          right: 32,
          top: showBelow ? anchorPosition.dy + anchorSize.height + 8 : null,
          bottom: showBelow ? null : MediaQuery.of(context).size.height - anchorPosition.dy + 8,
          child: Material(
            color: Colors.transparent,
            child: _buildProfileCard(context, colors, textTheme),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    AppColorsTheme colors,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.quaternary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.alternate,
                borderRadius: BorderRadius.circular(48),
              ),
              child: ClipOval(
                child: Image.asset(
                  plan.gender == 'female'
                      ? 'assets/images/Gemini_Generated_Image_ajjb8yajjb8yajjb.png'
                      : 'assets/images/Gemini_Generated_Image_wn5duxwn5duxwn5d.png',
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => Container(
                    color: colors.alternate,
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: colors.primaryText,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Name and info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '書呆子 ${plan.displayName}',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plan.universityName ?? '',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.primaryText,
                      ),
                    ),
                    if (plan.age != null)
                      Text(
                        '  |  ${plan.ageDisplay}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.primaryText,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
