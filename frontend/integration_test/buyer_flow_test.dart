import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/buyer/pages/buyer_dashboard_page.dart';
import 'package:frontend/data/providers/app_auth_provider.dart';
import 'package:frontend/core/localization/language_provider.dart';
import 'package:frontend/core/services/voice_service.dart';
import 'package:frontend/config/theme_config.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Buyer Dashboard Navigation Test', (WidgetTester tester) async {
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppAuthProvider()), 
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
          home: const BuyerDashboardPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Dashboard Tabs / Sections
    // Note: Buyer tabs: Discover, Browse (Location), Orders, Favourites, Profile
    // Using Find by Icon or Text if text is localized
    
    // We can check for standard UI elements we expect
    // Ideally we mock backend service to return some food items for "Discover" page

    // 2. Navigate to Browse Tab
    await tester.tap(find.byIcon(Icons.location_on_outlined));
    await tester.pumpAndSettle();

    // 3. Navigate to Orders Tab
    await tester.tap(find.byIcon(Icons.shopping_bag_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Orders'), findsOneWidget); // Assuming header "Orders" exists

    // 4. Navigate to Profile
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget); // Assuming header "Profile" exists
  });
}
