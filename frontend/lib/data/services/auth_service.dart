import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';



class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get backendBaseUrl => ApiConfig.baseUrl;

  //---------------------------------------------------------
  /// LOGIN (NO MONGO CALL)
  //---------------------------------------------------------

  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return cred.user;
  }

  //---------------------------------------------------------
  /// REGISTER (ONLY PLACE WE CREATE MONGO USER)
  //---------------------------------------------------------

  Future<User?> registerUser({
    required String role,
    required String name,
    required String phone,
    required String email,
    required String password,
    required dynamic location,
    String? businessName,
    String? businessType,
    String? fssaiNumber,
    String? transportMode,
    String? dateOfBirth,
    String? language,
    String? uiMode,
  }) async {
    //-----------------------------------------------------
    /// CREATE FIREBASE USER
    //-----------------------------------------------------

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user!;
    await user.updateDisplayName(name);

    //-----------------------------------------------------
    /// FIRESTORE SAVE
    //-----------------------------------------------------

    await _db.collection('users').doc(user.uid).set({
      "uid": user.uid,
      "name": name,
      "phone": phone,
      "email": email,
      "location": location,
      "role": role,
      "language": language ?? "en",
      "uiMode": uiMode ?? "standard",
      "createdAt": Timestamp.now(),
    });

    //-----------------------------------------------------
    /// MONGO SYNC
    //-----------------------------------------------------

    await syncUserWithBackend(
      user: user,
      role: role,
      name: name,
      phone: phone,
      location: location,
      businessName: businessName,
      businessType: businessType,
      fssaiNumber: fssaiNumber,
      transportMode: transportMode,
      dateOfBirth: dateOfBirth,
      language: language,
      uiMode: uiMode,
    );

    return user;
  }

  //---------------------------------------------------------
  /// GOOGLE LOGIN (AUTH ONLY)
  //---------------------------------------------------------

  Future<User?> handleGoogleLogin(User user) async {
    // DO NOT create Mongo user here
    return user;
  }

  //---------------------------------------------------------
  /// OTP SERVICES
  //---------------------------------------------------------

  Future<Map<String, dynamic>> sendOtpSync(String phoneNumber) async {
    final response = await http.post(
      Uri.parse("$backendBaseUrl/otp/send"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phoneNumber": phoneNumber}),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      String errorMessage = errorData['error'] ?? "Failed to send OTP";
      
      // Special handling for Twilio Trial restrictions
      if (errorData['isTrialError'] == true) {
         errorMessage = "Twilio Trial: Go to Twilio console and verify this number as a Caller ID!";
      }
      
      throw Exception(errorMessage);
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> verifyOtpSync(String phoneNumber, String otp) async {
    final response = await http.post(
      Uri.parse("$backendBaseUrl/otp/verify"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phoneNumber": phoneNumber, "otp": otp}),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error'] ?? "Verification failed");
    }

    return jsonDecode(response.body);
  }

  //---------------------------------------------------------
  /// BACKEND SYNC
  //---------------------------------------------------------

  Future<void> syncUserWithBackend({
    required User user,
    required String role,
    required String name,
    required String phone,
    required dynamic location,
    String? businessName,
    String? businessType,
    String? fssaiNumber,
    String? transportMode,
    String? dateOfBirth,
    String? language,
    String? uiMode,
  }) async {
    try {
      final token = await user.getIdToken();
      
      final response = await http.post(
        Uri.parse("$backendBaseUrl/users/create"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "firebaseUid": user.uid,
          "email": user.email,
          "name": name,
          "role": role,
          "phone": phone,
          "location": location,
          if (language != null) "language": language,
          if (uiMode != null) "uiMode": uiMode,
          if (businessName != null) "businessName": businessName,
          if (businessType != null) "businessType": businessType,
          if (fssaiNumber != null) "fssaiNumber": fssaiNumber,
          if (transportMode != null) "transportMode": transportMode,
          if (dateOfBirth != null) "dateOfBirth": dateOfBirth,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print("❌ Backend sync error: Status ${response.statusCode}");
        print("Response body: ${response.body}");
        throw Exception("Backend sync failed: ${response.body}");
      }
      print("✅ Backend sync successful for user: ${user.uid}");
    } catch (e) {
      print("⚠️ Mongo sync failed: $e");
      // Don't crash signup, but log the error
      rethrow; // Allow caller to handle if needed
    }
  }
}
