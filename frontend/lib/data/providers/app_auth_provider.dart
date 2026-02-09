import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';

class AppAuthProvider extends ChangeNotifier {

  //---------------------------------------------------------
  /// SERVICES
  //---------------------------------------------------------

  final AuthService _authService = AuthService();
  final GoogleAuthService _googleService = GoogleAuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //---------------------------------------------------------
  /// STATE
  //---------------------------------------------------------

  bool _loading = false;

  bool get loading => _loading;

  Stream<User?> get authState => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  //---------------------------------------------------------
  /// EMAIL LOGIN
  /// 🔥 IMPORTANT:
  /// Mongo sync SHOULD NOT happen here.
  /// Only Firebase authentication.
  //---------------------------------------------------------

  Future<User?> login(String email, String password) async {

    _setLoading(true);

    try {
      final user = await _authService.login(email, password);
      return user;

    } catch (e) {
      rethrow;

    } finally {
      _setLoading(false);
    }
  }

  //---------------------------------------------------------
  /// REGISTER USER
  /// ✅ Mongo sync happens INSIDE AuthService
  //---------------------------------------------------------

  Future<User?> registerUser({
    required String role,
    required String name,
    required String phone,
    required String email,
    required String password,
    required String location,
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
      );

      return user;

    } catch (e) {
      rethrow;

    } finally {
      _setLoading(false);
    }
  }

  //---------------------------------------------------------
  /// GOOGLE SIGN-IN
  /// 🔥 DO NOT sync Mongo here.
  /// Google users should complete profile first.
  //---------------------------------------------------------

  Future<User?> signInWithGoogle() async {

    _setLoading(true);

    try {

      final user = await _googleService.signInWithGoogle();

      return user;

    } catch (e) {
      rethrow;

    } finally {
      _setLoading(false);
    }
  }
  //---------------------------------------------------------
  /// LOGOUT
  //---------------------------------------------------------

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  
  //---------------------------------------------------------
  /// INTERNAL LOADING HANDLER
  //---------------------------------------------------------

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
