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
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'my_events_model.dart';
export 'my_events_model.dart';

class MyEventsWidget extends StatefulWidget {
  const MyEventsWidget({super.key});

  static String routeName = 'MyEvents';
  static String routePath = '/myEvents';

  @override
  State<MyEventsWidget> createState() => _MyEventsWidgetState();
}

class _MyEventsWidgetState extends State<MyEventsWidget>
    with TickerProviderStateMixin {
  late MyEventsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MyEventsModel());

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
                                FlutterFlowTheme.of(context).secondaryText,
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
                                text: 'Upcoming',
                              ),
                              Tab(
                                text: 'History',
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
                                      FutureBuilder<List<MyEventsVRow>>(
                                        future: FFAppState().myEventsUpcoming(
                                          uniqueQueryKey:
                                              '${currentUserUid}_upcoming',
                                          requestFn: () =>
                                              MyEventsVTable().queryRows(
                                            queryFn: (q) => q
                                                .eqOrNull(
                                                  'user_id',
                                                  currentUserUid,
                                                )
                                                .neqOrNull(
                                                  'event_status',
                                                  'completed',
                                                )
                                                .neqOrNull(
                                                  'event_status',
                                                  'cancelled',
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
                                                child:
                                                    MyEventCardLoadingWidget(),
                                              ),
                                            );
                                          }
                                          List<MyEventsVRow>
                                              listViewMyEventsVRowList =
                                              snapshot.data!;

                                          if (listViewMyEventsVRowList
                                              .isEmpty) {
                                            return MyEventCardEmptyUpcomingWidget();
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
                                                listViewMyEventsVRowList.length,
                                            separatorBuilder: (_, __) =>
                                                SizedBox(height: 16.0),
                                            itemBuilder:
                                                (context, listViewIndex) {
                                              final listViewMyEventsVRow =
                                                  listViewMyEventsVRowList[
                                                      listViewIndex];
                                              return MyEventCardWidget(
                                                key: Key(
                                                    'Keypj0_${listViewIndex}_of_${listViewMyEventsVRowList.length}'),
                                                cityId: listViewMyEventsVRow
                                                    .cityId!,
                                                venueName: listViewMyEventsVRow
                                                    .venueName,
                                                locationDetail:
                                                    listViewMyEventsVRow
                                                        .locationDetail!,
                                                eventStatus:
                                                    listViewMyEventsVRow
                                                        .eventStatus!,
                                                groupStartAt:
                                                    listViewMyEventsVRow
                                                        .groupStartAt,
                                                eventCategory:
                                                    listViewMyEventsVRow
                                                        .eventCategory!,
                                                eventDate: listViewMyEventsVRow
                                                    .eventDate!,
                                                timeSlot: listViewMyEventsVRow
                                                    .timeSlot!,
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
                                      FutureBuilder<List<MyEventsVRow>>(
                                        future: FFAppState().myEventsHistory(
                                          uniqueQueryKey:
                                              '${currentUserUid}_history',
                                          requestFn: () =>
                                              MyEventsVTable().queryRows(
                                            queryFn: (q) => q
                                                .eqOrNull(
                                                  'user_id',
                                                  currentUserUid,
                                                )
                                                .eqOrNull(
                                                  'event_status',
                                                  'completed',
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
                                                child:
                                                    MyEventCardLoadingWidget(),
                                              ),
                                            );
                                          }
                                          List<MyEventsVRow>
                                              listViewMyEventsVRowList =
                                              snapshot.data!;

                                          if (listViewMyEventsVRowList
                                              .isEmpty) {
                                            return MyEventCardEmptyHistoryWidget();
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
                                                listViewMyEventsVRowList.length,
                                            separatorBuilder: (_, __) =>
                                                SizedBox(height: 16.0),
                                            itemBuilder:
                                                (context, listViewIndex) {
                                              final listViewMyEventsVRow =
                                                  listViewMyEventsVRowList[
                                                      listViewIndex];
                                              return MyEventCardWidget(
                                                key: Key(
                                                    'Keyjbp_${listViewIndex}_of_${listViewMyEventsVRowList.length}'),
                                                cityId: listViewMyEventsVRow
                                                    .cityId!,
                                                venueName: listViewMyEventsVRow
                                                    .venueName,
                                                locationDetail:
                                                    listViewMyEventsVRow
                                                        .locationDetail!,
                                                eventStatus:
                                                    listViewMyEventsVRow
                                                        .eventStatus!,
                                                groupStartAt:
                                                    listViewMyEventsVRow
                                                        .groupStartAt,
                                                eventCategory:
                                                    listViewMyEventsVRow
                                                        .eventCategory!,
                                                eventDate: listViewMyEventsVRow
                                                    .eventDate!,
                                                timeSlot: listViewMyEventsVRow
                                                    .timeSlot!,
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
