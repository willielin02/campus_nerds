import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/app_clock.dart';
import '../../../../domain/entities/booking.dart';
import '../../../../domain/entities/event.dart';
import '../../chat/bloc/bloc.dart' show ChatBloc, ChatDispose, ChatInitialize, ChatMarkAsRead, ChatState, ChatStatus;
import '../../chat/widgets/chat_tab.dart';
import '../../home/bloc/bloc.dart' show HomeBloc, HomeRefresh;
import '../bloc/bloc.dart';
import '../widgets/cancel_booking_dialog.dart';
import '../widgets/edit_goal_dialog.dart';
import '../widgets/rules_dialog_games.dart';
import '../widgets/rules_dialog_study.dart';
import '../widgets/english_content_card.dart';
import '../widgets/study_plan_card.dart';

/// Event details page for both focused study and english games
/// Matches FlutterFlow design exactly
class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage({
    super.key,
    required this.bookingId,
    required this.isFocusedStudy,
    this.initialTab = 0,
  });

  final String bookingId;
  final bool isFocusedStudy;
  final int initialTab;

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _chatUnreadCount = 0;
  bool _chatInitialized = false;
  int _lastKnownMessageCount = 0;
  /// 本頁初始化 ChatBloc 時使用的 groupId，用於 dispose 時判斷是否仍為 owner
  String? _managedGroupId;
  /// 快取 ChatBloc 參考，避免 dispose 時 context 已 deactivated
  ChatBloc? _chatBloc;
  /// 等待 chatOpenAt 到達的一次性 Timer（用於自動切換聊天室 UI）
  Timer? _chatOpenTimer;

  @override
  void initState() {
    super.initState();
    context.read<MyEventsBloc>().add(MyEventsLoadDetails(widget.bookingId));
  }

  void _initTabController(MyEvent event) {
    if (_tabController == null) {
      _tabController = TabController(
        length: 2,
        initialIndex: widget.initialTab.clamp(0, 1),
        vsync: this,
      );
      _tabController!.addListener(_onTabChanged);
    }

    // 聊天室初始化（chat 可能在頁面建立後才開啟，所以不能放在 _tabController guard 裡）
    if (_managedGroupId == null && event.groupId != null && event.isChatOpen) {
      _chatOpenTimer?.cancel();
      _chatOpenTimer = null;
      _managedGroupId = event.groupId;
      _chatBloc = context.read<ChatBloc>();
      _chatBloc!.add(ChatInitialize(event.groupId!));
      // 進入聊天室 → 主動標記該群組的 chat_open 通知為已讀
      // 防止 checkUnreadNotifications() 重複彈出已知的聊天室開啟通知
      NotificationService.instance.markGroupNotificationsAsRead(event.groupId!);
      // 若當前已在聊天室 tab，立即設定 activeGroupId 抑制推播
      if (_tabController?.index == 1) {
        NotificationService.instance.setActiveGroupId(event.groupId);
      }
    }

    // 聊天室尚未開啟但有 chatOpenAt → 排程一次性 Timer，到時間自動重新載入
    if (_chatOpenTimer == null &&
        _managedGroupId == null &&
        event.groupId != null &&
        event.chatOpenAt != null &&
        !event.isChatOpen) {
      final delay = event.chatOpenAt!.difference(AppClock.now()) +
          const Duration(seconds: 1);
      if (delay > Duration.zero) {
        _chatOpenTimer = Timer(delay, () {
          if (mounted && _managedGroupId == null) {
            context
                .read<MyEventsBloc>()
                .add(MyEventsLoadDetails(widget.bookingId));
          }
        });
      }
    }

    // ChatBloc 初始化前都允許從 event 更新未讀數（確保用最新的伺服器資料）
    if (!_chatInitialized) {
      _chatUnreadCount =
          widget.initialTab.clamp(0, 1) == 1 ? 0 : event.unreadMessageCount;
    }
  }

  void _onTabChanged() {
    if (_tabController?.index == 1) {
      if (_chatUnreadCount > 0) {
        setState(() {
          _chatUnreadCount = 0;
        });
      }
      // 切換到聊天室 tab 時標記已讀 + 設定 activeGroupId 抑制推播
      _chatBloc?.add(const ChatMarkAsRead());
      if (_managedGroupId != null) {
        NotificationService.instance.setActiveGroupId(_managedGroupId);
      }
    } else {
      // 離開聊天室 tab → 清除 activeGroupId，恢復推播
      NotificationService.instance.setActiveGroupId(null);
    }
  }

  @override
  void dispose() {
    _chatOpenTimer?.cancel();
    // 離開頁面時清除 activeGroupId，恢復推播
    NotificationService.instance.setActiveGroupId(null);
    // 只在 ChatBloc 仍由本頁管理時才清理，避免頁面切換時
    // 舊頁的 dispose 覆蓋新頁已初始化的 ChatBloc
    if (_chatBloc != null &&
        _managedGroupId != null &&
        _chatBloc!.state.groupId == _managedGroupId) {
      if (_tabController?.index == 1) {
        _chatBloc!.add(const ChatMarkAsRead());
      }
      _chatBloc!.add(const ChatDispose());
    }
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  void _showRulesDialog() {
    if (widget.isFocusedStudy) {
      RulesDialogStudy.show(context);
    } else {
      RulesDialogGames.show(context);
    }
  }

  void _handleCancelBooking(MyEvent event) {
    CancelBookingDialog.show(
      context,
      event: event,
      onConfirm: () {
        context.read<MyEventsBloc>().add(MyEventsCancelBooking(event.bookingId));
      },
    );
  }

  Future<void> _openGoogleMaps(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Fallback: try platform default mode (handles emulator crashes)
      try {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        // Silently fail if URL cannot be launched
      }
    }
  }

  void _handleGoalTap(
    MyEvent event,
    int slot,
    String? planId,
    String? content,
    bool isDone,
  ) {
    if (planId == null) return;

    EditGoalDialog.show(
      context,
      slot: slot,
      planId: planId,
      initialContent: content,
      initialIsDone: isDone,
      canEditContent: event.canEditGoalContent,
      canEditCompletion: event.canCheckGoal,
      onSave: (newContent, newIsDone) {
        context.read<MyEventsBloc>().add(
              MyEventsUpdateStudyPlan(
                planId: planId,
                content: newContent,
                isDone: newIsDone,
                groupId: event.groupId,
                bookingId: event.groupId == null ? event.bookingId : null,
              ),
            );
      },
    );
  }

  String _getCityName(String? cityId) {
    switch (cityId) {
      case '2e7c8bc4-232b-4423-9526-002fc27ed1d3':
        return '臺北';
      case '2e3dfbb9-8c2a-4098-8c09-9213f55de6fc':
        return '桃園';
      case '3d221404-0590-4cca-b553-1ab890f31267':
        return '新竹';
      case '3bc5798e-933e-4d46-a819-05f3fa060077':
        return '臺中';
      case 'c3e02d08-970d-4fcf-82c5-69a86f69e872':
        return '嘉義';
      case '33a466b3-6d0b-4cd6-b197-9eaba2101853':
        return '臺南';
      case '72cbb430-f015-41b1-970a-86297bf3c904':
        return '高雄';
      default:
        return '';
    }
  }

  bool _showFeedbackButton(MyEvent event) {
    return event.feedbackSentAt != null;
  }

  /// Status text based on event lifecycle (matches FlutterFlow exactly)
  /// scheduled/notified → '已報名', completed → '已結束', else → ''
  String _getStatusText(MyEvent event) {
    if (event.eventStatus == EventStatus.scheduled ||
        event.eventStatus == EventStatus.notified) {
      return '已報名';
    } else if (event.eventStatus == EventStatus.completed) {
      return '已結束';
    }
    return '';
  }

  /// Format date as "M 月 d 日 ( 六 )" to match FlutterFlow
  String _formatDateDisplay(MyEvent event) {
    final d = event.eventDate;
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final weekday = weekdays[d.weekday - 1];
    return '${d.month} 月 ${d.day} 日 ( $weekday )';
  }

  /// Format time display: time slot for scheduled, HH:mm for notified/completed
  String _formatTimeDisplay(MyEvent event) {
    if (event.groupStartAt != null) {
      final t = AppClock.toTaipei(event.groupStartAt!);
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return event.timeSlot.displayName;
  }

  /// Map locationDetail enum to Chinese venue name (FlutterFlow mapping)
  String _getLocationDisplay(MyEvent event) {
    // When notified/completed, use venueName from DB
    if (event.venueName != null && event.venueName!.isNotEmpty) {
      return event.venueName!;
    }
    // Otherwise map locationDetail enum to display name
    switch (event.locationDetail) {
      case 'ntu_main_library_reading_area':
        return '國立臺灣大學總圖書館 閱覽區';
      case 'nycu_haoran_library_reading_area':
        return '國立陽明交通大學浩然圖書館 閱覽區';
      case 'nthu_main_library_reading_area':
        return '國立清華大學總圖書館 閱覽區';
      case 'ncku_main_library_reading_area':
        return '國立成功大學總圖書館 閱覽區';
      case 'nccu_daxian_library_reading_area':
        return '國立政治大學達賢圖書館 閱覽區';
      case 'ncu_main_library_reading_area':
        return '國立中央大學總圖書館 閱覽區';
      case 'nsysu_library_reading_area':
        return '國立中山大學圖書館 閱覽區';
      case 'nchu_main_library_reading_area':
        return '國立中興大學總圖書館 閱覽區';
      case 'ccu_library_reading_area':
        return '國立中正大學圖書館 閱覽區';
      case 'ntnu_main_library_reading_area':
        return '國立臺灣師範大學總圖書館 閱覽區';
      case 'ntpu_library_reading_area':
        return '國立臺北大學圖書館 閱覽區';
      case 'ntust_library_reading_area':
        return '國立臺灣科技大學圖書館 閱覽區';
      case 'ntut_library_reading_area':
        return '國立臺北科技大學圖書館 閱覽區';
      case 'library_or_cafe':
        return '圖書館/ 咖啡廳';
      case 'boardgame_or_escape_room':
        return '桌遊店/ 密室逃脫';
      case 'boardgame':
        return '桌遊店';
      default:
        return event.locationDetail;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<ChatBloc, ChatState>(
      listener: (context, chatState) {
        // 等待初始載入完成，設定基準值
        if (chatState.status == ChatStatus.loaded && !_chatInitialized) {
          _chatInitialized = true;
          _lastKnownMessageCount = chatState.messages.length;
          // 如果初始 tab 就是聊天室，標記已讀
          if (_tabController?.index == 1) {
            context.read<ChatBloc>().add(const ChatMarkAsRead());
          }
          return;
        }
        if (!_chatInitialized) return;

        final currentCount = chatState.messages.length;
        if (currentCount > _lastKnownMessageCount) {
          final newCount = currentCount - _lastKnownMessageCount;
          if (_tabController?.index != 1) {
            // 不在聊天室 tab → 增加未讀計數
            setState(() {
              _chatUnreadCount += newCount;
            });
          } else {
            // 在聊天室 tab → 標記已讀
            context.read<ChatBloc>().add(const ChatMarkAsRead());
          }
        }
        _lastKnownMessageCount = currentCount;
      },
      child: BlocConsumer<MyEventsBloc, MyEventsState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: colors.secondaryText,
            ),
          );
          context.read<MyEventsBloc>().add(const MyEventsClearSuccess());
          if (state.successMessage == '已取消報名') {
            context.read<HomeBloc>().add(const HomeRefresh());
            context.pop();
          }
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colors.error,
            ),
          );
          context.read<MyEventsBloc>().add(const MyEventsClearError());
        }
      },
      builder: (context, state) {
        // 只在 bookingId 匹配時使用 event，避免殘留上次瀏覽的 stale 資料
        final rawEvent = state.selectedEvent;
        final event = rawEvent != null && rawEvent.bookingId == widget.bookingId
            ? rawEvent
            : null;

        if (event != null) {
          _initTabController(event);
        }

        // Read viewInsets BEFORE Scaffold (Scaffold may consume it)
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: colors.primaryBackground,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ColoredBox(
                    color: colors.primaryBackground,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned(
                          top: -bottomInset,
                          left: 0,
                          right: 0,
                          height: constraints.maxHeight,
                          child: Column(
                            children: [
                              // Header row: back button on left, 64px spacer on right
                              SizedBox(
                                width: double.infinity,
                                height: 64,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      iconSize: 64,
                                      icon: Icon(
                                        Icons.arrow_back_ios_rounded,
                                        color: colors.secondaryText,
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        if (context.canPop()) {
                                          context.pop();
                                        } else {
                                          context.go(AppRoutes.myEvents);
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 64, height: 64),
                                  ],
                                ),
                              ),
                              // Main content
                              Expanded(
                                child: event == null
                                    ? Center(
                                        child: CircularProgressIndicator(
                                          color: colors.primary,
                                        ),
                                      )
                                    : _buildContent(colors, event, state),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    ),
    );
  }

  Widget _buildContent(
    AppColorsTheme colors,
    MyEvent event,
    MyEventsState state,
  ) {
    final textTheme = context.textTheme;
    final cityName = _getCityName(event.cityId);
    final statusText = _getStatusText(event);
    final showTabs = _tabController != null;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        decoration: const BoxDecoration(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Event info card
              Container(
                width: 579,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row: "Focused Study" / "English Games" + city + status badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.isFocusedStudy ? 'Focused Study' : 'English Games',
                                style: textTheme.titleLarge?.copyWith(
                                  fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                ),
                              ),
                              Text(
                                '  ( $cityName ) ',
                                style: textTheme.labelMedium?.copyWith(
                                  fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                ),
                              ),
                            ],
                          ),
                          // Status badge
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colors.tertiaryText,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  statusText,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                    color: colors.secondaryBackground,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Time row
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Text(
                                    '時間： ',
                                    style: textTheme.labelMedium?.copyWith(
                                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                    ),
                                  ),
                                  Text(
                                    _formatDateDisplay(event),
                                    style: textTheme.labelLarge?.copyWith(
                                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                    ),
                                  ),
                                  Text(
                                    '  ${_formatTimeDisplay(event)}',
                                    style: textTheme.labelLarge?.copyWith(
                                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(right: 16),
                              child: SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),

                      // Location row
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '地點： ',
                              style: textTheme.labelMedium?.copyWith(
                                fontFamily: GoogleFonts.notoSansTc().fontFamily,
                              ),
                            ),
                            Flexible(
                              child: InkWell(
                                splashColor: Colors.transparent,
                                onTap: event.venueGoogleMapUrl != null
                                    ? () => _openGoogleMaps(event.venueGoogleMapUrl)
                                    : null,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _getLocationDisplay(event),
                                            style: textTheme.labelMedium?.copyWith(
                                              fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                              decoration: event.venueGoogleMapUrl != null
                                                  ? TextDecoration.underline
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        if (event.venueGoogleMapUrl != null)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4),
                                            child: Icon(
                                              Icons.open_in_new_rounded,
                                              size: 14,
                                              color: colors.secondaryText,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (event.venueAddress != null &&
                                        event.venueAddress!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          ' ( ${event.venueAddress} ) ',
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Buttons row: "規則" and "取消報名"
                      Padding(
                        padding: const EdgeInsets.only(top: 18, bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Rules button
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: SizedBox(
                                width: 144,
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: _showRulesDialog,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: colors.secondaryBackground,
                                    foregroundColor: colors.secondaryText,
                                    side: BorderSide(color: colors.tertiary, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    '規則',
                                    style: textTheme.labelLarge?.copyWith(
                                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                      color: colors.secondaryText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Cancel booking / Feedback button
                            // scheduled phase → 取消報名; notified/completed → 填寫問券
                            // Pressable: bg = tertiaryText; Not pressable: bg = tertiary
                            // Text: secondaryBackground, no shadow
                            if (_showFeedbackButton(event))
                              SizedBox(
                                width: 144,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: event.isFeedbackOpen
                                      ? () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('回饋功能即將推出'),
                                              backgroundColor: colors.tertiary,
                                            ),
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.tertiaryText,
                                    foregroundColor: colors.secondaryBackground,
                                    disabledBackgroundColor: colors.tertiary,
                                    disabledForegroundColor: colors.secondaryBackground,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    '填寫問券',
                                    style: textTheme.labelLarge?.copyWith(
                                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                      color: colors.secondaryBackground,
                                    ),
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                width: 144,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: event.canCancel
                                      ? () => _handleCancelBooking(event)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.tertiaryText,
                                    foregroundColor: colors.secondaryBackground,
                                    disabledBackgroundColor: colors.tertiary,
                                    disabledForegroundColor: colors.secondaryBackground,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    '取消報名',
                                    style: textTheme.labelLarge?.copyWith(
                                      fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                      color: colors.secondaryBackground,
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
              ),

              // Expanded section with TabBar
              if (showTabs)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.primaryBackground,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              // TabBar
                              Align(
                                alignment: Alignment.center,
                                child: TabBar(
                                  controller: _tabController,
                                  labelColor: colors.primaryText,
                                  unselectedLabelColor: colors.tertiary,
                                  labelStyle: textTheme.titleMedium?.copyWith(
                                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                  ),
                                  unselectedLabelStyle: textTheme.labelLarge?.copyWith(
                                    fontFamily: GoogleFonts.notoSansTc().fontFamily,
                                  ),
                                  indicatorColor: colors.secondaryText,
                                  dividerColor: Colors.transparent,
                                  tabs: [
                                    Tab(text: widget.isFocusedStudy ? '待辦事項' : '學習內容'),
                                    Tab(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('聊天室'),
                                          if (_chatUnreadCount > 0) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 1,
                                              ),
                                              decoration: BoxDecoration(
                                                color: colors.tertiaryText,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '$_chatUnreadCount',
                                                style: textTheme.bodySmall?.copyWith(
                                                  color: colors.secondaryBackground,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // TabBarView
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    // Goals / English content tab
                                    widget.isFocusedStudy
                                        ? _buildGoalsTab(colors, event, state)
                                        : _buildEnglishContentTab(colors, event, state),
                                    // Chat tab
                                    _buildChatTab(event),
                                  ],
                                ),
                              ),
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
    );
  }

  Widget _buildGoalsTab(
    AppColorsTheme colors,
    MyEvent event,
    MyEventsState state,
  ) {
    final textTheme = context.textTheme;

    if (state.isLoadingStudyPlans) {
      return Center(
        child: CircularProgressIndicator(color: colors.primary),
      );
    }

    final studyPlans = state.studyPlans;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    if (studyPlans.isEmpty) {
      return ShaderMask(
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
          children: [
            Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '尚無目標',
                            style: textTheme.labelLarge?.copyWith(
                              fontFamily: GoogleFonts.notoSansTc().fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 16),
                      child: Row(
                        children: [
                          Text(
                            '等待小組成員設定目標',
                            style: textTheme.bodyLarge?.copyWith(
                              fontFamily: GoogleFonts.notoSansTc().fontFamily,
                              color: colors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isPreGrouping = event.groupId == null;

    return ShaderMask(
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
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 24, 8, 24),
        itemCount: studyPlans.length + (isPreGrouping ? 1 : 0),
        itemBuilder: (context, index) {
          // Hint text below the cards in pre-grouping phase
          if (index == studyPlans.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                '請先寫下活動期間你希望完成的 3 個待辦事項，分組後你將看到其他夥伴的待辦事項。',
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: fontFamily,
                  color: colors.tertiaryText,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          final plan = studyPlans[index];
          return Padding(
            padding: EdgeInsets.only(top: index > 0 ? 16 : 0),
            child: StudyPlanCard(
              plan: plan,
              canEditGoalContent: event.canEditGoalContent,
              canCheckGoal: event.canCheckGoal,
              onGoalTap: (slot, planId, content, isDone) =>
                  _handleGoalTap(event, slot, planId, content, isDone),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnglishContentTab(
    AppColorsTheme colors,
    MyEvent event,
    MyEventsState state,
  ) {
    final textTheme = context.textTheme;

    if (state.isLoadingEnglishAssignments) {
      return Center(
        child: CircularProgressIndicator(color: colors.primary),
      );
    }

    final assignments = state.englishAssignments;
    final fontFamily = GoogleFonts.notoSansTc().fontFamily;

    if (assignments.isEmpty) {
      return ShaderMask(
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
          children: [
            Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '尚未分配學習內容',
                            style: textTheme.labelLarge?.copyWith(
                              fontFamily: GoogleFonts.notoSansTc().fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 16),
                      child: Row(
                        children: [
                          Text(
                            '等待系統分配學習內容',
                            style: textTheme.bodyLarge?.copyWith(
                              fontFamily: GoogleFonts.notoSansTc().fontFamily,
                              color: colors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isPreGrouping = event.groupId == null;

    return ShaderMask(
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
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 24, 8, 24),
        itemCount: assignments.length + (isPreGrouping ? 1 : 0),
        itemBuilder: (context, index) {
          // Hint text below the cards in pre-grouping phase
          if (index == assignments.length) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                '分組後你將看到其他組員的學習內容。',
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: fontFamily,
                  color: colors.tertiaryText,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          final assignment = assignments[index];
          return Padding(
            padding: EdgeInsets.only(top: index > 0 ? 16 : 0),
            child: EnglishContentCard(
              assignment: assignment,
              canViewContent: event.canViewEnglishContent,
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatTab(MyEvent event) {
    return ChatTab(event: event);
  }
}
