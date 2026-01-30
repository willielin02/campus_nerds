import '/auth/supabase_auth/auth_util.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/components/city_selector_bottom_sheet_study_widget.dart';
import '/event_card/event_card/event_card_widget.dart';
import '/event_card/event_card_empty/event_card_empty_widget.dart';
import '/event_card/event_card_loading/event_card_loading_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/popout_dialog/alert_dialog/alert_dialog_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'home_widget.dart' show HomeWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class HomeModel extends FlutterFlowModel<HomeWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in Home widget.
  List<UserTicketBalancesVRow>? queryBalances;
  // Stores action output result for [Backend Call - Query Rows] action in Home widget.
  List<EventsRow>? queryEventsForTaoyuanStudy0;
  // Stores action output result for [Backend Call - Query Rows] action in Home widget.
  List<EventsRow>? queryEventsForHsinchuStudy0;
  // Stores action output result for [Backend Call - Query Rows] action in Home widget.
  List<EventsRow>? queryEventsForChiayiStudy0;
  // Stores action output result for [Backend Call - Query Rows] action in Home widget.
  List<EventsRow>? queryEventsForKaohsiungStudy0;
  // Stores action output result for [Backend Call - Query Rows] action in Home widget.
  List<EventsRow>? queryEventsForTainanStudy0;
  // Stores action output result for [Backend Call - Query Rows] action in Home widget.
  List<EventsRow>? queryEventsForTaichungStudy0;
  // Stores action output result for [Backend Call - Query Rows] action in Home widget.
  List<EventsRow>? queryEventsForTaipeiStudy0;
  // Stores action output result for [Backend Call - Query Rows] action in Home widget.
  List<EventsRow>? queryEventsForTaoyuanGames0;
  // Stores action output result for [Backend Call - Query Rows] action in Home widget.
  List<EventsRow>? queryEventsForHsinchuGames0;
  // Stores action output result for [Backend Call - Query Rows] action in Home widget.
  List<EventsRow>? queryEventsForChiayiGames0;
  // Stores action output result for [Backend Call - Query Rows] action in Home widget.
  List<EventsRow>? queryEventsForKaohsiungGames0;
  // Stores action output result for [Backend Call - Query Rows] action in Home widget.
  List<EventsRow>? queryEventsForTainanGames0;
  // Stores action output result for [Backend Call - Query Rows] action in Home widget.
  List<EventsRow>? queryEventsForTaichungGames0;
  // Stores action output result for [Backend Call - Query Rows] action in Home widget.
  List<EventsRow>? queryEventsForTaipeiGames0;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  // Stores action output result for [Backend Call - Query Rows] action in Container widget.
  List<EventsRow>? queryEventsForTaoyuanStudy;
  // Stores action output result for [Backend Call - Query Rows] action in Container widget.
  List<EventsRow>? queryEventsForHsinchuStudy;
  // Stores action output result for [Backend Call - Query Rows] action in Container widget.
  List<EventsRow>? queryEventsForChiayiStudy;
  // Stores action output result for [Backend Call - Query Rows] action in Container widget.
  List<EventsRow>? queryEventsForKaohsiungStudy;
  // Stores action output result for [Backend Call - Query Rows] action in Container widget.
  List<EventsRow>? queryEventsForTainanStudy;
  // Stores action output result for [Backend Call - Query Rows] action in Container widget.
  List<EventsRow>? queryEventsForTaichungStudy;
  // Stores action output result for [Backend Call - Query Rows] action in Container widget.
  List<EventsRow>? queryEventsForTaipeiStudy;
  // Stores action output result for [Backend Call - Query Rows] action in Container widget.
  List<EventsRow>? queryEventsForTaoyuanGames;
  // Stores action output result for [Backend Call - Query Rows] action in Container widget.
  List<EventsRow>? queryEventsForHsinchuGames;
  // Stores action output result for [Backend Call - Query Rows] action in Container widget.
  List<EventsRow>? queryEventsForChiayiGames;
  // Stores action output result for [Backend Call - Query Rows] action in Container widget.
  List<EventsRow>? queryEventsForKaohsiungGames;
  // Stores action output result for [Backend Call - Query Rows] action in Container widget.
  List<EventsRow>? queryEventsForTainanGames;
  // Stores action output result for [Backend Call - Query Rows] action in Container widget.
  List<EventsRow>? queryEventsForTaichungGames;
  // Stores action output result for [Backend Call - Query Rows] action in Container widget.
  List<EventsRow>? queryEventsForTaipeiGames;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tabBarController?.dispose();
  }
}
