/// File: auth_service.dart
/// Purpose: Low-level authentication and database synchronization primitives.
/// 
/// Responsibilities:
/// - Manages Firebase Authentication lifecycle (Sign-in/Sign-up)
/// - Orchestrates Firestore and MongoDB profile creation
/// - Implements failure-tolerant backend synchronization
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

/// Infrastructure service for managing user credentials and cross-platform identity.
/// 
/// Features:
/// - Unified registration flow for all user roles (Buyer, Seller, Volunteer)
/// - Integrated Firestore metadata storage for auth persistence
/// - Bearer-token based REST API synchronization
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
    required String location,
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
  /// BACKEND SYNC
  //---------------------------------------------------------

  Future<void> syncUserWithBackend({
    required User user,
    required String role,
    required String name,
    required String phone,
    required String location,
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
        throw Exception("Backend sync failed: ${response.body}");
      }
    } catch (e) {
      // NEVER crash signup
      print("⚠️ Mongo sync failed: $e");
    }
  }
}
