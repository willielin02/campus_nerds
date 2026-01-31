import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/booking.dart';

/// Dialog to confirm booking cancellation
class CancelBookingDialog extends StatelessWidget {
  const CancelBookingDialog({
    super.key,
    required this.event,
    required this.onConfirm,
  });

  final MyEvent event;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return AlertDialog(
      backgroundColor: colors.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.warning),
          const SizedBox(width: 8),
          Text(
            '取消報名',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '確定要取消這場活動的報名嗎？',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primaryBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      event.isFocusedStudy
                          ? Icons.menu_book_rounded
                          : Icons.games_rounded,
                      size: 18,
                      color: event.isFocusedStudy
                          ? colors.primary
                          : colors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      event.eventCategory.displayName,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${event.formattedDate} ${event.timeSlot.displayName}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '取消後票券將會退還至您的帳戶',
            style: textTheme.bodySmall?.copyWith(
              color: colors.secondaryText,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '返回',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.secondaryText,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('確定取消'),
        ),
      ],
    );
  }
}
