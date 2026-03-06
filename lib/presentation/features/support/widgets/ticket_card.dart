import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/support.dart';

class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  final SupportTicket ticket;
  final VoidCallback onTap;

  IconData _categoryIcon(TicketCategory category) {
    switch (category) {
      case TicketCategory.schoolVerification:
        return Icons.school_outlined;
      case TicketCategory.payment:
        return Icons.payment_outlined;
      case TicketCategory.bugReport:
        return Icons.bug_report_outlined;
      case TicketCategory.other:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.secondaryBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colors.tertiary,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.alternate,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _categoryIcon(ticket.category),
                  color: colors.secondaryText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Title + category + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.subject,
                      style: typo.detail.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          ticket.category.label,
                          style: typo.caption.copyWith(
                            color: colors.secondaryText,
                          ),
                        ),
                        Text(
                          '  ·  ${_formatTime(ticket.updatedAt)}',
                          style: typo.caption.copyWith(
                            color: colors.quaternary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              _StatusBadge(status: ticket.status),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '剛剛';
    if (diff.inHours < 1) return '${diff.inMinutes} 分鐘前';
    if (diff.inHours < 24) return '${diff.inHours} 小時前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return DateFormat('M/d').format(dt);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TicketStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.isClosed ? colors.alternate : colors.tertiaryText,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: typo.footnote.copyWith(
          color: status.isClosed
              ? colors.secondaryText
              : colors.secondaryBackground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
