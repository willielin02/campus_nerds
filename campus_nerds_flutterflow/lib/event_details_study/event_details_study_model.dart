import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/components/rules_dialog_study_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/popout_dialog/confirm_dialog_cancel_booking_study/confirm_dialog_cancel_booking_study_widget.dart';
import '/popout_dialog/edit_dialog_goal1/edit_dialog_goal1_widget.dart';
import '/popout_dialog/edit_dialog_goal2/edit_dialog_goal2_widget.dart';
import '/popout_dialog/edit_dialog_goal3/edit_dialog_goal3_widget.dart';
import 'dart:ui';
import 'event_details_study_widget.dart' show EventDetailsStudyWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class EventDetailsStudyModel extends FlutterFlowModel<EventDetailsStudyWidget> {
  ///  Local state fields for this page.

  List<dynamic> groupFocusedPlans = [];
  void addToGroupFocusedPlans(dynamic item) => groupFocusedPlans.add(item);
  void removeFromGroupFocusedPlans(dynamic item) =>
      groupFocusedPlans.remove(item);
  void removeAtIndexFromGroupFocusedPlans(int index) =>
      groupFocusedPlans.removeAt(index);
  void insertAtIndexInGroupFocusedPlans(int index, dynamic item) =>
      groupFocusedPlans.insert(index, item);
  void updateGroupFocusedPlansAtIndex(int index, Function(dynamic) updateFn) =>
      groupFocusedPlans[index] = updateFn(groupFocusedPlans[index]);

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (rpcGetGroupFocusedStudyPlans)] action in EventDetailsStudy widget.
  ApiCallResponse? rpcResultGetGroupFocusedStudyPlans;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tabBarController?.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
