/// Reason for ticket ledger entry
enum TicketLedgerReason {
  purchaseCredit('purchase_credit'),
  bookingDebit('booking_debit'),
  bookingRefund('booking_refund'),
  adminAdjust('admin_adjust');

  const TicketLedgerReason(this.value);
  final String value;

  static TicketLedgerReason fromString(String value) {
    return TicketLedgerReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TicketLedgerReason.adminAdjust,
    );
  }

  /// Get Chinese display text for the reason
  String get displayText {
    switch (this) {
      case TicketLedgerReason.purchaseCredit:
        return '購買票券';
      case TicketLedgerReason.bookingDebit:
        return '報名活動';
      case TicketLedgerReason.bookingRefund:
        return '取消報名';
      case TicketLedgerReason.adminAdjust:
        return '管理員調整';
    }
  }
}

/// Ticket history entry entity
class TicketHistoryEntry {
  const TicketHistoryEntry({
    required this.id,
    required this.userId,
    required this.deltaStudy,
    required this.deltaGames,
    required this.reason,
    required this.createdAt,
    this.orderId,
    this.bookingId,
    this.orderDetail,
    this.bookingDetail,
  });

  final String id;
  final String userId;
  final String? orderId;
  final String? bookingId;
  final int deltaStudy;
  final int deltaGames;
  final TicketLedgerReason reason;
  final DateTime createdAt;

  /// Order details for purchase_credit entries
  final TicketOrderDetail? orderDetail;

  /// Booking details for booking_debit/refund entries
  final TicketBookingDetail? bookingDetail;

  /// Check if this is a study ticket entry
  bool get isStudyEntry => deltaStudy != 0;

  /// Check if this is a games ticket entry
  bool get isGamesEntry => deltaGames != 0;

  /// Get the delta value (positive for credit, negative for debit)
  int get delta => isStudyEntry ? deltaStudy : deltaGames;

  /// Get formatted description based on reason
  String get description {
    switch (reason) {
      case TicketLedgerReason.purchaseCredit:
        if (orderDetail != null) {
          final ticketType =
              orderDetail!.ticketType == 'study' ? 'Study票券' : 'Games票券';
          return '購買 $ticketType ${orderDetail!.packSize} 張';
        }
        return '購買票券';
      case TicketLedgerReason.bookingDebit:
        if (bookingDetail != null) {
          return '報名 ${bookingDetail!.cityName} ${bookingDetail!.formattedDate} 活動\n地點：${bookingDetail!.locationDetailText}';
        }
        return '報名活動';
      case TicketLedgerReason.bookingRefund:
        if (bookingDetail != null) {
          return '取消 ${bookingDetail!.cityName} ${bookingDetail!.formattedDate} 活動\n地點：${bookingDetail!.locationDetailText}';
        }
        return '取消報名';
      case TicketLedgerReason.adminAdjust:
        return '管理員調整';
    }
  }
}

/// Order detail for purchase entries
class TicketOrderDetail {
  const TicketOrderDetail({
    required this.ticketType,
    required this.packSize,
    required this.priceTwd,
    required this.title,
  });

  final String ticketType;
  final int packSize;
  final int priceTwd;
  final String title;
}

/// Booking detail for booking entries
class TicketBookingDetail {
  const TicketBookingDetail({
    required this.eventId,
    required this.eventDate,
    required this.timeSlot,
    required this.cityId,
    required this.cityName,
    required this.locationDetail,
    required this.category,
  });

  final String eventId;
  final DateTime eventDate;
  final String timeSlot;
  final String cityId;
  final String cityName;
  final String locationDetail;
  final String category;

  /// Get formatted date string
  String get formattedDate {
    final month = eventDate.month;
    final day = eventDate.day;
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final weekday = weekdays[eventDate.weekday - 1];
    return '$month 月 $day 日 ($weekday)';
  }

  /// Map location_detail enum to Chinese text
  /// Using same mapping as event_card.dart for consistency
  String get locationDetailText {
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
}
