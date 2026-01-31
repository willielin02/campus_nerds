import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Dialog for editing a study plan goal
class EditGoalDialog extends StatefulWidget {
  const EditGoalDialog({
    super.key,
    required this.slot,
    this.planId,
    this.initialContent,
    this.initialIsDone = false,
    this.canEditContent = true,
    this.canEditCompletion = true,
    required this.onSave,
  });

  final int slot;
  final String? planId;
  final String? initialContent;
  final bool initialIsDone;
  final bool canEditContent;
  final bool canEditCompletion;
  final void Function(String content, bool isDone) onSave;

  @override
  State<EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<EditGoalDialog> {
  late final TextEditingController _contentController;
  late bool _isDone;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    _isDone = widget.initialIsDone;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final content = _contentController.text.trim();
    widget.onSave(content, _isDone);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Dialog(
      backgroundColor: colors.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.slot}',
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '編輯待辦事項',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content input
            if (widget.canEditContent) ...[
              Text(
                '內容',
                style: textTheme.labelMedium?.copyWith(
                  color: colors.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                maxLines: 3,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: '輸入你要完成的目標...',
                  hintStyle: TextStyle(color: colors.secondaryText),
                  filled: true,
                  fillColor: colors.primaryBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.alternate),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.alternate),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                  counterStyle: TextStyle(color: colors.secondaryText),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Show read-only content when editing is disabled
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.alternate),
                ),
                child: Text(
                  widget.initialContent ?? '(無內容)',
                  style: textTheme.bodyMedium?.copyWith(
                    color: widget.initialContent != null
                        ? colors.primaryText
                        : colors.secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '已超過編輯截止時間，無法修改內容',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.warning,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Completion checkbox
            if (widget.canEditCompletion)
              InkWell(
                onTap: () {
                  setState(() {
                    _isDone = !_isDone;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _isDone
                        ? colors.success.withOpacity(0.1)
                        : colors.primaryBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isDone ? colors.success : colors.alternate,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _isDone ? colors.success : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _isDone ? colors.success : colors.secondaryText,
                            width: 2,
                          ),
                        ),
                        child: _isDone
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '已完成此目標',
                        style: textTheme.bodyMedium?.copyWith(
                          color: _isDone ? colors.success : colors.primaryText,
                          fontWeight: _isDone ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.tertiary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: colors.secondaryText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '已超過完成打卡截止時間',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.secondaryText,
                      side: BorderSide(color: colors.alternate),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (widget.canEditContent || widget.canEditCompletion)
                        ? _handleSave
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('確認'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
