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

  // ========================= LISTINGS =========================

  static Future<void> createListing(
      Map<String, dynamic> listingData) async {
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
      String id, Map<String, dynamic> data) async {
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
      String id, Map<String, dynamic> pickupWindow) async {
    final url = Uri.parse("$baseUrl/listings/relist/$id");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({
        "pickupWindow": pickupWindow,
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to relist listing");
    }
  }

  static Future<List<Map<String, dynamic>>> getSellerListings(
      String sellerId, String status) async {
    final url =
        Uri.parse("$baseUrl/listings/$status?sellerId=$sellerId");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to fetch listings");
    }
  }

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
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
          errorBody['error'] ?? "Failed to fetch active listings");
    }
  }

  static Future<Map<String, dynamic>> getSellerStats(
      String sellerId) async {
    final url =
        Uri.parse("$baseUrl/listings/seller-stats?sellerId=$sellerId");

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
      final errorBody = jsonDecode(response.body);
      throw Exception(
          errorBody['error'] ?? "Failed to fetch dashboard stats");
    }
  }

  // ========================= UPLOAD =========================

  static Future<String> uploadImage(
      Uint8List bytes, String filename) async {
    final url = Uri.parse("$baseUrl/upload");
    final request = http.MultipartRequest("POST", url);

    request.headers.addAll({
      "ngrok-skip-browser-warning": "true",
    });

    final multipartFile = http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: filename,
      contentType:
          MediaType('image', filename.split('.').last.toLowerCase()),
    );

    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response =
        await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['imageUrl'];
    } else {
      debugPrint("UPLOAD FAILED with status: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");
      throw Exception("Failed to upload image");
    }
  }

  static String formatImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;

    final root = baseUrl.replaceAll('/api', '');
    return "$root$path";
  }

  // Order Management Methods
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
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

  static Future<List<Map<String, dynamic>>> getBuyerOrders(String buyerId, {String? status}) async {
    final url = status != null
        ? Uri.parse("$baseUrl/orders/buyer/$buyerId?status=$status")
        : Uri.parse("$baseUrl/orders/buyer/$buyerId");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to fetch buyer orders");
    }
  }

  static Future<List<Map<String, dynamic>>> getSellerOrders(String sellerId, {String? status}) async {
    final url = status != null
        ? Uri.parse("$baseUrl/orders/seller/$sellerId?status=$status")
        : Uri.parse("$baseUrl/orders/seller/$sellerId");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to fetch seller orders");
    }
  }

  static Future<Map<String, dynamic>> updateOrder(String orderId, Map<String, dynamic> updates) async {
    final url = Uri.parse("$baseUrl/orders/$orderId");

    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
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

  static Future<void> cancelOrder(String orderId, String cancelledBy, String reason) async {
    final url = Uri.parse("$baseUrl/orders/$orderId/cancel");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({
        "cancelledBy": cancelledBy,
        "reason": reason,
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to cancel order");
    }
  }

  // --- Volunteer Methods ---

  static Future<List<Map<String, dynamic>>> getVolunteerRescueRequests(String volunteerId) async {
    final url = Uri.parse("$baseUrl/orders/volunteer/requests/$volunteerId");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Failed to fetch rescue requests");
    }
  }

  static Future<Map<String, dynamic>> acceptRescueRequest(String orderId, String volunteerId) async {
    final url = Uri.parse("$baseUrl/orders/$orderId/accept");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({"volunteerId": volunteerId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to accept rescue request");
    }
  }
}
