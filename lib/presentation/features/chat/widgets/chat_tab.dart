import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // Chat not open yet
    if (!widget.event.isChatOpen) {
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
              '聊天室尚未開放',
              style: context.textTheme.bodyLarge?.copyWith(
                color: colors.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '活動開始後即可聊天',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.secondaryText,
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

        return Column(
          children: [
            // Messages list
            Expanded(
              child: ChatMessagesList(
                messages: state.messages,
                hasMore: state.hasMore,
                isLoadingMore: state.isLoadingMore,
                onLoadMore: () {
                  context.read<ChatBloc>().add(const ChatLoadMore());
                },
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
        );
      },
    );
  }
}
