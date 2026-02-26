import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme_config.dart';
import 'features/common/pages/landing_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/language_provider.dart';
import 'core/localization/app_localizations.dart';
import 'features/buyer/pages/buyer_dashboard_page.dart';
import 'features/seller/pages/seller_dashboard_page.dart';
import 'features/volunteer/pages/volunteer_dashboard_page.dart';
import 'features/auth/pages/login_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'data/providers/app_auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/services/voice_service.dart';
import 'data/services/backend_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 LOAD ENV FILE FIRST
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => VoiceService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      title: 'Ahara',
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.lightTheme,
      locale: languageProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('ta'),
        Locale('te'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthWrapper(),
    );
  }
}

/// 🔥 AUTH WRAPPER
/// Controls app entry based on login state

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) return null;

    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    // 1. Check if we already have a Mongo user (either via Phone login or Firebase sync)
    if (auth.mongoUser != null) {
      final role = auth.mongoUser!['role'];
      
      // Auto-sync preferences if needed
      final language = auth.mongoUser!['language'];
      final uiMode = auth.mongoUser!['uiMode'];

      if (language != null || uiMode != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final lp = Provider.of<LanguageProvider>(context, listen: false);
          if (language != null && lp.locale.languageCode != language) {
            lp.setLanguage(language, isManual: false);
          }
          if (uiMode != null && lp.uiMode != uiMode) {
            lp.setUiMode(uiMode, isManual: false);
          }
        });
      }

      if (role == "seller") {
        return const SellerDashboardPage();
      } else if (role == "volunteer") {
        return const VolunteerDashboardPage();
      } else if (role == "buyer") {
        return const BuyerDashboardPage();
      }
    }

    // 2. If no Mongo user, check Firebase state
    return StreamBuilder<User?>(
      stream: auth.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If Firebase is null and we don't have a phone session (checked above), show Landing
        if (!snapshot.hasData) {
          return const LandingPage();
        }

        // 3. Fallback: Firebase user exists but Mongo not loaded yet
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Loading profile..."),
              ],
            ),
          ),
        );
      },
    );
  }
}
