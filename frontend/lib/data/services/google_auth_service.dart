/// File: google_auth_service.dart
/// Purpose: OAuth2 integration for Google identity providers.
/// 
/// Responsibilities:
/// - Manages [GoogleSignIn] lifecycle and credential acquisition
/// - Orchestrates token exchange for Firebase Authentication
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Encapsulates Google-specific authentication logic and token management.
/// 
/// Features:
/// - Reactive popup handling for multi-platform environments
/// - Transparent mapping from OAuth2 tokens to Firebase credentials
class GoogleAuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  Future<User?> signInWithGoogle() async {

    try {

      // Trigger popup
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // user cancelled
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase login
      final userCredential =
          await _auth.signInWithCredential(credential);

      return userCredential.user;

    } catch (e) {
      print("Google Sign-In Error: $e");
      rethrow;
    }
  }
}
