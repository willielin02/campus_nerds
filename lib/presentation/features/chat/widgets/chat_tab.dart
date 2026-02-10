import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../domain/entities/booking.dart';
import '../bloc/bloc.dart';
import 'chat_input.dart';
import 'chat_messages_list.dart';

/// Chat tab widget for embedding in EventDetailsPage
class ChatTab extends StatefulWidget {
  const ChatTab({
    super.key,
    required this.event,
  });

  final MyEvent event;

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  @override
  void initState() {
    super.initState();
    if (widget.event.groupId != null && widget.event.isChatOpen) {
      context.read<ChatBloc>().add(ChatInitialize(widget.event.groupId!));
    }
  }

  @override
  void dispose() {
    context.read<ChatBloc>().add(const ChatDispose());
    super.dispose();
  }

  /// Format chatOpenAt into a smart relative/absolute time string
  String _formatOpenTime(DateTime chatOpenAt) {
    final now = AppClock.now();
    final local = chatOpenAt.toLocal();
    final diff = local.difference(now);

    // Already past (shouldn't normally reach here, but just in case)
    if (diff.isNegative) return '即將';

    // Less than 1 hour → "X 分鐘後"
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes < 1 ? 1 : diff.inMinutes;
      return '$mins 分鐘後';
    }

    // Same calendar day → "X 小時 X 分鐘後"
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(local.year, local.month, local.day);
    final dayDiff = targetDay.difference(today).inDays;

    final timeStr =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    if (dayDiff == 0) {
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      if (mins == 0) return '$hours 小時後';
      return '$hours 小時 $mins 分鐘後';
    }

    // Tomorrow → "明天 HH:mm"
    if (dayDiff == 1) return '明天 $timeStr';

    // Day after tomorrow → "後天 HH:mm"
    if (dayDiff == 2) return '後天 $timeStr';

    // General → "M 月 d 日 ( 星期X ) HH:mm"
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final weekday = weekdays[local.weekday - 1];
    return '${local.month} 月 ${local.day} 日 ( 星期$weekday ) $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // Chat not open yet
    if (!widget.event.isChatOpen) {
      final fontFamily = GoogleFonts.notoSansTc().fontFamily;
      final chatOpenAt = widget.event.chatOpenAt;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Container(
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Image fills as much space as possible
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 48),
                            child: Opacity(
                              opacity: 0.8,
                              child: Image.asset(
                                'assets/images/Gemini_Generated_Image_g65w8og65w8og65w.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Text at the bottom (two lines, centered)
                        Text(
                          '聊天室將於',
                          style: context.textTheme.labelLarge?.copyWith(
                            fontFamily: fontFamily,
                            color: colors.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          chatOpenAt != null
                              ? '${_formatOpenTime(chatOpenAt)}開啟...'
                              : '活動開始 1 小時前開啟...',
                          style: context.textTheme.labelLarge?.copyWith(
                            fontFamily: fontFamily,
                            color: colors.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '屆時你們會透過聊天室聯絡並確認確切碰面地點。',
                          style: context.textTheme.bodyLarge?.copyWith(
                            fontFamily: fontFamily,
                            color: colors.secondaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Spacer matching ChatInput dimensions for border alignment
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SafeArea(
                top: false,
                child: const SizedBox(height: 48),
              ),
            ),
          ],
        ),
      );
    }

    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colors.error,
            ),
          );
          context.read<ChatBloc>().add(const ChatClearError());
        }
      },
      builder: (context, state) {
        if (state.status == ChatStatus.loading && !state.hasMessages) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ChatStatus.error && !state.hasMessages) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: colors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  '載入失敗',
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: colors.error,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (widget.event.groupId != null) {
                      context
                          .read<ChatBloc>()
                          .add(ChatInitialize(widget.event.groupId!));
                    }
                  },
                  child: const Text('重試'),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              // Messages list in bordered container
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.secondaryBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.tertiary,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ChatMessagesList(
                        messages: state.messages,
                        hasMore: state.hasMore,
                        isLoadingMore: state.isLoadingMore,
                        onLoadMore: () {
                          context
                              .read<ChatBloc>()
                              .add(const ChatLoadMore());
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Input
              ChatInput(
                isSending: state.isSending,
                onSend: (content) {
                  context.read<ChatBloc>().add(ChatSendMessage(content));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
