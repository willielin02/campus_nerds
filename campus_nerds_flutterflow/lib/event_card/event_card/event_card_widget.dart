import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'event_card_model.dart';
export 'event_card_model.dart';

class EventCardWidget extends StatefulWidget {
  const EventCardWidget({
    super.key,
    required this.eventDate,
    required this.timeSlot,
    required this.locationDetail,
    required this.hasConflictSameSlot,
  });

  final DateTime? eventDate;
  final String? timeSlot;
  final String? locationDetail;
  final bool? hasConflictSameSlot;

  @override
  State<EventCardWidget> createState() => _EventCardWidgetState();
}

class _EventCardWidgetState extends State<EventCardWidget> {
  late EventCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EventCardModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget!.hasConflictSameSlot! ? 0.222 : 1.0,
      child: Container(
        width: 579.0,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: FlutterFlowTheme.of(context).tertiary,
            width: 2.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 0.0),
                    child: Container(
                      decoration: BoxDecoration(),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dateTimeFormat(
                              "M 月 d 日 ( EEEEE )",
                              widget!.eventDate,
                              locale: FFLocalizations.of(context).languageCode,
                            ),
                            style: FlutterFlowTheme.of(context)
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
                          ),
                          Text(
                            () {
                              if (widget!.timeSlot ==
                                  EventTimeSlot.morning.name) {
                                return '  早上';
                              } else if (widget!.timeSlot ==
                                  EventTimeSlot.afternoon.name) {
                                return '  下午';
                              } else if (widget!.timeSlot ==
                                  EventTimeSlot.evening.name) {
                                return ' 晚上';
                              } else {
                                return '';
                              }
                            }(),
                            style: FlutterFlowTheme.of(context)
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
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
                    child: Container(
                      decoration: BoxDecoration(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 18.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(),
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 0.0),
                        child: Text(
                          () {
                            if (widget!.locationDetail ==
                                EventLocationDetail
                                    .ntu_main_library_reading_area.name) {
                              return '國立臺灣大學總圖書館 閱覽區';
                            } else if (widget!.locationDetail ==
                                EventLocationDetail
                                    .nycu_haoran_library_reading_area.name) {
                              return '國立陽明交通大學浩然圖書館 閱覽區';
                            } else if (widget!.locationDetail ==
                                EventLocationDetail
                                    .nycu_yangming_campus_library_reading_area
                                    .name) {
                              return '國立陽明交通大學陽明校區圖書館 閱覽區';
                            } else if (widget!.locationDetail ==
                                EventLocationDetail
                                    .nthu_main_library_reading_area.name) {
                              return '國立清華大學總圖書館 閱覽區';
                            } else if (widget!.locationDetail ==
                                EventLocationDetail
                                    .ncku_main_library_reading_area.name) {
                              return '國立成功大學總圖書館 閱覽區';
                            } else if (widget!.locationDetail ==
                                EventLocationDetail
                                    .nccu_daxian_library_reading_area.name) {
                              return '國立政治大學達賢圖書館 閱覽區';
                            } else if (widget!.locationDetail ==
                                EventLocationDetail
                                    .ncu_main_library_reading_area.name) {
                              return '國立中央大學總圖書館 閱覽區';
                            } else if (widget!.locationDetail ==
                                EventLocationDetail
                                    .nsysu_library_reading_area.name) {
                              return '國立中山大學圖書館 閱覽區';
                            } else if (widget!.locationDetail ==
                                EventLocationDetail
                                    .nchu_main_library_reading_area.name) {
                              return '國立中興大學總圖書館 閱覽區';
                            } else if (widget!.locationDetail ==
                                EventLocationDetail
                                    .ccu_library_reading_area.name) {
                              return '國立中正大學圖書館 閱覽區';
                            } else if (widget!.locationDetail ==
                                EventLocationDetail
                                    .ntnu_main_library_reading_area.name) {
                              return '國立臺灣師範大學總圖書館 閱覽區';
                            } else if (widget!.locationDetail ==
                                EventLocationDetail
                                    .ntpu_library_reading_area.name) {
                              return '國立臺北大學圖書館 閱覽區';
                            } else if (widget!.locationDetail ==
                                EventLocationDetail
                                    .ntust_library_reading_area.name) {
                              return '國立臺灣科技大學圖書館 閱覽區';
                            } else if (widget!.locationDetail ==
                                EventLocationDetail
                                    .ntut_library_reading_area.name) {
                              return '國立臺北科技大學圖書館 閱覽區';
                            } else if (widget!.locationDetail ==
                                EventLocationDetail.library_or_cafe.name) {
                              return '圖書館/ 咖啡廳';
                            } else if (widget!.locationDetail ==
                                EventLocationDetail
                                    .boardgame_or_escape_room.name) {
                              return '桌遊店/ 密室逃脫';
                            } else {
                              return '';
                            }
                          }(),
                          style:
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
}
