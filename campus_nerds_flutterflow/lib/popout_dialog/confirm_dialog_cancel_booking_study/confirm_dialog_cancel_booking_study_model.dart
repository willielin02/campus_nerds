import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/popout_dialog/alert_dialog/alert_dialog_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'confirm_dialog_cancel_booking_study_widget.dart'
    show ConfirmDialogCancelBookingStudyWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class ConfirmDialogCancelBookingStudyModel
    extends FlutterFlowModel<ConfirmDialogCancelBookingStudyWidget> {
  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - API (rpcCancelBooking)] action in Button widget.
  ApiCallResponse? rpcCancelBooking;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
