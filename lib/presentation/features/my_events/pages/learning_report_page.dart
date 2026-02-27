import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/learning_report.dart';

/// 學習報告頁面 — 顯示 AI 分析結果
class LearningReportPage extends StatelessWidget {
  final LearningReport report;

  const LearningReportPage({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.primaryBackground,
      appBar: AppBar(
        title: Text(
          '學習報告',
          style: TextStyle(
            fontFamily: GoogleFonts.notoSansTc().fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.primaryText,
          ),
        ),
        backgroundColor: colors.secondaryBackground,
        foregroundColor: colors.primaryText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 總錄音時長
            Center(
              child: Column(
                children: [
                  Icon(Icons.mic, size: 32, color: colors.tertiaryText),
                  const SizedBox(height: 4),
                  Text(
                    '總錄音時長',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.secondaryText,
                    ),
                  ),
                  Text(
                    report.formattedDuration,
                    style: TextStyle(
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: colors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 做得好的地方
            if (report.strengths.isNotEmpty)
              _buildCard(
                title: '做得好的地方',
                colors: colors,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: report.strengths
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: colors.primaryText)),
                                Expanded(
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: colors.primaryText),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),

            // Top 3 修正
            ...report.topFixes.asMap().entries.map((entry) {
              final i = entry.key + 1;
              final fix = entry.value;
              return _buildCard(
                title: '修正 #$i：${fix.habit}',
                colors: colors,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '出現頻率：${fix.frequency}',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...fix.examples.map((ex) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '原句：${ex.original}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.tertiaryText,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '改為：${ex.better}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )),
                    Text(
                      '→ ${fix.why}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.primaryText,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // 總結
            if (report.summary != null && report.summary!.isNotEmpty)
              _buildCard(
                title: '總結',
                colors: colors,
                child: Text(
                  report.summary!,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.primaryText,
                    height: 1.5,
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required AppColorsTheme colors,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        border: Border.all(color: colors.tertiary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: GoogleFonts.notoSansTc().fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
