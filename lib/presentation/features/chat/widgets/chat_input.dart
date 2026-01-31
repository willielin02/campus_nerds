import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Chat input widget with text field and send button
class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSend,
    this.isSending = false,
    this.hintText = '輸入訊息...',
  });

  final void Function(String content) onSend;
  final bool isSending;
  final String hintText;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleSend() {
    final content = _controller.text.trim();
    if (content.isEmpty || widget.isSending) return;

    widget.onSend(content);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        border: Border(
          top: BorderSide(color: colors.alternate),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: colors.primaryBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.alternate),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: colors.secondaryText,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              child: Material(
                color: _hasText && !widget.isSending
                    ? colors.primary
                    : colors.tertiary,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  onTap: _hasText && !widget.isSending ? _handleSend : null,
                  borderRadius: BorderRadius.circular(22),
                  child: Center(
                    child: widget.isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.secondaryText,
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            size: 20,
                            color: _hasText ? Colors.white : colors.secondaryText,
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
