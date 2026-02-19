import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/booking.dart';
import '../../../common/widgets/profile_popup.dart';

/// Card widget displaying a group member's English learning content
class EnglishContentCard extends StatelessWidget {
  const EnglishContentCard({
    super.key,
    required this.assignment,
    this.canViewContent = true,
  });

  final GroupEnglishAssignment assignment;
  final bool canViewContent;

  void _showProfilePopup(BuildContext context, GlobalKey headerKey) {
    showProfilePopup(
      context,
      headerKey,
      ProfilePopupData(
        displayName: assignment.displayName,
        gender: assignment.gender,
        universityName: assignment.universityName,
        age: assignment.age,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;
    final accentColor =
        assignment.isMe ? colors.secondaryText : colors.tertiaryText;
    final headerKey = GlobalKey();

    final hasContent =
        assignment.contentEn != null && assignment.contentEn!.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: assignment.isMe ? colors.quaternary : colors.tertiary,
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
            // Header: "書呆子 [displayName] 的學習內容"
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: GestureDetector(
                key: headerKey,
                onTap: () => _showProfilePopup(context, headerKey),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '書呆子 ${assignment.displayName}',
                        style: textTheme.labelLarge?.copyWith(
                          fontFamily: fontFamily,
                          color:
                              assignment.isMe ? null : colors.secondaryText,
                        ),
                      ),
                      TextSpan(
                        text: ' 的學習內容',
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
            // Content area
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: hasContent
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // English content (large font)
                        Text(
                          canViewContent
                              ? assignment.contentEn!
                              : '???',
                          style: textTheme.titleMedium?.copyWith(
                            fontFamily: fontFamily,
                            color: assignment.isMe
                                ? null
                                : colors.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Chinese translation (small font)
                        Text(
                          canViewContent
                              ? (assignment.contentZh ?? '')
                              : '???',
                          style: textTheme.bodyMedium?.copyWith(
                            fontFamily: fontFamily,
                            color: accentColor,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '尚未分配學習內容',
                      style: textTheme.bodyLarge?.copyWith(
                        fontFamily: fontFamily,
                        color: colors.quaternary,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
