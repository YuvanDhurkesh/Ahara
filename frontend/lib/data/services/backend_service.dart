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

  static Future<Map<String, dynamic>> getUserProfile(
      String firebaseUid) async {
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
    final url =
        Uri.parse("$baseUrl/users/preferences/$firebaseUid");

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

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
          errorBody['error'] ?? "Failed to create listing");
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
      throw Exception(
          errorBody['error'] ?? "Failed to update listing");
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
      throw Exception(
          errorBody['error'] ?? "Failed to relist listing");
    }
  }

  // ========================= UPLOAD =========================

  static Future<String> uploadImage(
      Uint8List bytes, String filename) async {
    final url = Uri.parse("$baseUrl/upload");

    final request =
        http.MultipartRequest("POST", url);

    request.headers.addAll({
      "ngrok-skip-browser-warning": "true",
    });

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
        contentType: MediaType(
          'image',
          filename.split('.').last.toLowerCase(),
        ),
      ),
    );

    try {
      final streamedResponse =
          await request.send();
      final response =
          await http.Response.fromStream(
              streamedResponse);

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body);
        return data['imageUrl'];
      } else {
        throw Exception(
            "Upload failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("Upload exception: $e");
      rethrow;
    }
  }

  // ========================= ORDERS =========================

  static Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> orderData) async {
    final url =
        Uri.parse("$baseUrl/orders/create");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode(orderData),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorBody =
          jsonDecode(response.body);
      throw Exception(
          errorBody['error'] ??
              "Failed to create order");
    }
  }

  static Future<void> updateOrderStatus(
      String orderId,
      String status) async {
    final url = Uri.parse(
        "$baseUrl/orders/$orderId/status");

    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({
        "status": status,
      }),
    );

    if (response.statusCode != 200) {
      final errorBody =
          jsonDecode(response.body);
      throw Exception(
          errorBody['error'] ??
              "Failed to update order status");
    }
  }

  static Future<void> cancelOrder(
      String orderId,
      String cancelledBy,
      String reason) async {
    final url = Uri.parse(
        "$baseUrl/orders/$orderId/cancel");

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
      final errorBody =
          jsonDecode(response.body);
      throw Exception(
          errorBody['error'] ??
              "Failed to cancel order");
    }
  }
}
