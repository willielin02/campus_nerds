import '/auth/supabase_auth/auth_util.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/popout_dialog/confirm_dialog_create_booking_games/confirm_dialog_create_booking_games_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'games_booking_confirmation_widget.dart'
    show GamesBookingConfirmationWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class GamesBookingConfirmationModel
    extends FlutterFlowModel<GamesBookingConfirmationWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for ListView widget.
  ScrollController? listViewController;
  // State field(s) for Column widget.
  ScrollController? columnController;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<UserProfileVRow>? loggedInUser;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<UserTicketBalancesVRow>? userBalanceGames;

  @override
  void initState(BuildContext context) {
    listViewController = ScrollController();
    columnController = ScrollController();
  }

  @override
  void dispose() {
    listViewController?.dispose();
    columnController?.dispose();
  }
}
