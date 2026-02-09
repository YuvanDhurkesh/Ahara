import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme_config.dart';
import 'features/common/pages/landing_page.dart';
import 'package:provider/provider.dart';
import 'data/providers/app_auth_provider.dart';
import 'data/providers/app_auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/buyer/pages/buyer_dashboard_page.dart';

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

  Future<String?> getUserRole(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) return null;

    return doc['role'];
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

        /// LOGGED IN → FETCH ROLE
        return FutureBuilder<String?>(
          future: getUserRole(snapshot.data!.uid),
          builder: (context, roleSnap) {

            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final role = roleSnap.data;

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
