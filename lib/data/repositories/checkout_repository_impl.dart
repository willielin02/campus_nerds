import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/services/supabase_service.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../models/tables/products.dart';

/// Implementation of CheckoutRepository using Supabase
class CheckoutRepositoryImpl implements CheckoutRepository {
  static const String _supabaseUrl = 'https://lzafwlmznlkvmbdxcxop.supabase.co';

  @override
  Future<List<Product>> getProducts(String ticketType) async {
    try {
      final response = await ProductsTable().queryRows(
        queryFn: (q) => q
            .eq('ticket_type', ticketType)
            .eq('is_active', true)
            .order('pack_size'),
      );

      return response.map(_mapRowToProduct).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      final response = await ProductsTable().queryRows(
        queryFn: (q) => q.eq('is_active', true).order('ticket_type').order('pack_size'),
      );

      return response.map(_mapRowToProduct).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<CreateOrderResult> createOrder(String productId) async {
    try {
      final token = SupabaseService.jwtToken;
      if (token == null) {
        return CreateOrderResult.failure('請先登入');
      }

      final response = await http.post(
        Uri.parse('$_supabaseUrl/functions/v1/ecpay_create_order'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'product_id': productId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CreateOrderResult.success(
          orderId: data['order_id'] ?? '',
          checkoutUrl: data['checkout_url'] ?? '',
          checkoutToken: data['checkout_token'],
        );
      } else {
        final errorData = jsonDecode(response.body);
        return CreateOrderResult.failure(
          errorData['error'] ?? '建立訂單失敗',
        );
      }
    } catch (e) {
      return CreateOrderResult.failure('建立訂單失敗，請稍後再試');
    }
  }

  @override
  Future<PaymentHtmlResult> getPaymentHtml(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/functions/v1/ecpay_pay?token=$token'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final html = data['html'] as String?;
        if (html != null && html.isNotEmpty) {
          return PaymentHtmlResult.success(html);
        }
        return PaymentHtmlResult.failure('無法取得付款頁面');
      } else {
        return PaymentHtmlResult.failure('取得付款頁面失敗');
      }
    } catch (e) {
      return PaymentHtmlResult.failure('取得付款頁面失敗，請稍後再試');
    }
  }

  Product _mapRowToProduct(ProductsRow row) {
    return Product(
      id: row.id,
      ticketType: row.ticketType,
      packSize: row.packSize,
      priceTwd: row.priceTwd,
      title: row.title,
      isActive: row.isActive,
      percentOff: row.percentOff,
      unitPriceTwd: row.unitPriceTwd,
    );
  }
}
