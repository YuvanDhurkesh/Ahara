import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class GamificationService {
  final String baseUrl = '${ApiConfig.baseUrl}/users'; // Use Centralized Config

  Future<Map<String, dynamic>> getGamificationProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/profile/$userId'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load gamification profile');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<void> addPoints(String userId, String actionType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/points/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'actionType': actionType,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add points');
      }
    } catch (e) {
      throw Exception('Error adding points: $e');
    }
  }
}
