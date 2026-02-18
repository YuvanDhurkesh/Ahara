/// File: main.dart
/// Purpose: Application entry point and root orchestration.
/// 
/// Responsibilities:
/// - Initializes Firebase and Environment variables
/// - Configures global Dependency Injection (MultiProvider)
/// - Manages top-level Auth Guarding (AuthWrapper)
/// - Handles application-wide localization and themes
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

/// Root application widget.
/// 
/// Logic:
/// - Injects global theme and locale configuration
/// - Defines supported locales and localization delegates
/// - Wraps the app with [AuthWrapper] for state-driven routing
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

/// Top-level authentication guard and role-based router.
/// 
/// Responsibility:
/// - Listens to [AppAuthProvider] for login state changes
/// - Fetches extended MongoDB user metadata (Role, Language)
/// - Orchestrates automatic UI preference synchronization
/// - Routes to [Buyer/Seller/Volunteer] dashboards based on profile role
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

        /// LOGGED IN → FETCH ROLE & LANGUAGE
        return FutureBuilder<Map<String, dynamic>?>(
          future: getUserData(snapshot.data!.uid),
          builder: (context, dataSnap) {

            if (dataSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (dataSnap.hasError) {
              return Scaffold(
                body: Center(
                  child: Text("Error loading user data: ${dataSnap.error}"),
                ),
              );
            }

            final userData = dataSnap.data;
            final role = userData?['role'];
            final language = userData?['language'];
            final uiMode = userData?['uiMode'];

            if (language != null || uiMode != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final lp = Provider.of<LanguageProvider>(context, listen: false);
                final auth = Provider.of<AppAuthProvider>(context, listen: false);
                
                if (!lp.isManualSelection) {
                  if (language != null && lp.locale.languageCode != language) {
                    lp.setLanguage(language, isManual: false);
                  }
                  if (uiMode != null && lp.uiMode != uiMode) {
                    lp.setUiMode(uiMode, isManual: false);
                  }
                } else {
                  if ((language != null && lp.locale.languageCode != language) ||
                      (uiMode != null && lp.uiMode != uiMode)) {
                    debugPrint("Syncing local manual preference to cloud: ${lp.locale.languageCode}");
                    BackendService.updateUserPreferences(
                      firebaseUid: auth.currentUser!.uid,
                      language: lp.locale.languageCode,
                      uiMode: lp.uiMode,
                    ).catchError((e) => debugPrint("Failed to sync to cloud: $e"));
                  }
                }
              });
            }

            //------------------------------------------------
            // ROLE ROUTING
            //------------------------------------------------

            if (role == "seller") {
              return const SellerDashboardPage();
            } else if (role == "volunteer") {
              return const VolunteerDashboardPage();
            } else if (role == "buyer") {
              return const BuyerDashboardPage();
            }

            return const LandingPage();
          },
        );
      },
    );
  }
}
