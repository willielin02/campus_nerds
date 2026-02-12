import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';

/// Rules dialog for english games events
/// Matches FlutterFlow design exactly
class RulesDialogGames extends StatefulWidget {
  const RulesDialogGames({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                '活動規則與流程',
                style: textTheme.titleMedium?.copyWith(
                  fontFamily: GoogleFonts.notoSansTc().fontFamily,
                ),
              ),
              const SizedBox(height: 4),
              // Rules list
              Flexible(
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
                              '2. 領取今日單字／片語',
                              '開始前，每人會拿到一個 實用英文單字或片語，本場遊戲中盡量多次使用。',
                            ),
                            Divider(thickness: 2, color: colors.alternate),
                            // Rule 3
                            _buildRule(
                              context,
                              '3. 全程對話一律英文',
                              '遊戲過程中，所有討論與聊天都用英文（即使和店員溝通可以也要說英文）。',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Close button
              Center(
                child: SizedBox(
                  width: 144,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isClosing ? null : _handleClose,
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
