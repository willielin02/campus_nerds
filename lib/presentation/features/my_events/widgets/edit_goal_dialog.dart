import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';

/// Dialog for editing a study plan goal
/// Matches FlutterFlow EditDialogGoal1/2/3 design
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

  /// Show the edit goal dialog matching FlutterFlow design
  static void show(
    BuildContext context, {
    required int slot,
    String? planId,
    String? initialContent,
    bool initialIsDone = false,
    bool canEditContent = true,
    bool canEditCompletion = true,
    required void Function(String content, bool isDone) onSave,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        clipBehavior: Clip.none,
        child: EditGoalDialog(
          slot: slot,
          planId: planId,
          initialContent: initialContent,
          initialIsDone: initialIsDone,
          canEditContent: canEditContent,
          canEditCompletion: canEditCompletion,
          onSave: onSave,
        ),
      ),
    );
  }

  @override
  State<EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<EditGoalDialog> {
  late final TextEditingController _contentController;
  late bool _isDone;

  @override
  void initState() {
    super.initState();
    _contentController =
        TextEditingController(text: widget.initialContent ?? '');
    _isDone = widget.initialIsDone;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _handleSave() {
    // If content editing is closed, send original content
    final content = widget.canEditContent
        ? _contentController.text.trim()
        : (widget.initialContent ?? '');
    widget.onSave(content, _isDone);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: 579,
        decoration: BoxDecoration(
          color: colors.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.tertiary,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title: "編輯待辦事項 N "
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Text(
                      '編輯待辦事項 ${widget.slot} ',
                      style: textTheme.labelLarge?.copyWith(
                        fontFamily: fontFamily,
                        color: colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              // Text field (only when canEditContent)
              if (widget.canEditContent)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      controller: _contentController,
                      autofocus: false,
                      decoration: InputDecoration(
                        isDense: true,
                        labelStyle: textTheme.bodyLarge?.copyWith(
                          fontFamily: fontFamily,
                        ),
                        hintText: '請輸入待辦事項 ${widget.slot}',
                        hintStyle: textTheme.bodyLarge?.copyWith(
                          fontFamily: fontFamily,
                          color: colors.tertiary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colors.quaternary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colors.error,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colors.error,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: colors.secondaryBackground,
                      ),
                      style: textTheme.bodyLarge?.copyWith(
                        fontFamily: fontFamily,
                      ),
                      maxLines: null,
                      cursorColor: colors.primaryText,
                    ),
                  ),
                ),

              // Checkbox row (only when canEditCompletion)
              if (widget.canEditCompletion)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Theme(
                        data: ThemeData(
                          checkboxTheme: CheckboxThemeData(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          unselectedWidgetColor: colors.tertiaryText,
                        ),
                        child: Checkbox(
                          value: _isDone,
                          onChanged: (v) => setState(() => _isDone = v!),
                          side: BorderSide(
                            width: 2,
                            color: colors.tertiaryText,
                          ),
                          activeColor: colors.secondaryText,
                          checkColor: colors.primary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          _isDone
                              ? '待辦事項 ${widget.slot} 已完成'
                              : '待辦事項 ${widget.slot} 尚未完成',
                          style: textTheme.bodyLarge?.copyWith(
                            fontFamily: fontFamily,
                            color: _isDone
                                ? colors.secondaryText
                                : colors.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Buttons row
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: Row(
                  children: [
                    // "取消" button
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.secondaryBackground,
                              foregroundColor: colors.primaryText,
                              elevation: 0.2,
                              side: BorderSide(color: colors.tertiary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              '取消',
                              style: textTheme.bodyLarge?.copyWith(
                                fontFamily: fontFamily,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // "確定" button
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.alternate,
                              foregroundColor: colors.primaryText,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              '確定',
                              style: textTheme.bodyLarge?.copyWith(
                                fontFamily: fontFamily,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
