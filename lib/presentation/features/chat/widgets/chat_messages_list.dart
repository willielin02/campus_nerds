import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/chat.dart';
import 'chat_message_bubble.dart';

/// Chat messages list widget with reverse scroll
class ChatMessagesList extends StatefulWidget {
  const ChatMessagesList({
    super.key,
    required this.messages,
    required this.onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<ChatMessage> messages;
  final VoidCallback onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;

  @override
  State<ChatMessagesList> createState() => _ChatMessagesListState();
}

class _ChatMessagesListState extends State<ChatMessagesList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when user scrolls near the top (oldest messages)
    // Since list is reversed, "top" means the end of the list
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (widget.hasMore && !widget.isLoadingMore) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (widget.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: colors.secondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              '開始聊天吧！',
              style: context.textTheme.bodyLarge?.copyWith(
                color: colors.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Newest messages at the bottom
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.messages.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at the top (oldest messages)
        if (index == widget.messages.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: widget.isLoadingMore
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : TextButton(
                      onPressed: widget.onLoadMore,
                      child: Text(
                        '載入更多',
                        style: TextStyle(color: colors.primary),
                      ),
                    ),
            ),
          );
        }

        final message = widget.messages[index];
        final previousMessage =
            index < widget.messages.length - 1 ? widget.messages[index + 1] : null;

        // Show date divider when date changes
        final showDateDivider = previousMessage == null ||
            !_isSameDay(message.createdAt, previousMessage.createdAt);

        // Show sender name when sender changes or after date divider
        final showSender = !message.isMe &&
            !message.isSystemMessage &&
            (previousMessage == null ||
                previousMessage.senderUserId != message.senderUserId ||
                showDateDivider);

        return Column(
          children: [
            if (showDateDivider) ChatDateDivider(date: message.createdAt),
            ChatMessageBubble(
              message: message,
              showSender: showSender,
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
