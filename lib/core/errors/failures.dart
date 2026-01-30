import 'package:equatable/equatable.dart';

/// Base class for all failures in the app
///
/// Failures represent expected errors that can be handled gracefully.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Server-side failure (API errors, database errors)
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = '伺服器發生錯誤，請稍後再試',
    super.code,
  });
}

/// Network failure (no internet, timeout)
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = '網路連線失敗，請檢查網路設定',
    super.code,
  });
}

/// Cache/storage failure
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = '讀取本地資料失敗',
    super.code,
  });
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = '驗證失敗，請重新登入',
    super.code,
  });
}

/// Validation failure (form validation, business rules)
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
  });
}

/// Payment failure
class PaymentFailure extends Failure {
  const PaymentFailure({
    super.message = '付款失敗，請重試或選擇其他付款方式',
    super.code,
  });
}

/// Booking failure
class BookingFailure extends Failure {
  const BookingFailure({
    required super.message,
    super.code,
  });

  /// Insufficient tickets
  factory BookingFailure.insufficientTickets(String ticketType) {
    final type = ticketType == 'study' ? '自習' : '遊戲';
    return BookingFailure(
      message: '$type票券餘額不足，請先購買票券',
      code: 'insufficient_tickets',
    );
  }

  /// Event full
  factory BookingFailure.eventFull() {
    return const BookingFailure(
      message: '活動已額滿，請選擇其他場次',
      code: 'event_full',
    );
  }

  /// Already booked
  factory BookingFailure.alreadyBooked() {
    return const BookingFailure(
      message: '您已報名此活動',
      code: 'already_booked',
    );
  }

  /// Booking closed
  factory BookingFailure.closed() {
    return const BookingFailure(
      message: '報名已截止',
      code: 'booking_closed',
    );
  }

  /// Conflict with same time slot
  factory BookingFailure.conflictSameSlot() {
    return const BookingFailure(
      message: '您已報名同一時段的其他活動',
      code: 'conflict_same_slot',
    );
  }
}

/// Permission failure
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = '您沒有權限執行此操作',
    super.code,
  });
}

/// Unknown/unexpected failure
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = '發生未預期的錯誤',
    super.code,
  });
}
