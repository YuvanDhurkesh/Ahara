import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class OrderService {
  final String baseUrl = '${ApiConfig.baseUrl}/orders'; // Use Centralized Config

  // 1. Create Order (Buyer)
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create order: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  // 2. Get Open Orders (Volunteer)
  Future<List<dynamic>> getOpenOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/open'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch open orders');
      }
    } catch (e) {
      throw Exception('Error fetching open orders: $e');
    }
  }

  // 3. Accept Order (Volunteer)
  Future<void> acceptOrder(String orderId, String volunteerId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$orderId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'volunteerId': volunteerId}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to accept order');
      }
    } catch (e) {
      throw Exception('Error accepting order: $e');
    }
  }

  // 4. Confirm Delivery (Buyer) -> Triggers Gamification
  Future<void> confirmDelivery(String orderId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$orderId/confirm'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to confirm delivery');
      }
    } catch (e) {
      throw Exception('Error confirming delivery: $e');
    }
  }
  // 5. Get My Orders (Buyer/Volunteer)
  Future<List<dynamic>> getUserOrders(String userId, String role) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-orders?userId=$userId&role=$role'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch user orders');
      }
    } catch (e) {
      throw Exception('Error fetching user orders: $e');
    }
  }
}
