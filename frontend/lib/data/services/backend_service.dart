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
    required dynamic location,
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

  static Future<List<dynamic>> getFavoriteListings(String firebaseUid) async {
    final url = Uri.parse("$baseUrl/listings/favorites/$firebaseUid");

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
      throw Exception("Failed to fetch favorite listings");
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

  static Future<Map<String, dynamic>> toggleFavoriteListing({
    required String firebaseUid,
    required String listingId,
  }) async {
    final url = Uri.parse("$baseUrl/users/$firebaseUid/toggle-favorite-listing");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({"listingId": listingId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to toggle favorite");
    }
  }

  static Future<void> updateVolunteerAvailability(
    String firebaseUid,
    bool isAvailable,
  ) async {
    final url = Uri.parse("$baseUrl/users/$firebaseUid/availability");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({"isAvailable": isAvailable}),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        errorBody['error'] ?? "Failed to update availability",
      );
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

  static Future<void> updateSellerProfile({
    required String firebaseUid,
    String? name,
    String? phone,
    String? addressText,
    String? orgName,
    String? fssaiNumber,
    String? pickupHours,
  }) async {
    final url = Uri.parse("$baseUrl/users/$firebaseUid/seller-profile");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({
        if (name != null) "name": name,
        if (phone != null) "phone": phone,
        if (addressText != null) "addressText": addressText,
        if (orgName != null) "orgName": orgName,
        if (fssaiNumber != null) "fssaiNumber": fssaiNumber,
        if (pickupHours != null) "pickupHours": pickupHours,
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to update seller profile");
    }
  }

  static Future<void> updateBuyerProfile({
    required String firebaseUid,
    String? name,
    String? addressText,
    String? gender,
    List<String>? dietaryPreferences,
  }) async {
    final url = Uri.parse("$baseUrl/users/$firebaseUid/buyer-profile");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({
        if (name != null) "name": name,
        if (addressText != null) "addressText": addressText,
        if (gender != null) "gender": gender,
        if (dietaryPreferences != null)
          "dietaryPreferences": dietaryPreferences,
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to update buyer profile");
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

  static Future<List<Map<String, dynamic>>> getActiveListings(
    String sellerId,
  ) async {
    final url = Uri.parse("$baseUrl/listings/active?sellerId=$sellerId");

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

  static Future<void> deleteListing(String id) async {
    final url = Uri.parse("$baseUrl/listings/delete/$id");

    final response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to delete listing");
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

  static Future<List<Map<String, dynamic>>> getVolunteerOrders(
    String volunteerId, {
    String? status,
  }) async {
    final statusQuery = status != null ? "?status=$status" : "";
    final url = Uri.parse("$baseUrl/orders/volunteer/$volunteerId$statusQuery");

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
      throw Exception("Failed to fetch volunteer orders");
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

  static Future<Map<String, dynamic>> verifyOtp(
      String orderId, String otp) async {
    final url = Uri.parse("$baseUrl/orders/$orderId/verify-otp");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({"otp": otp}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Invalid OTP code");
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

  // ========================= REVIEWS =========================

  static Future<void> submitReview({
    required String orderId,
    required String reviewerId,
    required String targetType,
    required String targetUserId,
    required double rating,
    String? comment,
    List<String>? tags,
  }) async {
    final url = Uri.parse("$baseUrl/reviews");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({
        "orderId": orderId,
        "reviewerId": reviewerId,
        "targetType": targetType,
        "targetUserId": targetUserId,
        "rating": rating,
        "comment": comment,
        "tags": tags ?? [],
      }),
    );

    if (response.statusCode != 201) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to submit review");
    }
  }

  // ========================= EMERGENCY =========================

  static Future<void> reportEmergency({
    required String orderId,
    required String volunteerId,
    required double lat,
    required double lng,
    required String reason,
  }) async {
    final url = Uri.parse("$baseUrl/orders/$orderId/emergency");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true",
      },
      body: jsonEncode({
        "volunteerId": volunteerId,
        "lat": lat,
        "lng": lng,
        "reason": reason,
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? "Failed to report emergency");
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

    // Filter out old SVG generator URLs (DiceBear/Placeholder)
    if (imageUrl.contains('dicebear.com') || imageUrl.contains('placeholder.com')) {
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
    // Generate a default real food image URL using LoremFlickr
    final String name = (foodName).toLowerCase();
    
    // Primary mandatory tag is always 'food' to avoid random non-food pics
    final List<String> tags = ["food"];
    
    // Add ONE high-reliability secondary tag
    if (name.contains('chaap') || name.contains('soya')) tags.add('curry');
    else if (name.contains('biryani') || name.contains('rice')) tags.add('rice');
    else if (name.contains('bread') || name.contains('roti') || name.contains('naan')) tags.add('bread');
    else if (name.contains('pasta') || name.contains('noodle')) tags.add('pasta');
    else if (name.contains('pizza')) tags.add('pizza');
    else if (name.contains('burger')) tags.add('burger');
    else if (name.contains('fruit')) tags.add('fruit');
    else if (name.contains('cake') || name.contains('pastry') || name.contains('sweet')) tags.add('dessert');
    else tags.add('meal');

    // Create a consistent lock/seed for the same food item
    final seed = foodName.codeUnits.fold<int>(0, (prev, element) => prev + element) % 1000;
    
    // Using a single tag search for 'food,tag' which acts as (food AND tag)
    // This provides high-quality images and avoids fallback to the cat statue
    return "https://loremflickr.com/800/600/${tags.join(',')}?lock=$seed";
  }
}
