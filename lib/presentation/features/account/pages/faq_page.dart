import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';

/// FAQ (常見問題與使用說明) page
/// Uses ExpansionTile for accordion-style FAQ list with categories
class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

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
          style: textTheme.titleMedium?.copyWith(
            fontFamily: fontFamily,
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
              stops: const [0.0, 0.03, 0.97, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
            // 活動報名
            _FaqCategory(
              title: '活動報名',
              icon: Icons.event_outlined,
              items: const [
                _FaqItem(
                  question: '如何報名活動？',
                  answer: '在首頁選擇想參加的活動，點擊「報名」按鈕即可。報名時會自動扣除一張對應類型的票券（專注讀書或英文遊戲）。',
                ),
                _FaqItem(
                  question: '報名開放與截止時間？',
                  answer: '每場活動於活動日期前 23 天開放報名，並於活動日期前 3 天晚上 23:59 截止報名。',
                ),
                _FaqItem(
                  question: '如何取消報名？',
                  answer: '在「我的活動」頁面找到已報名的活動，點擊進入後選擇「取消報名」。請注意，只能在報名截止時間前取消。',
                ),
                _FaqItem(
                  question: '取消報名後票券會退還嗎？',
                  answer: '會的！在報名截止時間前取消報名，票券會立即退還到您的帳戶。',
                ),
                _FaqItem(
                  question: '可以同時報名多場活動嗎？',
                  answer: '可以報名多場活動，但不能報名同一天同時段的活動（例如同一天的上午場只能選一場）。',
                ),
              ],
              colors: colors,
              textTheme: textTheme,
              fontFamily: fontFamily,
            ),
            const SizedBox(height: 12),

            // 票券相關
            _FaqCategory(
              title: '票券相關',
              icon: Icons.confirmation_number_outlined,
              items: const [
                _FaqItem(
                  question: '專注讀書票和英文遊戲票有什麼差別？',
                  answer: '這是兩種不同類型的活動票券，分別用於「專注讀書」和「英文遊戲」活動。兩種票券獨立計算，不能互相轉換。',
                ),
                _FaqItem(
                  question: '如何購買票券？',
                  answer: '點擊首頁右上角的票券圖示，或從「帳號」頁面進入「票券紀錄」，即可進入購票頁面選購票券組合。',
                ),
                _FaqItem(
                  question: '支援哪些付款方式？',
                  answer: '目前支援信用卡/金融卡付款，透過綠界科技 (ECPay) 安全處理。',
                ),
                _FaqItem(
                  question: '付款失敗怎麼辦？',
                  answer: '請確認您的信用卡額度充足且卡片資訊正確。如持續失敗，建議更換其他信用卡或聯絡客服協助。',
                ),
              ],
              colors: colors,
              textTheme: textTheme,
              fontFamily: fontFamily,
            ),
            const SizedBox(height: 12),

            // 分組機制
            _FaqCategory(
              title: '分組機制',
              icon: Icons.group_outlined,
              items: const [
                _FaqItem(
                  question: '分組是如何運作的？',
                  answer: '系統會在活動前 2 天自動進行分組。分組時會確保每組男女比例為 1:1，並盡量避免將 Facebook 好友分到同一組，讓您有更多機會認識新朋友。',
                ),
                _FaqItem(
                  question: '什麼時候會知道分組結果？',
                  answer: '分組完成後，您會收到 App 內通知。同時可以在「我的活動」查看您的組別和組員資訊。',
                ),
                _FaqItem(
                  question: '為什麼要綁定 Facebook？',
                  answer: '綁定 Facebook 後，系統可以識別您在 App 中的 Facebook 好友，並在分組時避免將你們分到同一組。這樣您就能認識更多新朋友！',
                ),
                _FaqItem(
                  question: '如果這次沒有被分到組怎麼辦？',
                  answer: '別擔心！如果因為人數或性別比例因素這次沒有成功分組，您在下次報名時會獲得優先分組權，系統會優先為您配對。',
                ),
                _FaqItem(
                  question: '解除 Facebook 綁定會影響分組嗎？',
                  answer: '解除綁定後，系統仍會記住之前已識別的好友關係，確保分組時繼續避開這些人。這是為了讓您持續有機會認識新朋友。',
                ),
              ],
              colors: colors,
              textTheme: textTheme,
              fontFamily: fontFamily,
            ),
            const SizedBox(height: 12),

            // 聊天室與活動當天
            _FaqCategory(
              title: '聊天室與活動當天',
              icon: Icons.chat_outlined,
              items: const [
                _FaqItem(
                  question: '聊天室何時開放？',
                  answer: '聊天室會在活動開始前 1 小時開放，讓您可以提前和組員打招呼、確認碰面地點。',
                ),
                _FaqItem(
                  question: '讀書目標功能怎麼使用？',
                  answer: '在「專注讀書」活動中，您可以設定 3 個讀書目標。活動開始後 1 小時內可以編輯目標，之後可以勾選完成狀態。這能幫助您更有效率地讀書！',
                ),
                _FaqItem(
                  question: '活動結束後需要做什麼？',
                  answer: '活動結束後會開放回饋功能，您可以為這次活動和組員留下評價。您的回饋有助於我們改善服務品質。',
                ),
              ],
              colors: colors,
              textTheme: textTheme,
              fontFamily: fontFamily,
            ),
            const SizedBox(height: 12),

            // 帳號設定
            _FaqCategory(
              title: '帳號設定',
              icon: Icons.person_outlined,
              items: const [
                _FaqItem(
                  question: '為什麼需要驗證學校信箱？',
                  answer: '驗證學校信箱是為了確認您的大學生身份，維護社群品質，讓所有參與者都是真正的大學生。',
                ),
                _FaqItem(
                  question: '如何驗證學校信箱？',
                  answer: '前往「帳號」>「學校信箱驗證」，輸入您的學校 Email（通常是 .edu.tw 結尾），系統會發送 6 位數驗證碼到您的信箱，輸入驗證碼即可完成驗證。',
                ),
                _FaqItem(
                  question: '驗證碼多久會過期？',
                  answer: '驗證碼有效期限為 15 分鐘。如果過期，請重新發送驗證碼。',
                ),
                _FaqItem(
                  question: '如何綁定或解除 Facebook？',
                  answer: '前往「帳號」>「臉書綁定」，按照畫面指示操作即可綁定或解除綁定。',
                ),
              ],
              colors: colors,
              textTheme: textTheme,
              fontFamily: fontFamily,
            ),
            const SizedBox(height: 12),

            // 法律資訊
            _FaqCategory(
              title: '法律資訊',
              icon: Icons.gavel_outlined,
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
              colors: colors,
              textTheme: textTheme,
              fontFamily: fontFamily,
            ),
            const SizedBox(height: 24),
          ],
          ),
        ),
      ),
    );
  }
}

