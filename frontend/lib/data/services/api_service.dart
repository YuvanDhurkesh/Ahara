import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// API Service for backend communication
class ApiService {
	static const String baseUrl = 'http://localhost:3000'; // TODO: Set via config/env for prod

	/// Calls backend /api/auth/login with Firebase ID token
	static Future<Map<String, dynamic>> loginWithBackend() async {
		final user = FirebaseAuth.instance.currentUser;
		if (user == null) throw Exception('Not logged in');
		final idToken = await user.getIdToken();

		final response = await http.post(
			Uri.parse('$baseUrl/api/auth/login'),
			headers: {
				'Content-Type': 'application/json',
				'Authorization': 'Bearer $idToken',
			},
		);

		if (response.statusCode != 200) {
			throw Exception('Backend login failed: ${response.body}');
		}
		return json.decode(response.body);
	}
}
