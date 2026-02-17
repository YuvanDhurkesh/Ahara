import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/seller/pages/seller_dashboard_page.dart';
import 'package:frontend/data/providers/app_auth_provider.dart';
import 'package:frontend/core/localization/language_provider.dart';
import 'package:frontend/core/services/voice_service.dart';
import 'package:frontend/config/theme_config.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Seller Dashboard Navigation Test', (WidgetTester tester) async {
    
    // Setup Providers with default values
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppAuthProvider()), // Mock if needed
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => VoiceService()),
        ],
        child: MaterialApp(
          theme: ThemeConfig.lightTheme,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SellerDashboardPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Dashboard Tabs
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Listings'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // 2. Navigate to Listings Tab
    await tester.tap(find.text('Listings'));
    await tester.pumpAndSettle();

    // 3. Verify Listings Page UI
    expect(find.text('My Listings'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    
    // 4. Verify "New Listing" Button
    expect(find.text('New Listing'), findsOneWidget);

    // 5. Tap New Listing (Should open Create Listing Page)
    await tester.tap(find.text('New Listing'));
    await tester.pumpAndSettle();
    
    // Verify Create Listing Page Title (assuming it has one)
    expect(find.text('Create Listing'), findsOneWidget); // Update based on actual title
  });
}
