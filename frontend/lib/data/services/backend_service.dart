import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {

  /// ⚠️ USE YOUR LOCAL IP — NOT localhost
  static const String baseUrl = "http://10.12.249.122:5000/api";

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
}
