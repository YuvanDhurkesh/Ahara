import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔥 USE IPV4 WHEN TESTING ON PHONE
  //static const String backendBaseUrl = "http://10.12.249.12:5000/api";
  static const String backendBaseUrl = "http://localhost:5000/api";


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
    /// FIRESTORE (optional but fine)
    //-----------------------------------------------------

    await _db.collection('users')
        .doc(user.uid)
        .set({

      "uid": user.uid,
      "name": name,
      "phone": phone,
      "email": email,
      "location": location,
      "role": role,
      "createdAt": Timestamp.now(),

    });

    //-----------------------------------------------------
    /// 🔥 MONGO SYNC
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
    );

    return user;
  }

  //---------------------------------------------------------
  /// GOOGLE LOGIN (AUTH ONLY)
  //---------------------------------------------------------

  Future<User?> handleGoogleLogin(User user) async {

    /// DO NOT CREATE MONGO USER HERE
    /// Instead redirect user to profile completion screen.

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

      /// NEVER crash signup
      print("⚠️ Mongo sync failed: $e");
    }
  }
}
