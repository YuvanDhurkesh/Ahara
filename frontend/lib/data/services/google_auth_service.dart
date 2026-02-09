import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {

    /// Trigger Google popup
    final GoogleSignInAccount? googleUser =
        await _googleSignIn.signIn();

    if (googleUser == null) {
      return null; // user cancelled
    }

    /// Get auth details
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    /// Create credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    /// Firebase login
    final userCredential =
        await _auth.signInWithCredential(credential);

    return userCredential.user;
  }
}