/// FAQ category with expandable items
class _FaqCategory extends StatelessWidget {
  const _FaqCategory({
    required this.title,
    required this.icon,
    required this.items,
    required this.colors,
    required this.textTheme,
    required this.fontFamily,
  });

  final String title;
  final IconData icon;
  final List<_FaqItem> items;
  final AppColorsTheme colors;
  final TextTheme textTheme;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.tertiary,
          width: 2,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Icon(
            icon,
            color: colors.secondaryText,
            size: 24,
          ),
          title: Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              fontFamily: fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconColor: colors.secondaryText,
          collapsedIconColor: colors.secondaryText,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: items.map((item) {
            return _FaqItemTile(
              item: item,
              colors: colors,
              textTheme: textTheme,
              fontFamily: fontFamily,
            );
          }).toList(),
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

/// FAQ item tile widget
class _FaqItemTile extends StatelessWidget {
  const _FaqItemTile({
    required this.item,
    required this.colors,
    required this.textTheme,
    required this.fontFamily,
  });

  final _FaqItem item;
  final AppColorsTheme colors;
  final TextTheme textTheme;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: colors.alternate,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Text(
              item.question,
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: fontFamily,
                color: colors.primaryText,
              ),
            ),
            iconColor: colors.secondaryText,
            collapsedIconColor: colors.secondaryText,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.answer,
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: fontFamily,
                    color: colors.secondaryText,
                    height: 1.5,
                  ),
                ),
              ),
              if (item.url != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(item.url!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '查看完整內容',
                          style: textTheme.bodyMedium?.copyWith(
                            fontFamily: fontFamily,
                            color: colors.secondaryText,
                            fontWeight: FontWeight.w600,
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
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

