import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';

/// Contact support page
/// Allows users to contact customer service via email
class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({super.key});

  static const String _supportEmail = 'team@campusnerds.app';
  static const String _appVersion = 'v1.0.3 (103)';

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
          '聯絡客服',
          style: textTheme.titleMedium?.copyWith(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '如有任何問題或建議，歡迎透過以下方式聯絡我們。',
                  style: textTheme.bodyLarge?.copyWith(
                    fontFamily: fontFamily,
                    color: colors.secondaryText,
                  ),
                ),
              ),
              // Email container
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Container(
                  width: double.infinity,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email label
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              color: colors.secondaryText,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '電子郵件',
                              style: textTheme.bodyMedium?.copyWith(
                                fontFamily: fontFamily,
                                color: colors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                        // Email address
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _supportEmail,
                            style: textTheme.bodyLarge?.copyWith(
                              fontFamily: fontFamily,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Action buttons
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            children: [
                              // Copy button
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.copy_outlined,
                                  label: '複製',
                                  onTap: () => _copyEmail(context),
                                  colors: colors,
                                  textTheme: textTheme,
                                  fontFamily: fontFamily,
                                  isOutlined: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Send email button
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.send_outlined,
                                  label: '寄信',
                                  onTap: () => _sendEmail(context),
                                  colors: colors,
                                  textTheme: textTheme,
                                  fontFamily: fontFamily,
                                  isOutlined: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Response time info
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.alternate,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          color: colors.secondaryText,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '預計回覆時間：1-2 個工作天',
                            style: textTheme.bodyMedium?.copyWith(
                              fontFamily: fontFamily,
                              color: colors.secondaryText,
                            ),
                          ),
                        ),
                      ],
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

  void _copyEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _supportEmail));
    final colors = context.appColors;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('已複製到剪貼簿'),
        backgroundColor: colors.secondaryText,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context) async {
    final colors = context.appColors;

    // Build email body with app info
    final emailBody = '''
App 版本：$_appVersion

---
請在此描述您的問題：

''';

    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': '[Campus Nerds] 用戶回饋',
        'body': emailBody,
      },
    );

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: const Text('無法開啟郵件應用程式，請手動發送郵件至 team@campusnerds.app'),
              backgroundColor: colors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('無法開啟郵件應用程式'),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colors,
    required this.textTheme,
    required this.fontFamily,
    required this.isOutlined,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppColorsTheme colors;
  final TextTheme textTheme;
  final String? fontFamily;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isOutlined ? colors.secondaryBackground : colors.alternate,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.tertiary,
            width: isOutlined ? 1 : 0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: colors.secondaryText,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: fontFamily,
                color: colors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}