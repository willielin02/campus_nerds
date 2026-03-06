import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/support.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
  });

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender label
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 4),
              child: Text(
                '客服',
                style: typo.caption.copyWith(
                  color: colors.secondaryText,
                ),
              ),
            ),
          // Bubble
          Container(
            decoration: BoxDecoration(
              color: isUser
                  ? colors.tertiaryText
                  : colors.primaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: isUser
                  ? null
                  : Border.all(color: colors.tertiary, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  if (message.hasImage && message.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: GestureDetector(
                          onTap: () => _showFullImage(context, message.imageUrl!),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: Image.network(
                              message.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 80,
                                color: colors.alternate,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: colors.secondaryText,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Text
                  if (message.content != null && message.content!.isNotEmpty)
                    Text(
                      message.content!,
                      style: typo.detail.copyWith(
                        color: isUser
                            ? colors.secondaryBackground
                            : colors.primaryText,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: typo.footnote.copyWith(
                color: colors.quaternary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}
