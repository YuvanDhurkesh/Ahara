import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentRepository {
  final String _baseUrl = 'http://aharabackend-env.eba-nn8ggm5m.ap-south-1.elasticbeanstalk.com/api';

  /// Create Razorpay Order on Backend
  Future<Map<String, dynamic>> createOrder({
    required double amount,
    required String receipt,
    String currency = 'INR',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'receipt': receipt,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Backend error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Verify Payment Signature with Backend
  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
}
