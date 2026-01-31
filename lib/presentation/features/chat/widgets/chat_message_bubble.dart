import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/chat.dart';

/// Chat message bubble widget
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.showSender = true,
  });

  final ChatMessage message;
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    if (message.isSystemMessage) {
      return _buildSystemMessage(context);
    }

    return message.isMe
        ? _buildOwnMessage(context)
        : _buildOtherMessage(context);
  }

  Widget _buildSystemMessage(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.tertiary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.systemMessageText,
          style: textTheme.bodySmall?.copyWith(
            color: colors.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildOwnMessage(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 12, top: 2, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Time
          Padding(
            padding: const EdgeInsets.only(right: 6, bottom: 2),
            child: Text(
              _formatTime(message.createdAt),
              style: textTheme.bodySmall?.copyWith(
                color: colors.secondaryText,
                fontSize: 10,
              ),
            ),
          ),
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                message.content ?? '',
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherMessage(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 48, top: 2, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender name
          if (showSender)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                '書呆子 ${message.displaySender}',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Message bubble
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.secondaryBackground,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: colors.tertiary),
                  ),
                  child: Text(
                    message.content ?? '',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.primaryText,
                    ),
                  ),
                ),
              ),
              // Time
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 2),
                child: Text(
                  _formatTime(message.createdAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.secondaryText,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
}

/// Date divider widget for chat
class ChatDateDivider extends StatelessWidget {
  const ChatDateDivider({
    super.key,
    required this.date,
  });

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: colors.alternate),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDate(date),
              style: textTheme.bodySmall?.copyWith(
                color: colors.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: colors.alternate),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return '今天';
    } else if (targetDate == yesterday) {
      return '昨天';
    } else {
      return DateFormat('M月d日').format(date);
    }
  }
}
