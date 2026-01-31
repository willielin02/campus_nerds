import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';

/// Rules dialog for focused study events
/// Matches FlutterFlow design exactly
class RulesDialogStudy extends StatelessWidget {
  const RulesDialogStudy({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: RulesDialogStudy(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                '鐵打的規則',
                style: textTheme.titleMedium?.copyWith(
                  fontFamily: GoogleFonts.notoSansTc().fontFamily,
                ),
              ),
              const SizedBox(height: 4),
              // Rules list
              Flexible(
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rule 1
                          _buildRule(
                            context,
                            '1. 手機集中管理',
                            '入座後交出手機，關靜音，放在桌子中央大家都看得到的地方。',
                          ),
                          Divider(thickness: 2, color: colors.alternate),
                          // Rule 2
                          _buildRule(
                            context,
                            '2. 寫下讀書計畫',
                            '開始前，寫下本時段要完成的 3 個讀書目標。',
                          ),
                          Divider(thickness: 2, color: colors.alternate),
                          // Rule 3
                          _buildRule(
                            context,
                            '3. 全程專心讀書',
                            '讀書期間不講話、不滑手機、不打擾他人，需要離席請安靜離開。',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Close button
              Center(
                child: SizedBox(
                  width: 144,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colors.secondaryBackground,
                      foregroundColor: colors.secondaryText,
                      side: BorderSide(color: colors.tertiary, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '關閉',
                      style: textTheme.labelLarge?.copyWith(
                        fontFamily: GoogleFonts.notoSansTc().fontFamily,
                        color: colors.secondaryText,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRule(BuildContext context, String title, String description) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              fontFamily: GoogleFonts.notoSansTc().fontFamily,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              description,
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: GoogleFonts.notoSansTc().fontFamily,
                color: colors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
