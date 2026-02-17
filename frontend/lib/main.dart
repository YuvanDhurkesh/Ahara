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

import 'package:provider/provider.dart';
import 'data/providers/app_auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
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

            final userData = dataSnap.data;
            final role = userData?['role'];
            final language = userData?['language'];

            // Sync Language if needed
            if (language != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final lp = Provider.of<LanguageProvider>(context, listen: false);
                if (lp.locale.languageCode != language) {
                  lp.setLanguage(language);
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

            /// Temporarily route others to landing
            return const LandingPage();
          },
        );
      },
    );
  }
}
