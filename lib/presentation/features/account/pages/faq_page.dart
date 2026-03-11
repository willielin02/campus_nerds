import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';

/// FAQ (常見問題與使用說明) page
/// Single-level accordion with static category headers
class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: colors.primaryText,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '常見問題與使用說明',
          style: typo.heading.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
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
              stops: const [0.0, 0.05, 0.95, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            _buildSection(
              icon: Icons.event_outlined,
              title: '活動報名',
              colors: colors,
              typo: typo,
              items: const [
                _FaqItem(
                  question: '如何報名活動？',
                  answer: '在首頁選擇想參加的活動，點擊「確認報名」按鈕即可。報名時會自動扣除一張對應類型 ( Focused Study 或 English Games ) 的票券。',
                ),
                _FaqItem(
                  question: '報名開放與截止時間？',
                  answer: '每場活動均於活動日期前 23 天開放報名，並於活動日期 3 天前晚上 23:59 截止報名。',
                ),
                _FaqItem(
                  question: '如何取消報名？',
                  answer: '在「我的活動」頁面找到已報名的活動，點擊進入後選擇「取消報名」。請注意，只能在報名截止時間前取消。',
                ),
                _FaqItem(
                  question: '取消報名後票券會退還嗎？',
                  answer: '會的！在報名截止時間前取消報名，票券會立即退還到您的票券餘額。',
                ),
                _FaqItem(
                  question: '可以同時報名多場活動嗎？',
                  answer: '可以報名多場活動，但不能報名同一天同時段的活動（例如同一天的上午場只能選一場）。',
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSection(
              icon: Icons.confirmation_number_outlined,
              title: '票券相關',
              colors: colors,
              typo: typo,
              items: const [
                _FaqItem(
                  question: 'Study 票券和 Games 票券有什麼差別？',
                  answer: '這是兩種不同類型的活動票券，分別用於「Focused Study」和「English Games」活動。兩種票券獨立計算，不能互相轉換。',
                ),
                _FaqItem(
                  question: '如何購買票券？',
                  answer: '點擊首頁右上角的票券圖示，或進入「帳號」頁面中的「票券紀錄」頁面，並點擊右上角的票券圖示，即可進入購票頁面選購票券組合。',
                ),
                _FaqItem(
                  question: '支援哪些付款方式？',
                  answer: '目前支援信用卡/ 金融卡/ Apple Pay 付款，透過綠界科技 ( ECPay ) 安全處理。',
                ),
                _FaqItem(
                  question: '付款失敗怎麼辦？',
                  answer: '請確認您的付款方式額度充足且資訊正確。如持續失敗，建議更換其他付款方式或聯絡客服協助。',
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSection(
              icon: Icons.group_outlined,
              title: '分組機制',
              colors: colors,
              typo: typo,
              items: const [
                _FaqItem(
                  question: '分組是如何運作的？',
                  answer: '系統會在活動日 2 天前自動進行分組。分組時會避免將 Facebook 好友分到同一組，並盡量確保每組男女比例均衡，讓您有更多機會認識新朋友。',
                ),
                _FaqItem(
                  question: '為什麼要綁定 Facebook？',
                  answer: '綁定 Facebook 後，系統可以識別您在 App 中的 Facebook 好友，並在分組時避免將你們分到同一組。這樣您就能認識更多新朋友！',
                ),
                _FaqItem(
                  question: '如何綁定或解除 Facebook？',
                  answer: '前往「帳號」>「臉書綁定」，按照畫面指示操作即可綁定或解除綁定。',
                ),
                _FaqItem(
                  question: '什麼時候會知道分組結果？',
                  answer: '系統會在活動日 2 天前自動進行分組。分組完成後，您會收到 App 通知。同時可以在「我的活動」頁面查看您的組別和組員資訊。',
                ),
                _FaqItem(
                  question: '如果這次沒有被分到組怎麼辦？',
                  answer: '別擔心！如果因為人數或性別比例因素這次沒有成功分組，您在下次報名時會獲得優先分組權，系統會優先為您配對。',
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSection(
              icon: Icons.chat_outlined,
              title: '聊天室與活動當天',
              colors: colors,
              typo: typo,
              items: const [
                _FaqItem(
                  question: '聊天室何時開放？',
                  answer: '聊天室會在活動開始前 1 小時開放，讓您可以提前和組員打招呼、確認碰面地點。',
                ),
                _FaqItem(
                  question: 'Focused Study 中的待辦事項是什麼？',
                  answer: '在 Focused Study 活動中，您可以在活動開始前設定 3 個待辦事項。活動開始後 1 小時內可以編輯待辦事項，之後可以勾選完成狀態。這不僅讓您更有效地運用這段學習時間，也讓您和組員間可以互相監督！',
                ),
                _FaqItem(
                  question: 'English Games 中的學習內容是什麼？',
                  answer: '在 English Games 活動中，每位組員會被分配專屬的學習內容 ( 片語/ 句子 )。您需要在活動開始前熟記這些內容，並在遊戲過程中活用。活動進行至一個段落後，組員間會互相檢查是否學會並活用了各自的學習內容。',
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSection(
              icon: Icons.gavel_outlined,
              title: '法律資訊',
              colors: colors,
              typo: typo,
              items: const [
                _FaqItem(
                  question: '隱私權政策',
                  answer: '說明我們如何蒐集、使用及保護您的個人資料。',
                  url: 'https://campusnerds.app/privacy.html',
                ),
                _FaqItem(
                  question: '服務條款',
                  answer: '使用 Campus Nerds 服務時應遵守的條款與規範。',
                  url: 'https://campusnerds.app/terms.html',
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// Builds a category section: static header + card with FAQ items
  Widget _buildSection({
    required IconData icon,
    required String title,
    required AppColorsTheme colors,
    required AppTypography typo,
    required List<_FaqItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header (static, not expandable)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, size: 22, color: colors.secondaryText),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: typo.body.copyWith(
                  color: colors.secondaryText,
                ),
              ),
            ],
          ),
        ),
        // Card containing all FAQ items
        _FaqCard(items: items, colors: colors, typo: typo),
      ],
    );
  }
}

/// Card containing a list of single-level expandable FAQ items
class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.items,
    required this.colors,
    required this.typo,
  });

  final List<_FaqItem> items;
  final AppColorsTheme colors;
  final AppTypography typo;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.tertiary, width: 2),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              _FaqItemTile(
                item: items[i],
                colors: colors,
                typo: typo,
              ),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: colors.alternate,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Single FAQ item data
class _FaqItem {
  const _FaqItem({
    required this.question,
    required this.answer,
    this.url,
  });

  final String question;
  final String answer;
  final String? url;
}

/// FAQ item tile — single-level ExpansionTile
class _FaqItemTile extends StatelessWidget {
  const _FaqItemTile({
    required this.item,
    required this.colors,
    required this.typo,
  });

  final _FaqItem item;
  final AppColorsTheme colors;
  final AppTypography typo;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          item.question,
          style: typo.detail.copyWith(
            color: colors.primaryText,
          ),
          maxLines: 1,
        ),
      ),
      iconColor: colors.secondaryText,
      collapsedIconColor: colors.secondaryText,
      children: [
        Builder(
          builder: (tileContext) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  ExpansionTileController.of(tileContext).collapse(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.answer,
                    style: typo.caption.copyWith(
                      color: colors.secondaryText,
                      height: 1.5,
                    ),
                  ),
                  if (item.url != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse(item.url!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                              uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '查看完整內容',
                            style: typo.caption.copyWith(
                              color: colors.secondaryText,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.open_in_new,
                            color: colors.secondaryText,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
