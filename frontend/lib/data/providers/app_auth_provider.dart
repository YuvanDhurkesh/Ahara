import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool loading = false;

  Stream<User?> get authState => FirebaseAuth.instance.authStateChanges();

  /// LOGIN
  Future<Map<String, dynamic>?> login(String email, String password) async {
    loading = true;
    notifyListeners();

    try {
      final user = await _service.login(email, password);
      if (user != null) {
        final userData = await _service.getUserData(user.uid);
        return userData;
      }
      return null;
    } catch (e) {
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// FETCH ROLE
  Future<String?> getUserRole(String uid) async {
    final data = await _service.getUserData(uid);
    return data?['role'];
  }

  /// REGISTER (ROLE BASED)
  Future<User?> registerUser({
    required String role,
    required String name,
    required String phone,
    required String email,
    required String password,
    required String location,
  }) async {
    loading = true;
    notifyListeners();

    try {
      final user = await _service.registerUser(
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
      loading = false;
      notifyListeners();
    }
  }
}
