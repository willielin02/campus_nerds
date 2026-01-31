import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/event.dart';

/// Event card widget matching FlutterFlow design exactly
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  final Event event;
  final VoidCallback onTap;

  /// Format date as "M 月 d 日 ( EEEEE )"
  String _formatDate(DateTime date) {
    // Get weekday in Chinese
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month} 月 ${date.day} 日 ( $weekday )';
  }

  /// Get time slot display name
  String _getTimeSlotName(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return '  早上';
      case TimeSlot.afternoon:
        return '  下午';
      case TimeSlot.evening:
        return ' 晚上';
    }
  }

  /// Get location detail display name
  String _getLocationDisplay(String locationDetail) {
    // Map location detail enum to display name
    final locationMap = {
      'ntu_main_library_reading_area': '國立臺灣大學總圖書館 閱覽區',
      'nycu_haoran_library_reading_area': '國立陽明交通大學浩然圖書館 閱覽區',
      'nycu_yangming_campus_library_reading_area': '國立陽明交通大學陽明校區圖書館 閱覽區',
      'nthu_main_library_reading_area': '國立清華大學總圖書館 閱覽區',
      'ncku_main_library_reading_area': '國立成功大學總圖書館 閱覽區',
      'nccu_daxian_library_reading_area': '國立政治大學達賢圖書館 閱覽區',
      'ncu_main_library_reading_area': '國立中央大學總圖書館 閱覽區',
      'nsysu_library_reading_area': '國立中山大學圖書館 閱覽區',
      'nchu_main_library_reading_area': '國立中興大學總圖書館 閱覽區',
      'ccu_library_reading_area': '國立中正大學圖書館 閱覽區',
      'ntnu_main_library_reading_area': '國立臺灣師範大學總圖書館 閱覽區',
      'ntpu_library_reading_area': '國立臺北大學圖書館 閱覽區',
      'ntust_library_reading_area': '國立臺灣科技大學圖書館 閱覽區',
      'ntut_library_reading_area': '國立臺北科技大學圖書館 閱覽區',
      'library_or_cafe': '圖書館/ 咖啡廳',
      'boardgame_or_escape_room': '桌遊店/ 密室逃脫',
    };
    return locationMap[locationDetail] ?? locationDetail;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = context.textTheme;

    return Opacity(
      opacity: event.hasConflictSameSlot ? 0.222 : 1.0,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.tertiary,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Date and time row
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        Text(
                          _formatDate(event.eventDate),
                          style: textTheme.labelLarge?.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                          ),
                        ),
                        Text(
                          _getTimeSlotName(event.timeSlot),
                          style: textTheme.labelLarge?.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Container(),
                  ),
                ],
              ),
            ),

            // Location row
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        _getLocationDisplay(event.locationDetail),
                        style: textTheme.bodyLarge?.copyWith(
                          fontFamily: GoogleFonts.notoSansTc().fontFamily,
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
