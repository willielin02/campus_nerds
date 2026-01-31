import 'event.dart';

/// Product entity for ticket purchases
class Product {
  const Product({
    required this.id,
    required this.ticketType,
    required this.packSize,
    required this.priceTwd,
    required this.title,
    required this.isActive,
    this.percentOff = 0,
    this.unitPriceTwd,
  });

  final String id;
  final String ticketType;
  final int packSize;
  final int priceTwd;
  final String title;
  final bool isActive;
  final int percentOff;
  final int? unitPriceTwd;

  /// Check if this is a study ticket product
  bool get isStudyTicket => ticketType == 'study';

  /// Check if this is a games ticket product
  bool get isGamesTicket => ticketType == 'games';

  /// Get the event category for this product
  EventCategory get category =>
      isStudyTicket ? EventCategory.focusedStudy : EventCategory.englishGames;

  /// Get display price with discount info
  String get displayPrice => 'NT\$ $priceTwd';

  /// Check if product has a discount
  bool get hasDiscount => percentOff > 0;

  /// Get discount label (e.g., "20% OFF")
  String get discountLabel => hasDiscount ? '$percentOff% OFF' : '';
}

/// Order status enum
enum OrderStatus {
  pending('pending'),
  paid('paid'),
  cancelled('cancelled'),
  refunded('refunded');

  const OrderStatus(this.value);
  final String value;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Order entity for tracking purchases
class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.productId,
    required this.merchantTradeNo,
    required this.ticketTypeSnapshot,
    required this.packSizeSnapshot,
    required this.titleSnapshot,
    required this.priceSnapshotTwd,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
  });

  final String id;
  final String userId;
  final String productId;
  final String merchantTradeNo;
  final String ticketTypeSnapshot;
  final int packSizeSnapshot;
  final String titleSnapshot;
  final int priceSnapshotTwd;
  final int totalAmount;
  final String currency;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;

  /// Check if order is paid
  bool get isPaid => status == OrderStatus.paid;

  /// Check if order is pending payment
  bool get isPending => status == OrderStatus.pending;
}

/// Result of creating an order
class CreateOrderResult {
  const CreateOrderResult._({
    required this.success,
    this.orderId,
    this.checkoutUrl,
    this.checkoutToken,
    this.errorMessage,
  });

  final bool success;
  final String? orderId;
  final String? checkoutUrl;
  final String? checkoutToken;
  final String? errorMessage;

  factory CreateOrderResult.success({
    required String orderId,
    required String checkoutUrl,
    String? checkoutToken,
  }) =>
      CreateOrderResult._(
        success: true,
        orderId: orderId,
        checkoutUrl: checkoutUrl,
        checkoutToken: checkoutToken,
      );

  factory CreateOrderResult.failure(String message) => CreateOrderResult._(
        success: false,
        errorMessage: message,
      );
}

/// Result of getting payment HTML
class PaymentHtmlResult {
  const PaymentHtmlResult._({
    required this.success,
    this.html,
    this.errorMessage,
  });

  final bool success;
  final String? html;
  final String? errorMessage;

  factory PaymentHtmlResult.success(String html) => PaymentHtmlResult._(
        success: true,
        html: html,
      );

  factory PaymentHtmlResult.failure(String message) => PaymentHtmlResult._(
        success: false,
        errorMessage: message,
      );
}
