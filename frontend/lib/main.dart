// Ahara Flutter App
//
// Authentication: Uses Firebase Auth for secure client login.
// User roles/trustScore: Fetched from backend (Node.js + MongoDB) after login.
//
// SECURITY: No backend logic or secrets in Flutter. No Firebase Admin or DB access here.
// See backend/README.md for more details.
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme_config.dart';
import 'features/common/pages/landing_page.dart';
import 'package:provider/provider.dart';
import 'data/providers/app_auth_provider.dart';
import 'data/providers/app_auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/buyer/pages/buyer_dashboard_page.dart';
import 'data/services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppAuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ahara',
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

/// 🔥 AUTH WRAPPER
/// Controls app entry based on login state

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});


  /// Fetch user profile from backend (roles, trustScore, etc)
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final profile = await ApiService.loginWithBackend();
      return profile;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: context.read<AppAuthProvider>().authState,
      builder: (context, snapshot) {

        /// Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        /// NOT LOGGED IN
        if (!snapshot.hasData) {
          return const LandingPage();
        }

        /// LOGGED IN → FETCH PROFILE FROM BACKEND
        return FutureBuilder<Map<String, dynamic>?>(
          future: getUserProfile(),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final profile = profileSnap.data;
            final roles = profile?['roles'] as List?;
            final role = (roles != null && roles.isNotEmpty) ? roles.first : null;

            //------------------------------------------------
            // ROLE ROUTING
            //------------------------------------------------

            if (role == "buyer") {
              return const BuyerDashboardPage();
            }

            /// Temporarily route others to landing
            return const LandingPage();
          },
        );
      },
    );
  }
}
