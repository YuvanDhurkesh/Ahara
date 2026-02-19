import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  //---------------------------------------------------------
  /// GOOGLE SIGN-IN
  //---------------------------------------------------------

  Future<User?> signInWithGoogle() async {
    try {

      // Trigger Google Sign-In popup
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // User cancelled login
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential =
          await _auth.signInWithCredential(credential);

      return userCredential.user;

    } catch (e, stackTrace) {
      debugPrint("Google Sign-In Error: $e");
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  //---------------------------------------------------------
  /// GOOGLE SIGN-OUT 🔥 (THIS FIXES YOUR ERROR)
  //---------------------------------------------------------

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Clears Google session
    } catch (e, stackTrace) {
      debugPrint("Google Sign-Out Error: $e");
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }
}
