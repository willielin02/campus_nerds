import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/my_event_card/my_event_card/my_event_card_widget.dart';
import '/my_event_card/my_event_card_empty_history/my_event_card_empty_history_widget.dart';
import '/my_event_card/my_event_card_empty_upcoming/my_event_card_empty_upcoming_widget.dart';
import '/my_event_card/my_event_card_loading/my_event_card_loading_widget.dart';
import 'dart:ui';
import 'my_events_widget.dart' show MyEventsWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MyEventsModel extends FlutterFlowModel<MyEventsWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tabBarController?.dispose();
  }
}
