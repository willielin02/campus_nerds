import 'package:flutter/foundation.dart';

import '../services/supabase_service.dart';

/// Centralized clock utility that syncs with Supabase server time.
///
/// **Release mode:** Skips server sync entirely — [now] returns real device
/// time with zero overhead.
///
/// **Debug/profile mode:** Syncs with the server's `get_server_now()` RPC
/// on startup. If mock time is set via `SELECT test_set_now(...)`, all
/// time-gated logic in both Flutter and Supabase will use the same mock time.
class AppClock {
  AppClock._();

  static Duration _offset = Duration.zero;

  /// Current time adjusted by the server offset.
  /// Use this everywhere instead of [DateTime.now()].
  static DateTime now() => DateTime.now().add(_offset);

  /// Sync the clock offset with the Supabase server.
  /// Call this once during app initialization.
  ///
  /// In release mode, this is a no-op (no network call, no latency).
  static Future<void> syncWithServer() async {
    if (kReleaseMode) return;

    try {
      final response = await SupabaseService.client.rpc('get_server_now');

      final String timeStr;
      if (response is String) {
        timeStr = response;
      } else if (response is List && response.isNotEmpty) {
        timeStr = response.first.toString();
      } else {
        timeStr = response.toString();
      }

      final serverNow = DateTime.parse(timeStr);
      _offset = serverNow.difference(DateTime.now());
      debugPrint('[AppClock] serverNow=$serverNow, offset=$_offset');
    } catch (e) {
      debugPrint('[AppClock] sync failed: $e');
      _offset = Duration.zero;
    }
  }

  /// Reset the clock to device time (offset = 0).
  static void reset() => _offset = Duration.zero;

  /// Taiwan timezone offset (UTC+8, no DST).
  static const _taipeiOffset = Duration(hours: 8);

  /// Convert a UTC DateTime to Taipei local time (UTC+8).
  /// Use this instead of .toLocal() to avoid depending on device timezone.
  static DateTime toTaipei(DateTime dt) {
    return dt.toUtc().add(_taipeiOffset);
  }
}
