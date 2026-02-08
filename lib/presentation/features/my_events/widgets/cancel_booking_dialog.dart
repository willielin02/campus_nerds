import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/booking.dart';

/// Dialog to confirm booking cancellation
/// Matches FlutterFlow ConfirmDialogCancelBookingStudy design exactly
class CancelBookingDialog extends StatelessWidget {
  const CancelBookingDialog({
    super.key,
    required this.event,
    required this.onConfirm,
  });

  final MyEvent event;
  final VoidCallback onConfirm;

  static void show(
    BuildContext context, {
    required MyEvent event,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        elevation: 0,
        backgroundColor: Colors.transparent,
        clipBehavior: Clip.none,
        child: CancelBookingDialog(
          event: event,
          onConfirm: () {
            Navigator.of(ctx).pop();
            onConfirm();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    final eventTypeName =
        event.isFocusedStudy ? 'Focused Study' : 'English Games';
    final ticketTypeName = event.isFocusedStudy ? 'Study' : 'Games';

    return Container(
      width: 579,
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
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    decoration: const BoxDecoration(),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '確定取消本場$eventTypeName嗎？',
                          style: textTheme.labelLarge?.copyWith(
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Description
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '您將取消本場活動的報名，並取回一張 $ticketTypeName 票券。',
                style: textTheme.bodyLarge?.copyWith(
                  fontFamily: fontFamily,
                ),
              ),
            ),
            // Buttons row
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                // "取消" button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 8, 16),
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.secondaryBackground,
                          foregroundColor: colors.primaryText,
                          elevation: 0.2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: colors.tertiary,
                            ),
                          ),
                        ),
                        child: Text(
                          '取消',
                          style: textTheme.bodyLarge?.copyWith(
                            fontFamily: fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // "確定" button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 8, 16),
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.alternate,
                          foregroundColor: colors.primaryText,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '確定',
                          style: textTheme.bodyLarge?.copyWith(
                            fontFamily: fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
