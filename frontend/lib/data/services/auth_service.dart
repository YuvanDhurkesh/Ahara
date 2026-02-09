import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// LOGIN
  Future<User?> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return cred.user;
  }

  /// REGISTER USER (ROLE BASED)
  Future<User?> registerUser({
    required String role,
    required String name,
    required String phone,
    required String email,
    required String password,
    required String location,
  }) async {
    /// Create Auth Account
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    /// Store User Metadata in Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      "uid": cred.user!.uid,
      "name": name,
      "phone": phone,
      "email": email,
      "location": location,
      "role": role,
      "createdAt": Timestamp.now(),
    });

    return cred.user;
  }

  /// FETCH USER DATA (ROLE/METADATA)
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
}
