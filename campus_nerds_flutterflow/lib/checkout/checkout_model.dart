import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/popout_dialog/alert_dialog/alert_dialog_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'checkout_widget.dart' show CheckoutWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class CheckoutModel extends FlutterFlowModel<CheckoutWidget> {
  ///  Local state fields for this page.

  int selectedStudy = 2;

  int selectedGames = 2;

  List<ProductsRow> productsStudy = [];
  void addToProductsStudy(ProductsRow item) => productsStudy.add(item);
  void removeFromProductsStudy(ProductsRow item) => productsStudy.remove(item);
  void removeAtIndexFromProductsStudy(int index) =>
      productsStudy.removeAt(index);
  void insertAtIndexInProductsStudy(int index, ProductsRow item) =>
      productsStudy.insert(index, item);
  void updateProductsStudyAtIndex(int index, Function(ProductsRow) updateFn) =>
      productsStudy[index] = updateFn(productsStudy[index]);

  bool isLoading = true;

  List<ProductsRow> productsGames = [];
  void addToProductsGames(ProductsRow item) => productsGames.add(item);
  void removeFromProductsGames(ProductsRow item) => productsGames.remove(item);
  void removeAtIndexFromProductsGames(int index) =>
      productsGames.removeAt(index);
  void insertAtIndexInProductsGames(int index, ProductsRow item) =>
      productsGames.insert(index, item);
  void updateProductsGamesAtIndex(int index, Function(ProductsRow) updateFn) =>
      productsGames[index] = updateFn(productsGames[index]);

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in Checkout widget.
  List<ProductsRow>? queryPruductsStudy;
  // Stores action output result for [Backend Call - Query Rows] action in Checkout widget.
  List<ProductsRow>? queryPruductsGames;
  // Stores action output result for [Backend Call - Query Rows] action in Checkout widget.
  List<UserTicketBalancesVRow>? queryBalances;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  // Stores action output result for [Backend Call - API (EcpayCreateOrder)] action in Button widget.
  ApiCallResponse? apiEcpayCreateOrder;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tabBarController?.dispose();
  }
}
