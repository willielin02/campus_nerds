import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';

/// Rules dialog for focused study events
/// Matches FlutterFlow RulesDialogStudy design exactly
class RulesDialogStudy extends StatelessWidget {
  const RulesDialogStudy({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        elevation: 0,
        backgroundColor: Colors.transparent,
        clipBehavior: Clip.none,
        child: RulesDialogStudy(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    return Container(
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
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title in Row
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '活動規則與流程',
                  style: textTheme.titleMedium?.copyWith(
                    fontFamily: fontFamily,
                  ),
                ),
              ],
            ),
            // Rules list
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black,
                          Colors.black,
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.03, 0.97, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      primary: false,
                      shrinkWrap: true,
                      children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRule(
                                context,
                                '1. 手機集中管理',
                                '入座後交出手機，關靜音，放在桌子中央大家都看得到的地方。',
                              ),
                              Divider(thickness: 2, color: colors.alternate),
                              _buildRule(
                                context,
                                '2. 寫下 3 個待辦事項',
                                '開始前，寫下本時段要完成的 3 個待辦事項。',
                              ),
                              Divider(thickness: 2, color: colors.alternate),
                              _buildRule(
                                context,
                                '3. 全程專心學習',
                                '讀書期間不講話、不滑手機、不打擾他人，需要離席請安靜離開。',
                              ),
                              Divider(thickness: 2, color: colors.alternate),
                              _buildRule(
                                context,
                                '4. 中場檢查進度',
                                '讀書一個段落後，一起吃飯/ 休息，互相檢查是否完成當初寫下的 3 個待辦事項，可以簡短分享成果。',
                              ),
                              Divider(thickness: 2, color: colors.alternate),
                              _buildRule(
                                context,
                                '5. 活動結束後匿名回饋',
                                '活動後請為同桌夥伴留下回饋，包含：專注程度、達標程度、是否有抖腳/ 講話等影響他人的行為',
                              ),
                              Divider(thickness: 2, color: colors.alternate),
                              _buildRule(
                                context,
                                '6. 尊重場地與他人',
                                '遵守場地規定，不大聲喧嘩，不做讓人不舒服的行為。',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    ),
                  ),
                ),
              ),
            ),
            // "我知道了" button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.alternate,
                    foregroundColor: colors.primaryText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '我知道了',
                    style: textTheme.bodyLarge?.copyWith(
                      fontFamily: fontFamily,
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

  Widget _buildRule(BuildContext context, String title, String description) {
    final textTheme = context.textTheme;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              fontFamily: fontFamily,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              description,
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
