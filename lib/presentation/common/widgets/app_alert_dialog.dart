import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';

/// Reusable alert dialog matching FlutterFlow AlertDialog design.
///
/// Single button ("我知道了") variant — used for informational alerts.
///
/// Usage:
/// ```dart
/// showAppAlertDialog(
///   context: context,
///   title: '錯誤',
///   message: '此學校信箱已被其他帳號使用',
/// );
/// ```
Future<void> showAppAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = '我知道了',
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppAlertDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onPressed: () => Navigator.of(dialogContext).pop(),
      ),
    ),
  );
}

/// Alert dialog widget matching FlutterFlow AlertDialogWidget.
///
/// Container with secondaryBackground, 12px radius, 2px tertiary border.
/// Single full-width button (filled alternate).
class AppAlertDialog extends StatelessWidget {
  const AppAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = '我知道了',
    required this.onPressed,
  });

  final String title;
  final String message;
  final String buttonText;
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
                title,
                style: textTheme.labelLarge?.copyWith(
                  fontFamily: fontFamily,
                ),
              ),
            ),
            // Message
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                message,
                style: textTheme.bodyLarge?.copyWith(
                  fontFamily: fontFamily,
                ),
              ),
            ),
            // Button
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
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
                    buttonText,
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
