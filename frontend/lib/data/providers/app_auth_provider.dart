import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/backend_service.dart';

class AppAuthProvider extends ChangeNotifier {

  //---------------------------------------------------------
  /// SERVICES
  //---------------------------------------------------------

  final AuthService _authService = AuthService();
  final GoogleAuthService _googleService = GoogleAuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppAuthProvider() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await refreshMongoUser();
      } else {
        _mongoUser = null;
        _mongoProfile = null;
        notifyListeners();
      }
    });
  }

  //---------------------------------------------------------
  /// STATE
  //---------------------------------------------------------

  bool _loading = false;
  bool get loading => _loading;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Map<String, dynamic>? _mongoUser;
  Map<String, dynamic>? get mongoUser => _mongoUser;

  Map<String, dynamic>? _mongoProfile;
  Map<String, dynamic>? get mongoProfile => _mongoProfile;

  //---------------------------------------------------------
  /// GOOGLE SIGN-IN
  //---------------------------------------------------------

  Future<User?> signInWithGoogle() async {
    _setLoading(true);

    try {
      final user = await _googleService.signInWithGoogle();

      if (user == null) return null;

      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // 🔥 Safe merge to avoid overwrite issues
      await docRef.set({
        "firebaseUid": user.uid,
        "name": user.displayName ?? "User",
        "email": user.email ?? "",
        "role": "buyer",
        "phone": "",
        "location": "",
        "language": "en",
        "uiMode": "light",
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await refreshMongoUser();

      return user;

    } catch (e, stackTrace) {
      debugPrint("Google Sign-In Error: $e");
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  //---------------------------------------------------------
  /// EMAIL LOGIN
  //---------------------------------------------------------

  Future<User?> login(String email, String password) async {
    _setLoading(true);

    try {
      final user = await _authService.login(email, password);
      if (user != null) {
        await refreshMongoUser();
      }
      return user;
    } catch (e, stackTrace) {
      debugPrint("Email Login Error: $e");
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  //---------------------------------------------------------
  /// REGISTER USER
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
  }) async {
    _setLoading(true);

    try {
      final user = await _authService.registerUser(
        role: role,
        name: name,
        phone: phone,
        email: email,
        password: password,
        location: location,
        businessName: businessName,
        businessType: businessType,
        fssaiNumber: fssaiNumber,
        transportMode: transportMode,
        dateOfBirth: dateOfBirth,
        language: language,
      );

      if (user != null) {
        await refreshMongoUser();
      }

      return user;
    } catch (e, stackTrace) {
      debugPrint("Register Error: $e");
      debugPrint(stackTrace.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  //---------------------------------------------------------
/// GET USER ROLE FROM FIRESTORE
//---------------------------------------------------------

Future<String?> getUserRole(String uid) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      return doc.data()?['role'];
    }

    return null;
  } catch (e, stackTrace) {
    debugPrint("GetUserRole Error: $e");
    debugPrint(stackTrace.toString());
    return null;
  }
}


  //---------------------------------------------------------
  /// REFRESH MONGO USER
  //---------------------------------------------------------

  Future<void> refreshMongoUser() async {
    if (currentUser == null) return;

    try {
      final data =
          await BackendService.getUserProfile(currentUser!.uid);

      _mongoUser = data['user'];
      _mongoProfile = data['profile'];

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint("Mongo Fetch Error: $e");
      debugPrint(stackTrace.toString());
    }
  }

  //---------------------------------------------------------
  /// LOGOUT
  //---------------------------------------------------------

  Future<void> logout() async {
    try {
      await _googleService.signOut(); // 🔥 important
      await _auth.signOut();

      _mongoUser = null;
      _mongoProfile = null;

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint("Logout Error: $e");
      debugPrint(stackTrace.toString());
    }
  }

  //---------------------------------------------------------
  /// LOADING HANDLER
  //---------------------------------------------------------

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
