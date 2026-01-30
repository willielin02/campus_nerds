import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'my_event_card_model.dart';
export 'my_event_card_model.dart';

class MyEventCardWidget extends StatefulWidget {
  const MyEventCardWidget({
    super.key,
    required this.cityId,
    this.groupStartAt,
    required this.eventCategory,
    this.venueName,
    required this.eventDate,
    required this.timeSlot,
    required this.locationDetail,
    required this.eventStatus,
  });

  final String? cityId;
  final DateTime? groupStartAt;
  final String? eventCategory;
  final String? venueName;
  final DateTime? eventDate;
  final String? timeSlot;
  final String? locationDetail;
  final String? eventStatus;

  @override
  State<MyEventCardWidget> createState() => _MyEventCardWidgetState();
}

class _MyEventCardWidgetState extends State<MyEventCardWidget> {
  late MyEventCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MyEventCardModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 579.0,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).tertiary,
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
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
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        () {
                          if (widget!.eventCategory ==
                              EventCategory.focused_study.name) {
                            return 'Focused Study';
                          } else if (widget!.eventCategory ==
                              EventCategory.english_games.name) {
                            return 'English Ganes';
                          } else {
                            return '';
                          }
                        }(),
                        style:
                            FlutterFlowTheme.of(context).titleMedium.override(
                                  font: GoogleFonts.notoSansTc(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                      ),
                      Text(
                        '  ( ${() {
                          if (widget!.cityId ==
                              '2e7c8bc4-232b-4423-9526-002fc27ed1d3') {
                            return '臺北';
                          } else if (widget!.cityId ==
                              '2e3dfbb9-8c2a-4098-8c09-9213f55de6fc') {
                            return '桃園';
                          } else if (widget!.cityId ==
                              '3d221404-0590-4cca-b553-1ab890f31267') {
                            return '新竹';
                          } else if (widget!.cityId ==
                              '3bc5798e-933e-4d46-a819-05f3fa060077') {
                            return '臺中';
                          } else if (widget!.cityId ==
                              'c3e02d08-970d-4fcf-82c5-69a86f69e872') {
                            return '嘉義';
                          } else if (widget!.cityId ==
                              '33a466b3-6d0b-4cd6-b197-9eaba2101853') {
                            return '臺南';
                          } else if (widget!.cityId ==
                              '72cbb430-f015-41b1-970a-86297bf3c904') {
                            return '高雄';
                          } else {
                            return '';
                          }
                        }()} ) ',
                        style: FlutterFlowTheme.of(context).bodyLarge.override(
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
                    ],
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).tertiaryText,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(4.0, 4.0, 4.0, 4.0),
                        child: Text(
                          () {
                            if ((widget!.eventStatus == 'scheduled') ||
                                (widget!.eventStatus == 'notified')) {
                              return '已報名';
                            } else if (widget!.eventStatus == 'completed') {
                              return '已結束';
                            } else {
                              return '';
                            }
                          }(),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.notoSansTc(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                            shadows: [
                              Shadow(
                                color: FlutterFlowTheme.of(context).primaryText,
                                offset: Offset(0.2, 0.2),
                                blurRadius: 0.2,
                              ),
                              Shadow(
                                color: FlutterFlowTheme.of(context).primaryText,
                                offset: Offset(-0.2, -0.2),
                                blurRadius: 0.2,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '時間： ',
                          style:
                              FlutterFlowTheme.of(context).labelMedium.override(
                                    font: GoogleFonts.notoSansTc(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                        ),
                        Text(
                          () {
                            if (widget!.eventStatus == 'scheduled') {
                              return '${dateTimeFormat(
                                "M 月 d 日 ( EEEEE )",
                                widget!.eventDate,
                                locale:
                                    FFLocalizations.of(context).languageCode,
                              )}${() {
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
                              }()}';
                            } else if ((widget!.eventStatus == 'notified') ||
                                (widget!.eventStatus == 'completed')) {
                              return dateTimeFormat(
                                "M 月 d 日 ( EEEEE )  HH:mm",
                                widget!.groupStartAt,
                                locale:
                                    FFLocalizations.of(context).languageCode,
                              );
                            } else {
                              return '';
                            }
                          }(),
                          style:
                              FlutterFlowTheme.of(context).labelLarge.override(
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
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 18.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '地點： ',
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.notoSansTc(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelMedium
                                .fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontStyle,
                        ),
                  ),
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(),
                      child: Text(
                        () {
                          if (widget!.eventStatus == 'scheduled') {
                            return () {
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
                              } else if (widget!.locationDetail == EventLocationDetail.library_or_cafe.name) {
                                return '圖書館/ 咖啡廳';
                              } else if (widget!.locationDetail == EventLocationDetail.boardgame_or_escape_room.name) {
                                return '桌遊店/ 密室逃脫';
                              } else {
                                return '';
                              }
                            }();
                          } else if ((widget!.eventStatus == 'notified') ||
                              (widget!.eventStatus == 'completed')) {
                            return widget!.venueName!;
                          } else {
                            return '';
                          }
                        }(),
                        style:
                            FlutterFlowTheme.of(context).labelMedium.override(
                                  font: GoogleFonts.notoSansTc(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .fontStyle,
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
