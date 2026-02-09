import 'package:intl/intl.dart';

import 'app_clock.dart';

/// Date and time utilities for Campus Nerds
class AppDateUtils {
  static final _dateFormat = DateFormat('yyyy/MM/dd');
  static final _dateFormatWithDay = DateFormat('yyyy/MM/dd (E)', 'zh_TW');
  static final _timeFormat = DateFormat('HH:mm');
  static final _dateTimeFormat = DateFormat('yyyy/MM/dd HH:mm');

  /// Format date as yyyy/MM/dd
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Format date with day of week (e.g., 2024/01/15 (一))
  static String formatDateWithDay(DateTime date) {
    return _dateFormatWithDay.format(date);
  }

  /// Format time as HH:mm
  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  /// Format datetime as yyyy/MM/dd HH:mm
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// Get time slot label in Chinese
  static String getTimeSlotLabel(String timeSlot) {
    switch (timeSlot) {
      case 'morning':
        return '早上';
      case 'afternoon':
        return '下午';
      case 'evening':
        return '晚上';
      default:
        return timeSlot;
    }
  }

  /// Get time slot time range
  static String getTimeSlotRange(String timeSlot) {
    switch (timeSlot) {
      case 'morning':
        return '09:00 - 12:00';
      case 'afternoon':
        return '14:00 - 17:00';
      case 'evening':
        return '19:00 - 22:00';
      default:
        return '';
    }
  }

  /// Calculate age from birthday
  static int calculateAge(DateTime birthday) {
    final now = AppClock.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  /// Check if datetime is in the past
  static bool isPast(DateTime dateTime) {
    return dateTime.isBefore(AppClock.now());
  }

  /// Check if datetime is in the future
  static bool isFuture(DateTime dateTime) {
    return dateTime.isAfter(AppClock.now());
  }

  /// Get relative time string (e.g., "5 分鐘前")
  static String getRelativeTime(DateTime dateTime) {
    final now = AppClock.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} 天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小時前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分鐘前';
    } else {
      return '剛剛';
    }
  }
}
