import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';

/// Chat input widget with text field and send button
/// Matches FlutterFlow EventDetailsStudy chat input design
class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSend,
    this.isSending = false,
  });

  final void Function(String content) onSend;
  final bool isSending;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus != _hasFocus) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    }
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
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Container(
        height: 48,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hasFocus ? colors.quaternary : colors.tertiary,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Text input
            Expanded(
              child: TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                cursorColor: colors.primaryText,
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (_) => _handleSend(),
                style: textTheme.bodyLarge?.copyWith(
                  fontFamily: fontFamily,
                ),
                decoration: InputDecoration(
                  hintText: '請輸入訊息',
                  hintStyle: textTheme.bodyLarge?.copyWith(
                    fontFamily: fontFamily,
                    color: colors.quaternary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  isDense: true,
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            // Send button
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: widget.isSending
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Material(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap:
                            _hasText && !widget.isSending ? _handleSend : null,
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.send_rounded,
                            size: 20,
                            color: colors.secondaryText,
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
