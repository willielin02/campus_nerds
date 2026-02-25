import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';

/// Rules dialog for english games events
/// Aligned with RulesDialogStudy design
class RulesDialogGames extends StatefulWidget {
  const RulesDialogGames({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        elevation: 0,
        backgroundColor: Colors.transparent,
        clipBehavior: Clip.none,
        child: RulesDialogGames(),
      ),
    );
  }

  @override
  State<RulesDialogGames> createState() => _RulesDialogGamesState();
}

class _RulesDialogGamesState extends State<RulesDialogGames> {
  final ScrollController _scrollController = ScrollController();
  bool _isClosing = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    if (_isClosing) return;
    setState(() => _isClosing = true);

    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 666),
      curve: Curves.ease,
    );
    await Future.delayed(const Duration(milliseconds: 666));

    if (!mounted) return;
    Navigator.of(context).pop();
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
                  style: textTheme.labelLarge?.copyWith(
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
                      controller: _scrollController,
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
                                '1. 熟記自己的學習內容',
                                '開始前，先熟記本時段要學會的學習內容 ( 片語/ 句子 ) ，以利於在遊戲過程中活用。自己的學習內容將於活動開始一段時間後消失。',
                              ),
                              Divider(thickness: 2, color: colors.alternate),
                              _buildRule(
                                context,
                                '2. AI 口說進步建議',
                                '開始前，按下錄音鍵確保手機錄得到自己的口說內容 ( 錄自己的內容即可 ) ，在活動結束後 AI 會根據口說內容給予進步建議。',
                              ),
                              Divider(thickness: 2, color: colors.alternate),
                              _buildRule(
                                context,
                                '3. 全程英語交談',
                                '遊戲期間禁止使用任何非英文的語言，並認真參與遊戲。',
                              ),
                              Divider(thickness: 2, color: colors.alternate),
                              _buildRule(
                                context,
                                '4. 中場檢查',
                                '遊戲至一個段落後，一起吃飯/ 休息，互相檢查是否學會並在遊戲中活用當初被分配的學習內容 ( 片語/ 句子 ) 。',
                              ),
                              Divider(thickness: 2, color: colors.alternate),
                              _buildRule(
                                context,
                                '5. 活動結束後匿名回饋',
                                '活動後請為同桌夥伴留下回饋，包含：投入程度、達標程度、是否有令人不悅的行為。',
                              ),
                              Divider(thickness: 2, color: colors.alternate),
                              _buildRule(
                                context,
                                '6. 尊重場地與他人',
                                '遵守場地規定，不破壞設備，不做讓人不舒服的行為，也絕對嚴禁取笑他人的英語口說。',
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
                  onPressed: _isClosing ? null : _handleClose,
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
              style: context.appTypography.bodyBig,
            ),
          ),
        ],
      ),
    );
  }
}
