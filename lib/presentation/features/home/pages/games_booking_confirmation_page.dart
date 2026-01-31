import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/event.dart';
import '../bloc/bloc.dart';

/// Booking confirmation page for English Games events
///
/// Shows event details, rules, and confirms the booking.
/// UI matches FlutterFlow design exactly.
class GamesBookingConfirmationPage extends StatefulWidget {
  const GamesBookingConfirmationPage({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  State<GamesBookingConfirmationPage> createState() =>
      _GamesBookingConfirmationPageState();
}

class _GamesBookingConfirmationPageState
    extends State<GamesBookingConfirmationPage> {
  final ScrollController _listViewController = ScrollController();
  final ScrollController _columnController = ScrollController();

  @override
  void dispose() {
    _listViewController.dispose();
    _columnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            backgroundColor: colors.primaryBackground,
            body: SafeArea(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(),
                child: Column(
                  children: [
                    // Header row
                    _buildHeader(context, colors, textTheme),
                    // Content
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              // Title row: "English Games ( city )"
                              _buildTitleRow(colors, textTheme, state),
                              // Subtitle row with ticket balance
                              _buildSubtitleRow(context, colors, textTheme, state),
                              // Description text right-aligned
                              _buildDescriptionRow(textTheme),
                              // ListView with event card, rules, and notice
                              Expanded(
                                child: ListView(
                                  controller: _listViewController,
                                  padding: EdgeInsets.zero,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Column(
                                        children: [
                                          // Event info card
                                          _buildEventCard(colors, textTheme),
                                          // Rules card
                                          _buildRulesCard(colors, textTheme),
                                          // Notice section
                                          _buildNoticeSection(textTheme),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Confirm button
                              _buildConfirmButton(context, colors, textTheme),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppColorsTheme colors,
    TextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: const BoxDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: colors.secondaryText,
              size: 24,
            ),
            onPressed: () => context.pop(),
          ),
          Text(
            '確認報名',
            style: textTheme.titleMedium?.copyWith(
              fontFamily: GoogleFonts.notoSansTc().fontFamily,
            ),
          ),
          const SizedBox(width: 64, height: 64),
        ],
      ),
    );
  }

  Widget _buildTitleRow(
    AppColorsTheme colors,
    TextTheme textTheme,
    HomeState state,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'English Games',
            style: textTheme.titleLarge?.copyWith(
              fontFamily: GoogleFonts.notoSansTc().fontFamily,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              ' ( ${state.selectedCityName} )',
              style: textTheme.labelMedium?.copyWith(
                fontFamily: GoogleFonts.notoSansTc().fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitleRow(
    BuildContext context,
    AppColorsTheme colors,
    TextTheme textTheme,
    HomeState state,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '和其他書呆子一起',
            style: textTheme.titleMedium?.copyWith(
              fontFamily: GoogleFonts.notoSansTc().fontFamily,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              onTap: () {
                context.push('${AppRoutes.checkout}?tabIndex=1');
              },
              child: Container(
                width: 96,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.tertiary,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 2, 0, 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/ticket_games_work2.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.confirmation_number,
                              color: colors.secondary,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          '${state.ticketBalance.gamesBalance}',
                          style: textTheme.labelLarge?.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                            color: colors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionRow(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '封印中文，全程英文遊戲',
              style: textTheme.titleMedium?.copyWith(
                fontFamily: GoogleFonts.notoSansTc().fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(AppColorsTheme colors, TextTheme textTheme) {
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final weekday = weekdays[widget.event.eventDate.weekday - 1];
    final dateString =
        '${widget.event.eventDate.month} 月 ${widget.event.eventDate.day} 日 ( $weekday )';
    final timeSlotText = _getTimeSlotText(widget.event.timeSlot.name);

    return Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Time row
            Row(
              children: [
                Text(
                  '時間：',
                  style: textTheme.labelMedium?.copyWith(
                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    dateString,
                    style: textTheme.labelLarge?.copyWith(
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    timeSlotText,
                    style: textTheme.labelLarge?.copyWith(
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    ),
                  ),
                ),
              ],
            ),
            // Location row
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '地點：',
                    style: textTheme.labelMedium?.copyWith(
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    ),
                  ),
                  Flexible(
                    child: Container(
                      decoration: const BoxDecoration(),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          _getLocationDisplay(widget.event.locationDetail),
                          style: textTheme.labelLarge?.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
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
    );
  }

  Widget _buildRulesCard(AppColorsTheme colors, TextTheme textTheme) {
    return Padding(
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '規則',
                    style: textTheme.labelLarge?.copyWith(
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    ),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    controller: _columnController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleRow(
                          textTheme,
                          '1. ',
                          '開始讀書前：設立 3 個目標，並將手機設為靜音，置於桌面中央',
                        ),
                        Divider(thickness: 2, color: colors.alternate),
                        _buildRuleRow(
                          textTheme,
                          '2. ',
                          '讀書期間：專注讀書，不干擾他人',
                        ),
                        Divider(thickness: 2, color: colors.alternate),
                        _buildRuleRow(
                          textTheme,
                          '3. ',
                          '中午一起吃飯時：互相檢查是否完成當初設的 3 個目標',
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

  Widget _buildRuleRow(TextTheme textTheme, String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: GoogleFonts.notoSansTc().fontFamily,
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(),
              child: Text(
                text,
                style: textTheme.bodyLarge?.copyWith(
                  fontFamily: GoogleFonts.notoSansTc().fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeSection(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '報名前小提醒',
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: GoogleFonts.notoSansTc().fontFamily,
                ),
              ),
            ],
          ),
          _buildNoticeItem(
            textTheme,
            '報名後由 Campus Nerds 進行分組，不保證一定成團；我們會依整體報名情形與過往出席狀況盡力安排。',
          ),
          _buildNoticeItem(
            textTheme,
            '活動開始 2 天前我們會透過 App 通知是否成團以及確切時間、地點 ( 如果有順利成團 ) 。',
          ),
          _buildNoticeItem(
            textTheme,
            '若臨時有事，活動開始 3 天前 23:59 前，可在 App 自行取消報名，不會扣除票券。',
          ),
          _buildNoticeItem(
            textTheme,
            '我們會優先安排學生價位友善的圖書館／咖啡廳，以不造成壓力的價位為主。',
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(TextTheme textTheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '‧',
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: GoogleFonts.notoSansTc().fontFamily,
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(),
              child: Text(
                text,
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: GoogleFonts.notoSansTc().fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(
    BuildContext context,
    AppColorsTheme colors,
    TextTheme textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () async {
            // Scroll to bottom first
            await _listViewController.animateTo(
              _listViewController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 666),
              curve: Curves.ease,
            );
            await Future.delayed(const Duration(milliseconds: 500));
            // Show confirmation dialog
            if (context.mounted) {
              _showConfirmDialog(context, colors, textTheme);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.secondary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            '確認報名',
            style: textTheme.labelLarge?.copyWith(
              fontSize: 18,
              color: Colors.white,
              fontFamily: GoogleFonts.notoSansTc().fontFamily,
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    AppColorsTheme colors,
    TextTheme textTheme,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '確認報名',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '報名後將使用 1 張英文遊戲票券。',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.secondaryText,
                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.secondaryText,
                          side: BorderSide(color: colors.tertiary, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '取消',
                          style: textTheme.labelLarge?.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          // TODO: Call booking API
                          context.pop(true); // Return success
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.secondary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '確認',
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTimeSlotText(String timeSlot) {
    switch (timeSlot) {
      case 'morning':
        return '早上';
      case 'afternoon':
        return '下午';
      case 'evening':
        return '晚上';
      default:
        return '早上';
    }
  }

  String _getLocationDisplay(String locationDetail) {
    final locationMap = {
      'ntu_main_library_reading_area': '國立臺灣大學總圖書館 閱覽區',
      'nycu_haoran_library_reading_area': '國立陽明交通大學浩然圖書館 閱覽區',
      'nycu_yangming_campus_library_reading_area': '國立陽明交通大學陽明校區圖書館 閱覽區',
      'nthu_main_library_reading_area': '國立清華大學總圖書館 閱覽區',
      'ncku_main_library_reading_area': '國立成功大學總圖書館 閱覽區',
      'nccu_daxian_library_reading_area': '國立政治大學達賢圖書館 閱覽區',
      'ncu_main_library_reading_area': '國立中央大學總圖書館 閱覽區',
      'nsysu_library_reading_area': '國立中山大學圖書館 閱覽區',
      'nchu_main_library_reading_area': '國立中興大學總圖書館 閱覽區',
      'ccu_library_reading_area': '國立中正大學圖書館 閱覽區',
      'ntnu_main_library_reading_area': '國立臺灣師範大學總圖書館 閱覽區',
      'ntpu_library_reading_area': '國立臺北大學圖書館 閱覽區',
      'ntust_library_reading_area': '國立臺灣科技大學圖書館 閱覽區',
      'ntut_library_reading_area': '國立臺北科技大學圖書館 閱覽區',
      'library_or_cafe': '圖書館/ 咖啡廳',
      'boardgame_or_escape_room': '桌遊店/ 密室逃脫',
    };
    return locationMap[locationDetail] ?? locationDetail;
  }
}
