import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/chat.dart';

/// Chat message bubble widget
/// Matches FlutterFlow ChatTimelineItem design
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
    final textTheme = context.textTheme;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        message.systemMessageText,
        textAlign: TextAlign.center,
        style: textTheme.bodyMedium?.copyWith(
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  Widget _buildOwnMessage(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Message bubble - right-aligned
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              decoration: BoxDecoration(
                color: colors.tertiaryText,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  message.content ?? '',
                  style: textTheme.bodyLarge?.copyWith(
                    fontFamily: fontFamily,
                    color: colors.primaryBackground,
                    shadows: [
                      Shadow(
                        color: colors.secondaryText,
                        offset: const Offset(0.5, 0.5),
                        blurRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Time - right-aligned
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _formatTime(message.createdAt),
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: fontFamily,
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
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender name
          if (showSender)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                '書呆子 ${message.displaySender}',
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: fontFamily,
                ),
              ),
            ),
          // Message bubble - left-aligned
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.primaryBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.tertiary,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    message.content ?? '',
                    style: textTheme.bodyLarge?.copyWith(
                      fontFamily: fontFamily,
                      color: colors.secondaryText,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Time - left-aligned
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                _formatTime(message.createdAt),
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: fontFamily,
                ),
              ),
            ),
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
/// Matches FlutterFlow design: tertiary divider + quaternary label
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
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 0),
      child: Column(
        children: [
          Divider(
            thickness: 2,
            color: colors.tertiary,
          ),
          Text(
            _formatDate(date),
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: fontFamily,
              color: colors.quaternary,
            ),
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
