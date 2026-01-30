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
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'home_model.dart';
export 'home_model.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  static String routeName = 'Home';
  static String routePath = '/home';

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> with TickerProviderStateMixin {
  late HomeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.queryBalances = await UserTicketBalancesVTable().queryRows(
        queryFn: (q) => q.eqOrNull(
          'user_id',
          currentUserUid,
        ),
      );
      FFAppState().studyBalance =
          _model.queryBalances!.firstOrNull!.studyBalance!;
      FFAppState().gamesBalance =
          _model.queryBalances!.firstOrNull!.gamesBalance!;
      safeSetState(() {});
      _model.queryEventsForTaoyuanStudy0 = await EventsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull(
              'city_id',
              '2e3dfbb9-8c2a-4098-8c09-9213f55de6fc',
            )
            .eqOrNull(
              'category',
              EventCategory.focused_study.name,
            )
            .ltOrNull(
              'signup_open_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            )
            .gtOrNull(
              'signup_deadline_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            ),
      );
      FFAppState().queryEventsForTaoyuanStudyCounts =
          _model.queryEventsForTaoyuanStudy0!.length;
      safeSetState(() {});
      _model.queryEventsForHsinchuStudy0 = await EventsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull(
              'city_id',
              '3d221404-0590-4cca-b553-1ab890f31267',
            )
            .eqOrNull(
              'category',
              EventCategory.focused_study.name,
            )
            .ltOrNull(
              'signup_open_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            )
            .gtOrNull(
              'signup_deadline_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            ),
      );
      FFAppState().queryEventsForHsinchuStudyCounts =
          _model.queryEventsForHsinchuStudy0!.length;
      safeSetState(() {});
      _model.queryEventsForChiayiStudy0 = await EventsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull(
              'city_id',
              'c3e02d08-970d-4fcf-82c5-69a86f69e872',
            )
            .eqOrNull(
              'category',
              EventCategory.focused_study.name,
            )
            .ltOrNull(
              'signup_open_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            )
            .gtOrNull(
              'signup_deadline_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            ),
      );
      FFAppState().queryEventsForChiayiStudyCounts =
          _model.queryEventsForChiayiStudy0!.length;
      safeSetState(() {});
      _model.queryEventsForKaohsiungStudy0 = await EventsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull(
              'city_id',
              '72cbb430-f015-41b1-970a-86297bf3c904',
            )
            .eqOrNull(
              'category',
              EventCategory.focused_study.name,
            )
            .ltOrNull(
              'signup_open_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            )
            .gtOrNull(
              'signup_deadline_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            ),
      );
      FFAppState().queryEventsForKaohsiungStudyCounts =
          _model.queryEventsForKaohsiungStudy0!.length;
      safeSetState(() {});
      _model.queryEventsForTainanStudy0 = await EventsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull(
              'city_id',
              '33a466b3-6d0b-4cd6-b197-9eaba2101853',
            )
            .eqOrNull(
              'category',
              EventCategory.focused_study.name,
            )
            .ltOrNull(
              'signup_open_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            )
            .gtOrNull(
              'signup_deadline_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            ),
      );
      FFAppState().queryEventsForTainanStudyCounts =
          _model.queryEventsForTainanStudy0!.length;
      safeSetState(() {});
      _model.queryEventsForTaichungStudy0 = await EventsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull(
              'city_id',
              '3bc5798e-933e-4d46-a819-05f3fa060077',
            )
            .eqOrNull(
              'category',
              EventCategory.focused_study.name,
            )
            .ltOrNull(
              'signup_open_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            )
            .gtOrNull(
              'signup_deadline_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            ),
      );
      FFAppState().queryEventsForTaichungStudyCounts =
          _model.queryEventsForTaichungStudy0!.length;
      safeSetState(() {});
      _model.queryEventsForTaipeiStudy0 = await EventsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull(
              'city_id',
              '2e7c8bc4-232b-4423-9526-002fc27ed1d3',
            )
            .eqOrNull(
              'category',
              EventCategory.focused_study.name,
            )
            .ltOrNull(
              'signup_open_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            )
            .gtOrNull(
              'signup_deadline_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            ),
      );
      FFAppState().queryEventsForTaipeiStudyCounts =
          _model.queryEventsForTaipeiStudy0!.length;
      safeSetState(() {});
      _model.queryEventsForTaoyuanGames0 = await EventsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull(
              'city_id',
              '2e3dfbb9-8c2a-4098-8c09-9213f55de6fc',
            )
            .eqOrNull(
              'category',
              EventCategory.english_games.name,
            )
            .ltOrNull(
              'signup_open_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            )
            .gtOrNull(
              'signup_deadline_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            ),
      );
      FFAppState().queryEventsForTaoyuanGamesCounts =
          _model.queryEventsForTaoyuanGames0!.length;
      safeSetState(() {});
      _model.queryEventsForHsinchuGames0 = await EventsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull(
              'city_id',
              '3d221404-0590-4cca-b553-1ab890f31267',
            )
            .eqOrNull(
              'category',
              EventCategory.english_games.name,
            )
            .ltOrNull(
              'signup_open_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            )
            .gtOrNull(
              'signup_deadline_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            ),
      );
      FFAppState().queryEventsForHsinchuGamesCounts =
          _model.queryEventsForHsinchuGames0!.length;
      safeSetState(() {});
      _model.queryEventsForChiayiGames0 = await EventsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull(
              'city_id',
              'c3e02d08-970d-4fcf-82c5-69a86f69e872',
            )
            .eqOrNull(
              'category',
              EventCategory.english_games.name,
            )
            .ltOrNull(
              'signup_open_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            )
            .gtOrNull(
              'signup_deadline_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            ),
      );
      FFAppState().queryEventsForChiayiGamesCounts =
          _model.queryEventsForChiayiGames0!.length;
      safeSetState(() {});
      _model.queryEventsForKaohsiungGames0 = await EventsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull(
              'city_id',
              '72cbb430-f015-41b1-970a-86297bf3c904',
            )
            .eqOrNull(
              'category',
              EventCategory.english_games.name,
            )
            .ltOrNull(
              'signup_open_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            )
            .gtOrNull(
              'signup_deadline_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            ),
      );
      FFAppState().queryEventsForKaohsiungGamesCounts =
          _model.queryEventsForKaohsiungGames0!.length;
      safeSetState(() {});
      _model.queryEventsForTainanGames0 = await EventsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull(
              'city_id',
              '33a466b3-6d0b-4cd6-b197-9eaba2101853',
            )
            .eqOrNull(
              'category',
              EventCategory.english_games.name,
            )
            .ltOrNull(
              'signup_open_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            )
            .gtOrNull(
              'signup_deadline_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            ),
      );
      FFAppState().queryEventsForTainanGamesCounts =
          _model.queryEventsForTainanGames0!.length;
      safeSetState(() {});
      _model.queryEventsForTaichungGames0 = await EventsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull(
              'city_id',
              '3bc5798e-933e-4d46-a819-05f3fa060077',
            )
            .eqOrNull(
              'category',
              EventCategory.english_games.name,
            )
            .ltOrNull(
              'signup_open_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            )
            .gtOrNull(
              'signup_deadline_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            ),
      );
      FFAppState().queryEventsForTaichungGamesCounts =
          _model.queryEventsForTaichungGames0!.length;
      safeSetState(() {});
      _model.queryEventsForTaipeiGames0 = await EventsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull(
              'city_id',
              '2e7c8bc4-232b-4423-9526-002fc27ed1d3',
            )
            .eqOrNull(
              'category',
              EventCategory.english_games.name,
            )
            .ltOrNull(
              'signup_open_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            )
            .gtOrNull(
              'signup_deadline_at',
              supaSerialize<DateTime>(getCurrentTimestamp),
            ),
      );
      FFAppState().queryEventsForTaipeiGamesCounts =
          _model.queryEventsForTaipeiGames0!.length;
      safeSetState(() {});
    });

    _model.tabBarController = TabController(
      vsync: this,
      length: 2,
      initialIndex: 0,
    )..addListener(() => safeSetState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground,
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment(0.0, 0),
                          child: TabBar(
                            labelColor:
                                FlutterFlowTheme.of(context).primaryText,
                            unselectedLabelColor:
                                FlutterFlowTheme.of(context).tertiary,
                            labelStyle: FlutterFlowTheme.of(context)
                                .labelLarge
                                .override(
                                  font: GoogleFonts.notoSansTc(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelLarge
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .fontStyle,
                                ),
                            unselectedLabelStyle:
                                FlutterFlowTheme.of(context).bodyLarge.override(
                                      font: GoogleFonts.notoSansTc(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyLarge
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyLarge
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .fontStyle,
                                    ),
                            indicatorColor:
                                FlutterFlowTheme.of(context).secondaryText,
                            tabs: [
                              Tab(
                                text: 'Focused Study',
                              ),
                              Tab(
                                text: 'English Games',
                              ),
                            ],
                            controller: _model.tabBarController,
                            onTap: (i) async {
                              [() async {}, () async {}][i]();
                            },
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _model.tabBarController,
                            children: [
                              Container(
                                decoration: BoxDecoration(),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 0.0, 8.0, 0.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 16.0, 0.0, 0.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                await showModalBottomSheet(
                                                  isScrollControlled: true,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  enableDrag: false,
                                                  context: context,
                                                  builder: (context) {
                                                    return WebViewAware(
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          FocusScope.of(context)
                                                              .unfocus();
                                                          FocusManager.instance
                                                              .primaryFocus
                                                              ?.unfocus();
                                                        },
                                                        child: Padding(
                                                          padding: MediaQuery
                                                              .viewInsetsOf(
                                                                  context),
                                                          child:
                                                              CitySelectorBottomSheetStudyWidget(),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ).then((value) =>
                                                    safeSetState(() {}));

                                                _model.queryEventsForTaoyuanStudy =
                                                    await EventsTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'city_id',
                                                        '2e3dfbb9-8c2a-4098-8c09-9213f55de6fc',
                                                      )
                                                      .eqOrNull(
                                                        'category',
                                                        EventCategory
                                                            .focused_study.name,
                                                      )
                                                      .ltOrNull(
                                                        'signup_open_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      )
                                                      .gtOrNull(
                                                        'signup_deadline_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      ),
                                                );
                                                FFAppState()
                                                        .queryEventsForTaoyuanStudyCounts =
                                                    _model
                                                        .queryEventsForTaoyuanStudy!
                                                        .length;
                                                safeSetState(() {});
                                                _model.queryEventsForHsinchuStudy =
                                                    await EventsTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'city_id',
                                                        '3d221404-0590-4cca-b553-1ab890f31267',
                                                      )
                                                      .eqOrNull(
                                                        'category',
                                                        EventCategory
                                                            .focused_study.name,
                                                      )
                                                      .ltOrNull(
                                                        'signup_open_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      )
                                                      .gtOrNull(
                                                        'signup_deadline_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      ),
                                                );
                                                FFAppState()
                                                        .queryEventsForHsinchuStudyCounts =
                                                    _model
                                                        .queryEventsForHsinchuStudy!
                                                        .length;
                                                safeSetState(() {});
                                                _model.queryEventsForChiayiStudy =
                                                    await EventsTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'city_id',
                                                        'c3e02d08-970d-4fcf-82c5-69a86f69e872',
                                                      )
                                                      .eqOrNull(
                                                        'category',
                                                        EventCategory
                                                            .focused_study.name,
                                                      )
                                                      .ltOrNull(
                                                        'signup_open_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      )
                                                      .gtOrNull(
                                                        'signup_deadline_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      ),
                                                );
                                                FFAppState()
                                                        .queryEventsForChiayiStudyCounts =
                                                    _model
                                                        .queryEventsForChiayiStudy!
                                                        .length;
                                                safeSetState(() {});
                                                _model.queryEventsForKaohsiungStudy =
                                                    await EventsTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'city_id',
                                                        '72cbb430-f015-41b1-970a-86297bf3c904',
                                                      )
                                                      .eqOrNull(
                                                        'category',
                                                        EventCategory
                                                            .focused_study.name,
                                                      )
                                                      .ltOrNull(
                                                        'signup_open_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      )
                                                      .gtOrNull(
                                                        'signup_deadline_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      ),
                                                );
                                                FFAppState()
                                                        .queryEventsForKaohsiungStudyCounts =
                                                    _model
                                                        .queryEventsForKaohsiungStudy!
                                                        .length;
                                                safeSetState(() {});
                                                _model.queryEventsForTainanStudy =
                                                    await EventsTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'city_id',
                                                        '33a466b3-6d0b-4cd6-b197-9eaba2101853',
                                                      )
                                                      .eqOrNull(
                                                        'category',
                                                        EventCategory
                                                            .focused_study.name,
                                                      )
                                                      .ltOrNull(
                                                        'signup_open_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      )
                                                      .gtOrNull(
                                                        'signup_deadline_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      ),
                                                );
                                                FFAppState()
                                                        .queryEventsForTainanStudyCounts =
                                                    _model
                                                        .queryEventsForTainanStudy!
                                                        .length;
                                                safeSetState(() {});
                                                _model.queryEventsForTaichungStudy =
                                                    await EventsTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'city_id',
                                                        '3bc5798e-933e-4d46-a819-05f3fa060077',
                                                      )
                                                      .eqOrNull(
                                                        'category',
                                                        EventCategory
                                                            .focused_study.name,
                                                      )
                                                      .ltOrNull(
                                                        'signup_open_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      )
                                                      .gtOrNull(
                                                        'signup_deadline_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      ),
                                                );
                                                FFAppState()
                                                        .queryEventsForTaichungStudyCounts =
                                                    _model
                                                        .queryEventsForTaichungStudy!
                                                        .length;
                                                safeSetState(() {});
                                                _model.queryEventsForTaipeiStudy =
                                                    await EventsTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'city_id',
                                                        '2e7c8bc4-232b-4423-9526-002fc27ed1d3',
                                                      )
                                                      .eqOrNull(
                                                        'category',
                                                        EventCategory
                                                            .focused_study.name,
                                                      )
                                                      .ltOrNull(
                                                        'signup_open_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      )
                                                      .gtOrNull(
                                                        'signup_deadline_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      ),
                                                );
                                                FFAppState()
                                                        .queryEventsForTaipeiStudyCounts =
                                                    _model
                                                        .queryEventsForTaipeiStudy!
                                                        .length;
                                                safeSetState(() {});

                                                safeSetState(() {});
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Icon(
                                                      Icons.location_pin,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      size: 32.0,
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  4.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Text(
                                                        FFAppState()
                                                            .currentCityName,
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelLarge
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .notoSansTc(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelLarge
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelLarge
                                                                        .fontStyle,
                                                                  ),
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelLarge
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelLarge
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                context.pushNamed(
                                                  CheckoutWidget.routeName,
                                                  queryParameters: {
                                                    'tabIndex': serializeParam(
                                                      0,
                                                      ParamType.int,
                                                    ),
                                                  }.withoutNulls,
                                                );
                                              },
                                              child: Container(
                                                width: 96.0,
                                                height: 48.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .tertiary,
                                                    width: 2.0,
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          4.0, 4.0, 4.0, 4.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    2.0,
                                                                    2.0,
                                                                    0.0,
                                                                    2.0),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                          child: Image.asset(
                                                            'assets/images/ticket_study_work.png',
                                                            fit: BoxFit.contain,
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    0.0,
                                                                    6.0,
                                                                    0.0),
                                                        child: Text(
                                                          FFAppState()
                                                              .studyBalance
                                                              .toString(),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .labelLarge
                                                              .override(
                                                                font: GoogleFonts
                                                                    .notoSansTc(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelLarge
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelLarge
                                                                      .fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryText,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelLarge
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelLarge
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 16.0, 0.0, 0.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          4.0, 0.0, 0.0, 0.0),
                                                  child: Text(
                                                    '和其他書呆子一起',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .titleMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .notoSansTc(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 4.0, 8.0, 0.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '交出手機，全程專注學習',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .titleMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .notoSansTc(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      FutureBuilder<List<HomeEventsVRow>>(
                                        future: FFAppState().homeFocusedStudy(
                                          uniqueQueryKey:
                                              '${currentUserUid}_focused_study',
                                          requestFn: () =>
                                              HomeEventsVTable().queryRows(
                                            queryFn: (q) => q
                                                .eqOrNull(
                                                  'city_id',
                                                  FFAppState().currentCityId,
                                                )
                                                .eqOrNull(
                                                  'category',
                                                  EventCategory
                                                      .focused_study.name,
                                                )
                                                .order('event_date',
                                                    ascending: true),
                                          ),
                                        ),
                                        builder: (context, snapshot) {
                                          // Customize what your widget looks like when it's loading.
                                          if (!snapshot.hasData) {
                                            return Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 24.0, 0.0, 0.0),
                                              child: Container(
                                                width:
                                                    MediaQuery.sizeOf(context)
                                                            .width *
                                                        1.0,
                                                child: EventCardLoadingWidget(),
                                              ),
                                            );
                                          }
                                          List<HomeEventsVRow>
                                              listViewHomeEventsVRowList =
                                              snapshot.data!;

                                          if (listViewHomeEventsVRowList
                                              .isEmpty) {
                                            return EventCardEmptyWidget();
                                          }

                                          return ListView.separated(
                                            padding: EdgeInsets.fromLTRB(
                                              0,
                                              24.0,
                                              0,
                                              24.0,
                                            ),
                                            shrinkWrap: true,
                                            scrollDirection: Axis.vertical,
                                            itemCount:
                                                listViewHomeEventsVRowList
                                                    .length,
                                            separatorBuilder: (_, __) =>
                                                SizedBox(height: 16.0),
                                            itemBuilder:
                                                (context, listViewIndex) {
                                              final listViewHomeEventsVRow =
                                                  listViewHomeEventsVRowList[
                                                      listViewIndex];
                                              return Builder(
                                                builder: (context) => InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  focusColor:
                                                      Colors.transparent,
                                                  hoverColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () async {
                                                    if (listViewHomeEventsVRow
                                                        .hasConflictSameSlot!) {
                                                      await showDialog(
                                                        context: context,
                                                        builder:
                                                            (dialogContext) {
                                                          return Dialog(
                                                            elevation: 0,
                                                            insetPadding:
                                                                EdgeInsets.zero,
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            alignment: AlignmentDirectional(
                                                                    0.0, 0.0)
                                                                .resolve(
                                                                    Directionality.of(
                                                                        context)),
                                                            child: WebViewAware(
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  FocusScope.of(
                                                                          dialogContext)
                                                                      .unfocus();
                                                                  FocusManager
                                                                      .instance
                                                                      .primaryFocus
                                                                      ?.unfocus();
                                                                },
                                                                child:
                                                                    AlertDialogWidget(
                                                                  title:
                                                                      '無法報名此活動',
                                                                  message:
                                                                      '你在此日期的同一時段已經報名其他活動，請改選其他時段或日期。',
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    } else {
                                                      context.pushNamed(
                                                        StudyBookingConfirmationWidget
                                                            .routeName,
                                                        queryParameters: {
                                                          'eventDate':
                                                              serializeParam(
                                                            listViewHomeEventsVRow
                                                                .eventDate,
                                                            ParamType.DateTime,
                                                          ),
                                                          'timeSlot':
                                                              serializeParam(
                                                            listViewHomeEventsVRow
                                                                .timeSlot,
                                                            ParamType.String,
                                                          ),
                                                          'locationDetail':
                                                              serializeParam(
                                                            listViewHomeEventsVRow
                                                                .locationDetail,
                                                            ParamType.String,
                                                          ),
                                                          'eventId':
                                                              serializeParam(
                                                            listViewHomeEventsVRow
                                                                .id,
                                                            ParamType.String,
                                                          ),
                                                        }.withoutNulls,
                                                      );
                                                    }
                                                  },
                                                  child: EventCardWidget(
                                                    key: Key(
                                                        'Key019_${listViewIndex}_of_${listViewHomeEventsVRowList.length}'),
                                                    eventDate:
                                                        listViewHomeEventsVRow
                                                            .eventDate!,
                                                    timeSlot:
                                                        listViewHomeEventsVRow
                                                            .timeSlot!,
                                                    locationDetail:
                                                        listViewHomeEventsVRow
                                                            .locationDetail!,
                                                    hasConflictSameSlot:
                                                        listViewHomeEventsVRow
                                                            .hasConflictSameSlot!,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      8.0, 0.0, 8.0, 0.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 16.0, 0.0, 0.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                await showModalBottomSheet(
                                                  isScrollControlled: true,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  enableDrag: false,
                                                  context: context,
                                                  builder: (context) {
                                                    return WebViewAware(
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          FocusScope.of(context)
                                                              .unfocus();
                                                          FocusManager.instance
                                                              .primaryFocus
                                                              ?.unfocus();
                                                        },
                                                        child: Padding(
                                                          padding: MediaQuery
                                                              .viewInsetsOf(
                                                                  context),
                                                          child:
                                                              CitySelectorBottomSheetStudyWidget(),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ).then((value) =>
                                                    safeSetState(() {}));

                                                _model.queryEventsForTaoyuanGames =
                                                    await EventsTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'city_id',
                                                        '2e3dfbb9-8c2a-4098-8c09-9213f55de6fc',
                                                      )
                                                      .eqOrNull(
                                                        'category',
                                                        EventCategory
                                                            .english_games.name,
                                                      )
                                                      .ltOrNull(
                                                        'signup_open_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      )
                                                      .gtOrNull(
                                                        'signup_deadline_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      ),
                                                );
                                                FFAppState()
                                                        .queryEventsForTaoyuanGamesCounts =
                                                    _model
                                                        .queryEventsForTaoyuanGames!
                                                        .length;
                                                safeSetState(() {});
                                                _model.queryEventsForHsinchuGames =
                                                    await EventsTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'city_id',
                                                        '3d221404-0590-4cca-b553-1ab890f31267',
                                                      )
                                                      .eqOrNull(
                                                        'category',
                                                        EventCategory
                                                            .english_games.name,
                                                      )
                                                      .ltOrNull(
                                                        'signup_open_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      )
                                                      .gtOrNull(
                                                        'signup_deadline_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      ),
                                                );
                                                FFAppState()
                                                        .queryEventsForHsinchuGamesCounts =
                                                    _model
                                                        .queryEventsForHsinchuGames!
                                                        .length;
                                                safeSetState(() {});
                                                _model.queryEventsForChiayiGames =
                                                    await EventsTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'city_id',
                                                        'c3e02d08-970d-4fcf-82c5-69a86f69e872',
                                                      )
                                                      .eqOrNull(
                                                        'category',
                                                        EventCategory
                                                            .english_games.name,
                                                      )
                                                      .ltOrNull(
                                                        'signup_open_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      )
                                                      .gtOrNull(
                                                        'signup_deadline_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      ),
                                                );
                                                FFAppState()
                                                        .queryEventsForChiayiGamesCounts =
                                                    _model
                                                        .queryEventsForChiayiGames!
                                                        .length;
                                                safeSetState(() {});
                                                _model.queryEventsForKaohsiungGames =
                                                    await EventsTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'city_id',
                                                        '72cbb430-f015-41b1-970a-86297bf3c904',
                                                      )
                                                      .eqOrNull(
                                                        'category',
                                                        EventCategory
                                                            .english_games.name,
                                                      )
                                                      .ltOrNull(
                                                        'signup_open_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      )
                                                      .gtOrNull(
                                                        'signup_deadline_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      ),
                                                );
                                                FFAppState()
                                                        .queryEventsForKaohsiungGamesCounts =
                                                    _model
                                                        .queryEventsForKaohsiungGames!
                                                        .length;
                                                safeSetState(() {});
                                                _model.queryEventsForTainanGames =
                                                    await EventsTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'city_id',
                                                        '33a466b3-6d0b-4cd6-b197-9eaba2101853',
                                                      )
                                                      .eqOrNull(
                                                        'category',
                                                        EventCategory
                                                            .english_games.name,
                                                      )
                                                      .ltOrNull(
                                                        'signup_open_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      )
                                                      .gtOrNull(
                                                        'signup_deadline_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      ),
                                                );
                                                FFAppState()
                                                        .queryEventsForTainanGamesCounts =
                                                    _model
                                                        .queryEventsForTainanGames!
                                                        .length;
                                                safeSetState(() {});
                                                _model.queryEventsForTaichungGames =
                                                    await EventsTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'city_id',
                                                        '3bc5798e-933e-4d46-a819-05f3fa060077',
                                                      )
                                                      .eqOrNull(
                                                        'category',
                                                        EventCategory
                                                            .english_games.name,
                                                      )
                                                      .ltOrNull(
                                                        'signup_open_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      )
                                                      .gtOrNull(
                                                        'signup_deadline_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      ),
                                                );
                                                FFAppState()
                                                        .queryEventsForTaichungGamesCounts =
                                                    _model
                                                        .queryEventsForTaichungGames!
                                                        .length;
                                                safeSetState(() {});
                                                _model.queryEventsForTaipeiGames =
                                                    await EventsTable()
                                                        .queryRows(
                                                  queryFn: (q) => q
                                                      .eqOrNull(
                                                        'city_id',
                                                        '2e7c8bc4-232b-4423-9526-002fc27ed1d3',
                                                      )
                                                      .eqOrNull(
                                                        'category',
                                                        EventCategory
                                                            .english_games.name,
                                                      )
                                                      .ltOrNull(
                                                        'signup_open_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      )
                                                      .gtOrNull(
                                                        'signup_deadline_at',
                                                        supaSerialize<DateTime>(
                                                            getCurrentTimestamp),
                                                      ),
                                                );
                                                FFAppState()
                                                        .queryEventsForTaipeiGamesCounts =
                                                    _model
                                                        .queryEventsForTaipeiGames!
                                                        .length;
                                                safeSetState(() {});

                                                safeSetState(() {});
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Icon(
                                                      Icons.location_pin,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      size: 32.0,
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  4.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Text(
                                                        FFAppState()
                                                            .currentCityName,
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelLarge
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .notoSansTc(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelLarge
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelLarge
                                                                        .fontStyle,
                                                                  ),
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelLarge
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelLarge
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              splashColor: Colors.transparent,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              highlightColor:
                                                  Colors.transparent,
                                              onTap: () async {
                                                context.pushNamed(
                                                  CheckoutWidget.routeName,
                                                  queryParameters: {
                                                    'tabIndex': serializeParam(
                                                      1,
                                                      ParamType.int,
                                                    ),
                                                  }.withoutNulls,
                                                );
                                              },
                                              child: Container(
                                                width: 96.0,
                                                height: 48.0,
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .tertiary,
                                                    width: 2.0,
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          4.0, 4.0, 4.0, 4.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    2.0,
                                                                    2.0,
                                                                    0.0,
                                                                    2.0),
                                                        child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                          child: Image.asset(
                                                            'assets/images/ticket_games_work2.png',
                                                            fit: BoxFit.contain,
                                                          ),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    0.0,
                                                                    6.0,
                                                                    0.0),
                                                        child: Text(
                                                          FFAppState()
                                                              .gamesBalance
                                                              .toString(),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .labelLarge
                                                              .override(
                                                                font: GoogleFonts
                                                                    .notoSansTc(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelLarge
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelLarge
                                                                      .fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryText,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelLarge
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelLarge
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 16.0, 0.0, 0.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          4.0, 0.0, 0.0, 0.0),
                                                  child: Text(
                                                    '和其他書呆子一起',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .titleMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .notoSansTc(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(0.0, 4.0, 8.0, 0.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '封印中文，全程英文遊戲',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .titleMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .notoSansTc(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      FutureBuilder<List<HomeEventsVRow>>(
                                        future: FFAppState().homeEnglishGames(
                                          uniqueQueryKey:
                                              '${currentUserUid}_english_games',
                                          requestFn: () =>
                                              HomeEventsVTable().queryRows(
                                            queryFn: (q) => q
                                                .eqOrNull(
                                                  'city_id',
                                                  FFAppState().currentCityId,
                                                )
                                                .eqOrNull(
                                                  'category',
                                                  EventCategory
                                                      .english_games.name,
                                                )
                                                .order('event_date',
                                                    ascending: true),
                                          ),
                                        ),
                                        builder: (context, snapshot) {
                                          // Customize what your widget looks like when it's loading.
                                          if (!snapshot.hasData) {
                                            return Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 24.0, 0.0, 0.0),
                                              child: Container(
                                                width:
                                                    MediaQuery.sizeOf(context)
                                                            .width *
                                                        1.0,
                                                child: EventCardLoadingWidget(),
                                              ),
                                            );
                                          }
                                          List<HomeEventsVRow>
                                              listViewHomeEventsVRowList =
                                              snapshot.data!;

                                          if (listViewHomeEventsVRowList
                                              .isEmpty) {
                                            return EventCardEmptyWidget();
                                          }

                                          return ListView.separated(
                                            padding: EdgeInsets.fromLTRB(
                                              0,
                                              24.0,
                                              0,
                                              24.0,
                                            ),
                                            shrinkWrap: true,
                                            scrollDirection: Axis.vertical,
                                            itemCount:
                                                listViewHomeEventsVRowList
                                                    .length,
                                            separatorBuilder: (_, __) =>
                                                SizedBox(height: 16.0),
                                            itemBuilder:
                                                (context, listViewIndex) {
                                              final listViewHomeEventsVRow =
                                                  listViewHomeEventsVRowList[
                                                      listViewIndex];
                                              return Builder(
                                                builder: (context) => InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  focusColor:
                                                      Colors.transparent,
                                                  hoverColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () async {
                                                    if (listViewHomeEventsVRow
                                                        .hasConflictSameSlot!) {
                                                      await showDialog(
                                                        context: context,
                                                        builder:
                                                            (dialogContext) {
                                                          return Dialog(
                                                            elevation: 0,
                                                            insetPadding:
                                                                EdgeInsets.zero,
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            alignment: AlignmentDirectional(
                                                                    0.0, 0.0)
                                                                .resolve(
                                                                    Directionality.of(
                                                                        context)),
                                                            child: WebViewAware(
                                                              child:
                                                                  GestureDetector(
                                                                onTap: () {
                                                                  FocusScope.of(
                                                                          dialogContext)
                                                                      .unfocus();
                                                                  FocusManager
                                                                      .instance
                                                                      .primaryFocus
                                                                      ?.unfocus();
                                                                },
                                                                child:
                                                                    AlertDialogWidget(
                                                                  title:
                                                                      '無法報名此活動',
                                                                  message:
                                                                      '你在此日期的同一時段已經報名其他活動，請改選其他時段或日期。',
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    } else {
                                                      context.pushNamed(
                                                        GamesBookingConfirmationWidget
                                                            .routeName,
                                                        queryParameters: {
                                                          'eventDate':
                                                              serializeParam(
                                                            listViewHomeEventsVRow
                                                                .eventDate,
                                                            ParamType.DateTime,
                                                          ),
                                                          'timeSlot':
                                                              serializeParam(
                                                            listViewHomeEventsVRow
                                                                .timeSlot,
                                                            ParamType.String,
                                                          ),
                                                          'locationDetail':
                                                              serializeParam(
                                                            listViewHomeEventsVRow
                                                                .locationDetail,
                                                            ParamType.String,
                                                          ),
                                                          'eventId':
                                                              serializeParam(
                                                            listViewHomeEventsVRow
                                                                .id,
                                                            ParamType.String,
                                                          ),
                                                        }.withoutNulls,
                                                      );
                                                    }
                                                  },
                                                  child: EventCardWidget(
                                                    key: Key(
                                                        'Key02w_${listViewIndex}_of_${listViewHomeEventsVRowList.length}'),
                                                    timeSlot:
                                                        listViewHomeEventsVRow
                                                            .timeSlot!,
                                                    locationDetail:
                                                        listViewHomeEventsVRow
                                                            .locationDetail!,
                                                    eventDate:
                                                        listViewHomeEventsVRow
                                                            .eventDate!,
                                                    hasConflictSameSlot:
                                                        listViewHomeEventsVRow
                                                            .hasConflictSameSlot!,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ].divide(SizedBox(height: 12.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
