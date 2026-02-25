import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/app_notification.dart';

/// Shows an in-app notification dialog for event group results.
///
/// Single-button dialog matching FlutterFlow design.
/// On dismiss, calls [onDismiss] with the notification for navigation handling.
Future<void> showNotificationDialog({
  required BuildContext context,
  required AppNotification notification,
  required void Function(AppNotification notification) onDismiss,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: _NotificationDialogContent(
        notification: notification,
        onPressed: () {
          Navigator.of(dialogContext).pop();
          onDismiss(notification);
        },
      ),
    ),
  );
}

class _NotificationDialogContent extends StatelessWidget {
  const _NotificationDialogContent({
    required this.notification,
    required this.onPressed,
  });

  final AppNotification notification;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                notification.title,
                style: textTheme.labelLarge?.copyWith(
                  fontFamily: fontFamily,
                ),
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                notification.body,
                style: context.appTypography.bodyBig,
              ),
            ),
            // Button
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.alternate,
                    foregroundColor: colors.primaryText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '我知道了',
                    style: textTheme.bodyLarge?.copyWith(
                      fontFamily: fontFamily,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
