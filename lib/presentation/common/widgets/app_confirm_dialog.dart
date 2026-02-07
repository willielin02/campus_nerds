import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_theme.dart';

/// Reusable confirm dialog matching FlutterFlow ConfirmDialog design.
///
/// Usage:
/// ```dart
/// showAppConfirmDialog(
///   context: context,
///   title: '確定要解除綁定嗎？',
///   message: '解除綁定後，我們將無法在分組時避開你的臉書好友',
///   confirmText: '確定解除',
///   onConfirm: () { /* do something */ },
/// );
/// ```
Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelText = '取消',
  String confirmText = '確定',
  VoidCallback? onConfirm,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppConfirmDialog(
        title: title,
        message: message,
        cancelText: cancelText,
        confirmText: confirmText,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () {
          Navigator.of(dialogContext).pop(true);
          onConfirm?.call();
        },
      ),
    ),
  );
}

/// Confirm dialog widget matching FlutterFlow ConfirmDialogCreateBookingStudy.
///
/// Container with secondaryBackground, 12px radius, 2px tertiary border.
/// Two side-by-side buttons: cancel (outlined) and confirm (filled alternate).
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.cancelText = '取消',
    this.confirmText = '確定',
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final String cancelText;
  final String confirmText;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

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
            // Buttons row
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: colors.secondaryBackground,
                            side: BorderSide(color: colors.tertiary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            cancelText,
                            style: textTheme.bodyLarge?.copyWith(
                              fontFamily: fontFamily,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Confirm button
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.alternate,
                          foregroundColor: colors.primaryText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          confirmText,
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
          ],
        ),
      ),
    );
  }
}
