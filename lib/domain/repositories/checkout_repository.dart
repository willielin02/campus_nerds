import '../entities/checkout.dart';

/// Abstract repository for checkout operations
abstract class CheckoutRepository {
  /// Get products by ticket type ('study' or 'games')
  Future<List<Product>> getProducts(String ticketType);

  /// Get all active products
  Future<List<Product>> getAllProducts();

  /// Create an order and get checkout URL
  /// Calls the ecpay_create_order edge function
  Future<CreateOrderResult> createOrder(String productId);

  /// Get payment HTML for WebView rendering
  /// Calls the ecpay_pay edge function with checkout token
  Future<PaymentHtmlResult> getPaymentHtml(String token);
}
