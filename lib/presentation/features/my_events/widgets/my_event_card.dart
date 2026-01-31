import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/entities/booking.dart';
import '../../../../domain/entities/event.dart';

/// My event card widget matching FlutterFlow design exactly
class MyEventCard extends StatelessWidget {
  const MyEventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  final MyEvent event;
  final VoidCallback onTap;

  /// Get city name from city ID
  String _getCityName(String? cityId) {
    if (cityId == null) return '';

    final cityMap = {
      '2e7c8bc4-232b-4423-9526-002fc27ed1d3': '臺北',
      '2e3dfbb9-8c2a-4098-8c09-9213f55de6fc': '桃園',
      '3d221404-0590-4cca-b553-1ab890f31267': '新竹',
      '3bc5798e-933e-4d46-a819-05f3fa060077': '臺中',
      'c3e02d08-970d-4fcf-82c5-69a86f69e872': '嘉義',
      '33a466b3-6d0b-4cd6-b197-9eaba2101853': '臺南',
      '72cbb430-f015-41b1-970a-86297bf3c904': '高雄',
    };
    return cityMap[cityId] ?? '';
  }

  /// Get event status display name
  String _getStatusDisplayName(String? eventStatus) {
    if (eventStatus == 'scheduled' || eventStatus == 'notified') {
      return '已報名';
    } else if (eventStatus == 'completed') {
      return '已結束';
    }
    return '';
  }

  /// Format date based on event status
  String _formatDate() {
    final eventStatus = event.eventStatus.value;

    if (eventStatus == 'scheduled') {
      // Show event date with time slot
      final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
      final weekday = weekdays[event.eventDate.weekday - 1];
      final dateStr = '${event.eventDate.month} 月 ${event.eventDate.day} 日 ( $weekday )';

      String timeSlotStr;
      switch (event.timeSlot) {
        case TimeSlot.morning:
          timeSlotStr = '  早上';
          break;
        case TimeSlot.afternoon:
          timeSlotStr = '  下午';
          break;
        case TimeSlot.evening:
          timeSlotStr = ' 晚上';
          break;
      }

      return '$dateStr$timeSlotStr';
    } else {
      // Show group start time (for notified/completed)
      if (event.groupStartAt != null) {
        final dt = event.groupStartAt!;
        final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
        final weekday = weekdays[dt.weekday - 1];
        final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        return '${dt.month} 月 ${dt.day} 日 ( $weekday )  $timeStr';
      }

      // Fallback to event date
      final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
      final weekday = weekdays[event.eventDate.weekday - 1];
      return '${event.eventDate.month} 月 ${event.eventDate.day} 日 ( $weekday )';
    }
  }

  /// Get location display text
  String _getLocationDisplay() {
    final eventStatus = event.eventStatus.value;

    if (eventStatus == 'scheduled') {
      // Show location detail enum display name
      return _getLocationDetailName(event.locationDetail);
    } else {
      // Show venue name for notified/completed
      return event.venueName ?? _getLocationDetailName(event.locationDetail);
    }
  }

  /// Get location detail display name
  String _getLocationDetailName(String locationDetail) {
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

    return InkWell(
      onTap: onTap,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header row: category + city + status
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category + City
                    Row(
                      children: [
                        Text(
                          event.isFocusedStudy ? 'Focused Study' : 'English Ganes',
                          style: textTheme.titleMedium?.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                          ),
                        ),
                        Text(
                          '  ( ${_getCityName(event.cityId)} ) ',
                          style: textTheme.bodyLarge?.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                          ),
                        ),
                      ],
                    ),

                    // Status badge
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.tertiaryText,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            _getStatusDisplayName(event.eventStatus.value),
                            style: textTheme.bodyMedium?.copyWith(
                              fontFamily: GoogleFonts.notoSansTc().fontFamily,
                              color: colors.secondaryBackground,
                              shadows: [
                                Shadow(
                                  color: colors.primaryText,
                                  offset: const Offset(0.2, 0.2),
                                  blurRadius: 0.2,
                                ),
                                Shadow(
                                  color: colors.primaryText,
                                  offset: const Offset(-0.2, -0.2),
                                  blurRadius: 0.2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Time row
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '時間： ',
                          style: textTheme.labelMedium?.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                          ),
                        ),
                        Text(
                          _formatDate(),
                          style: textTheme.labelLarge?.copyWith(
                            fontFamily: GoogleFonts.notoSansTc().fontFamily,
                          ),
                        ),
                      ],
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
                    Text(
                      '地點： ',
                      style: textTheme.labelMedium?.copyWith(
                        fontFamily: GoogleFonts.notoSansTc().fontFamily,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        _getLocationDisplay(),
                        style: textTheme.labelMedium?.copyWith(
                          fontFamily: GoogleFonts.notoSansTc().fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
