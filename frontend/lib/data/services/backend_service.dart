import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class BackendService {
  /// ⚠️ UPDATED: Added /api and removed trailing slash
  static const String baseUrl = "https://52d6-2405-201-e015-e079-552b-9e41-e783-debe.ngrok-free.app/api";

  static Future<void> createUser({
    required String firebaseUID,
    required String name,
    required String email,
    required String role,
    required String phone,
    required String location,
  }) async {
    final url = Uri.parse("$baseUrl/users/create");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true", // Required for ngrok
      },
      body: jsonEncode({
        "firebaseUID": firebaseUID,
        "name": name,
        "email": email,
        "role": role,
        "phone": phone,
        "location": location,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to create Mongo user");
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

  static Future<void> updateListing(String id, Map<String, dynamic> data) async {
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

  static Future<List<Map<String, dynamic>>> getSellerListings(
      String sellerId, String status) async {
    // status should be 'active', 'expired', or 'completed'
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

  static Future<String> uploadImage(Uint8List bytes, String filename) async {
    final url = Uri.parse("$baseUrl/upload");
    final request = http.MultipartRequest("POST", url);

    request.headers.addAll({
      "ngrok-skip-browser-warning": "true",
    });

    final multipartFile = http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: filename,
      contentType: MediaType('image', filename.split('.').last.toLowerCase()),
    );

    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

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
    
    // Remote the /api from baseUrl to get the root
    final root = baseUrl.replaceAll('/api', '');
    return "$root$path";
  }
}
