import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../config/api_config.dart';

class BackendService {
  static String get baseUrl => ApiConfig.baseUrl;

  // ========================= USER =========================

  static Future<void> createUser({
    required String firebaseUid,
    required String name,
    required String email,
    required String role,
    required String phone,
    required String location,
    String? language,
  }) async {
    final url = Uri.parse("$baseUrl/users/create");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({
        "firebaseUid": firebaseUid,
        "name": name,
        "email": email,
        "role": role,
        "phone": phone,
        "location": location,
        if (language != null) "language": language,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to create Mongo user");
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String firebaseUid) async {
    final url = Uri.parse("$baseUrl/users/firebase/$firebaseUid");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch user profile");
    }
  }

  static Future<void> updateUserPreferences({
    required String firebaseUid,
    String? language,
    String? uiMode,
  }) async {
    final url = Uri.parse("$baseUrl/users/preferences/$firebaseUid");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({
        if (language != null) "language": language,
        if (uiMode != null) "uiMode": uiMode,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update user preferences");
    }
  }

  static Future<void> updateVolunteerProfile({
    required String firebaseUid,
    required String transportMode,
    String? name,
    String? phone,
    String? addressText,
  }) async {
    final url = Uri.parse("$baseUrl/users/$firebaseUid/volunteer-profile");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({
        "transportMode": transportMode,
        if (name != null) "name": name,
        if (phone != null) "phone": phone,
        if (addressText != null) "addressText": addressText,
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['error'] ?? "Failed to update volunteer profile",
      );
    }
  }

  // ========================= LISTINGS =========================

  static Future<List<Map<String, dynamic>>> getAllActiveListings() async {
    final url = Uri.parse("$baseUrl/listings/active");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('listings')) {
        return List<Map<String, dynamic>>.from(data['listings']);
      }
      return [];
    } else {
      throw Exception("Failed to fetch active listings");
    }
  }

  static Future<List<Map<String, dynamic>>> getSellerListings(
    String sellerId,
    String status,
  ) async {
    final url = Uri.parse("$baseUrl/listings/$status?sellerId=$sellerId");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('listings')) {
        return List<Map<String, dynamic>>.from(data['listings']);
      }
      return [];
    } else {
      throw Exception("Failed to fetch $status listings");
    }
  }

  static Future<Map<String, dynamic>> getSellerStats(String sellerId) async {
    final url = Uri.parse("$baseUrl/listings/seller-stats?sellerId=$sellerId");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch seller stats");
    }
  }

  static Future<void> createListing(Map<String, dynamic> listingData) async {
    final url = Uri.parse("$baseUrl/listings/create");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode(listingData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to create listing");
    }
  }

  static Future<void> updateListing(
    String id,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse("$baseUrl/listings/update/$id");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to update listing");
    }
  }

  static Future<void> relistListing(
    String id,
    Map<String, dynamic> pickupWindow,
  ) async {
    final url = Uri.parse("$baseUrl/listings/relist/$id");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({"pickupWindow": pickupWindow}),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to relist listing");
    }
  }

  // ========================= UPLOAD =========================

  static Future<String> uploadImage(Uint8List bytes, String filename) async {
    final url = Uri.parse("$baseUrl/upload");

    final request = http.MultipartRequest("POST", url);

    request.headers.addAll({"ngrok-skip-browser-warning": "true"});

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
        contentType: MediaType('image', filename.split('.').last.toLowerCase()),
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['imageUrl'];
      } else {
        throw Exception("Upload failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("Upload exception: $e");
      rethrow;
    }
  }

  // ========================= ORDERS =========================

  static Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> orderData,
  ) async {
    final url = Uri.parse("$baseUrl/orders/create");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode(orderData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to create order");
    }
  }

  static Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final url = Uri.parse("$baseUrl/orders/$orderId");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch order");
    }
  }

  static Future<List<Map<String, dynamic>>> getBuyerOrders(
    String buyerId,
  ) async {
    final url = Uri.parse("$baseUrl/orders/buyer/$buyerId");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('orders')) {
        return List<Map<String, dynamic>>.from(data['orders']);
      }
      return [];
    } else {
      throw Exception("Failed to fetch buyer orders");
    }
  }

  static Future<List<Map<String, dynamic>>> getSellerOrders(
    String sellerId,
  ) async {
    final url = Uri.parse("$baseUrl/orders/seller/$sellerId");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('orders')) {
        return List<Map<String, dynamic>>.from(data['orders']);
      }
      return [];
    } else {
      throw Exception("Failed to fetch seller orders");
    }
  }

  static Future<List<Map<String, dynamic>>> getVolunteerRescueRequests(
    String volunteerId,
  ) async {
    final url = Uri.parse("$baseUrl/orders/volunteer/requests/$volunteerId");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data.containsKey('requests')) {
        return List<Map<String, dynamic>>.from(data['requests']);
      }
      return [];
    } else {
      throw Exception("Failed to fetch rescue requests");
    }
  }

  static Future<void> acceptRescueRequest(
    String requestId,
    String volunteerId,
  ) async {
    final url = Uri.parse("$baseUrl/orders/$requestId/accept");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({"volunteerId": volunteerId}),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to accept rescue request");
    }
  }

  static Future<void> updateOrder(
    String orderId,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse("$baseUrl/orders/$orderId");

    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to update order");
    }
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    final url = Uri.parse("$baseUrl/orders/$orderId/status");

    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({"status": status}),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to update order status");
    }
  }

  static Future<void> cancelOrder(
    String orderId,
    String cancelledBy,
    String reason,
  ) async {
    final url = Uri.parse("$baseUrl/orders/$orderId/cancel");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({"cancelledBy": cancelledBy, "reason": reason}),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to cancel order");
    }
  }

  // ========================= IMAGE UTILITIES =========================

  static String formatImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return generateFoodImageUrl("food");
    }

    // If it's already a full HTTP/HTTPS URL, return as is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // If it's a relative path, prepend the base URL
    if (imageUrl.startsWith('/')) {
      return "$baseUrl$imageUrl";
    }

    // Otherwise, prepend base URL with /uploads/
    return "$baseUrl/uploads/$imageUrl";
  }

  static bool isValidImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return false;
    }

    try {
      Uri.parse(imageUrl);
      return imageUrl.startsWith('http://') ||
          imageUrl.startsWith('https://') ||
          imageUrl.startsWith('/');
    } catch (e) {
      return false;
    }
  }

  static String generateFoodImageUrl(String foodName) {
    // Generate a placeholder image URL using a food image service
    // Using a simple approach with emoji representation
    final encodedName = Uri.encodeComponent(foodName);
    return "https://via.placeholder.com/300?text=${encodedName.replaceAll('%20', '+')}";
  }
}
