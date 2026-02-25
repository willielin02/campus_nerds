import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../domain/entities/event.dart';
import '../../../../domain/repositories/my_events_repository.dart';
import '../../../common/widgets/app_alert_dialog.dart';
import '../../../common/widgets/app_confirm_dialog.dart';
import '../../my_events/bloc/bloc.dart' show MyEventsBloc, MyEventsRefresh;
import '../bloc/bloc.dart';

/// Booking confirmation page for Focused Study events
///
/// Shows event details, rules, and confirms the booking.
/// UI matches FlutterFlow design exactly.
class StudyBookingConfirmationPage extends StatefulWidget {
  const StudyBookingConfirmationPage({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  State<StudyBookingConfirmationPage> createState() =>
      _StudyBookingConfirmationPageState();
}

class _StudyBookingConfirmationPageState
    extends State<StudyBookingConfirmationPage> {
  final ScrollController _listViewController = ScrollController();
  final ScrollController _columnController = ScrollController();
  bool _isConfirming = false;

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
              child: Column(
                children: [
                  // Header row
                  _buildHeader(context, colors, textTheme),
                  // Content (scrollable area)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Title row: "Focused Study ( city )"
                          _buildTitleRow(colors, textTheme, state),
                          // Subtitle row with ticket balance
                          _buildSubtitleRow(context, colors, textTheme, state),
                          // Description text right-aligned
                          _buildDescriptionRow(textTheme),
                          // ListView with event card, rules, and notice
                          Expanded(
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
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Confirm button (fixed at bottom, outside scrollable area)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildConfirmButton(context, colors, textTheme, state),
                  ),
                ],
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
          SizedBox(
            width: 64,
            height: 64,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: colors.secondaryText,
                size: 24,
              ),
              onPressed: () => context.pop(),
            ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Focused Study',
                style: textTheme.titleMedium?.copyWith(
                  fontFamily: GoogleFonts.notoSansTc().fontFamily,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  ' ( ${state.selectedCityName} )',
                  style: textTheme.bodyLarge?.copyWith(
                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
                  ),
                ),
              ),
            ],
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
      padding: const EdgeInsets.fromLTRB(12, 16, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '和其他書呆子一起',
            style: textTheme.labelLarge?.copyWith(
              fontFamily: GoogleFonts.notoSansTc().fontFamily,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                context.push('${AppRoutes.checkout}?tabIndex=0');
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
                            'assets/images/ticket_study_work.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.confirmation_number,
                              color: colors.primary,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          '${state.ticketBalance.studyBalance}',
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.fromLTRB(0, 0, 12, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '交出手機，全程專注學習',
              style: textTheme.labelLarge?.copyWith(
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
                  style: textTheme.bodyLarge?.copyWith(
                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    dateString,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    timeSlotText,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
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
                    style: textTheme.bodyLarge?.copyWith(
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
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.only(top: 16),
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
                    '活動流程',
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
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: SingleChildScrollView(
                    controller: _columnController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleRow(
                          textTheme,
                          '開始學習前：\n寫下 3 個待辦事項，並將手機設為靜音，置於桌面中央。',
                        ),
                        Divider(thickness: 2, color: colors.alternate),
                        _buildRuleRow(
                          textTheme,
                          '學習期間：\n專注學習，不干擾他人。',
                        ),
                        Divider(thickness: 2, color: colors.alternate),
                        _buildRuleRow(
                          textTheme,
                          '中午一起吃飯時：\n互相檢查是否完成開始前寫下的 3 個待辦事項。',
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

  Widget _buildRuleRow(TextTheme textTheme, String text) {
    final parts = text.split('\n');
    final title = parts[0];
    final body = parts.length > 1 ? parts.sublist(1).join('\n') : '';
    final titleStyle = textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontFamily: GoogleFonts.notoSansTc().fontFamily,
    );
    final bodyStyle = textTheme.bodyLarge?.copyWith(
      fontSize: 16.0,
      fontFamily: GoogleFonts.notoSansTc().fontFamily,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          if (body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(body, style: bodyStyle),
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
                style: textTheme.bodySmall?.copyWith(
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
            style: textTheme.bodySmall?.copyWith(
              fontFamily: GoogleFonts.notoSansTc().fontFamily,
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(),
              child: Text(
                text,
                style: textTheme.bodySmall?.copyWith(
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
    HomeState state,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
      child: SizedBox(
        width: 192,
        height: 64,
        child: ElevatedButton(
          onPressed: _isConfirming
              ? null
              : () async {
                  setState(() => _isConfirming = true);

                  // Scroll to bottom first
                  await _listViewController.animateTo(
                    _listViewController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 666),
                    curve: Curves.ease,
                  );
                  await Future.delayed(const Duration(milliseconds: 2222));

                  if (!context.mounted) return;
                  setState(() => _isConfirming = false);

                  // Check ticket balance
                  if (state.ticketBalance.studyBalance <= 0) {
                    // No tickets - navigate to checkout
                    context.push('${AppRoutes.checkout}?tabIndex=0');
                    return;
                  }

                  // Show confirmation dialog
                  final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
                  final wd =
                      weekdays[widget.event.eventDate.weekday - 1];
                  final dateStr =
                      '${widget.event.eventDate.month} 月 ${widget.event.eventDate.day} 日 ( $wd )';
                  final cityName =
                      state.selectedCityName;
                  final fontFamily =
                      GoogleFonts.notoSansTc().fontFamily;
                  final confirmed = await showAppConfirmDialog(
                    context: context,
                    title: '確定報名本場Focused Study嗎？',
                    messageWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '您將花費一張 Study 票券報名',
                          style: context.appTypography.bodyBig,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text.rich(
                            TextSpan(
                              style: context.appTypography.bodyBig,
                              children: [
                                TextSpan(text: '$dateStr Focused Study '),
                                TextSpan(
                                  text: '( $cityName )',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontFamily: fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true || !context.mounted) return;

                  // Show loading while calling API
                  setState(() => _isConfirming = true);

                  final result = await GetIt.I<MyEventsRepository>()
                      .createBooking(
                    eventId: widget.event.id,
                    category: EventCategory.focusedStudy,
                  );

                  if (!context.mounted) return;
                  setState(() => _isConfirming = false);

                  if (result.success) {
                    // Show success alert, then navigate to my events
                    await showAppAlertDialog(
                      context: context,
                      title: '報名成功！',
                      message:
                          '活動確切時間與地點將於活動日兩天前透過 App 通知，你可以在「我的活動」頁面查看最新資訊。',
                    );
                    if (!context.mounted) return;

                    // Refresh home (events + balance) and my events
                    context
                        .read<HomeBloc>()
                        .add(const HomeRefresh());
                    context
                        .read<MyEventsBloc>()
                        .add(const MyEventsRefresh());

                    // Check Facebook binding status before navigating
                    bool shouldPromptFb = false;
                    try {
                      final userId = SupabaseService.currentUserId;
                      if (userId != null) {
                        final row = await SupabaseService.client
                            .from('users')
                            .select('fb_user_id')
                            .eq('id', userId)
                            .limit(1)
                            .maybeSingle();
                        shouldPromptFb = row?['fb_user_id'] == null;
                      }
                    } catch (_) {
                      // Don't block navigation if FB check fails
                    }

                    if (!context.mounted) return;

                    // Capture root navigator (survives route changes)
                    final rootNav = Navigator.of(
                      context,
                      rootNavigator: true,
                    );

                    // Navigate to my events first
                    context.go(AppRoutes.myEvents);

                    // Show FB prompt on top of MyEvents page
                    if (shouldPromptFb) {
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        if (!rootNav.mounted) return;
                        // Block interaction with transparent barrier
                        showDialog<void>(
                          context: rootNav.context,
                          barrierDismissible: false,
                          barrierColor: Colors.transparent,
                          builder: (_) => const SizedBox.shrink(),
                        );
                        await Future.delayed(
                            const Duration(milliseconds: 666));
                        if (!rootNav.mounted) return;
                        // Remove barrier, then show real dialog
                        Navigator.of(rootNav.context,
                                rootNavigator: true)
                            .pop();
                        final wantBind = await showAppConfirmDialog(
                          context: rootNav.context,
                          title: '綁定 Facebook 以避免遇到熟人',
                          message:
                              '在綁定您的 Facebook 帳號後，系統分組時會自動避開你的 Facebook 好友，讓你在活動上認識更多新朋友。',
                          confirmText: '前往綁定',
                        );
                        if (wantBind == true && rootNav.mounted) {
                          GoRouter.of(rootNav.context)
                              .push(AppRoutes.facebookBinding);
                        }
                      });
                    }
                  } else {
                    // Show error alert, stay on current page
                    await showAppAlertDialog(
                      context: context,
                      title: '報名失敗',
                      message: result.errorMessage ?? '報名失敗，請稍後再試',
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.tertiary,
            foregroundColor: colors.primaryText,
            disabledBackgroundColor: colors.tertiary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isConfirming
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  '確認報名',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.primaryText,
                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
                  ),
                ),
        ),
      ),
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
      'boardgame': '桌遊店',
    };
    return locationMap[locationDetail] ?? '';
  }
}
