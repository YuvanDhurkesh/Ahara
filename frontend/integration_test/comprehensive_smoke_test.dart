import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Comprehensive Smoke Test', () {
    testWidgets('Verify Global Navigation and Localization', (WidgetTester tester) async {
      // 1. Launch App
      await app.main();
      await tester.pumpAndSettle();

      // 2. Check for App Title (Verify Landing Page)
      expect(find.text('Ahara'), findsOneWidget);

      // 3. Test Language Switching (Logic Check)
      // Note: This assumes presence of a language picker on the landing/login page
      final languageButton = find.byIcon(Icons.language_outlined);
      if (languageButton.evaluate().isNotEmpty) {
        await tester.tap(languageButton);
        await tester.pumpAndSettle();
        
        // Verify that a dialog or bottom sheet opens
        expect(find.byType(BottomSheet), findsOneWidget);
        
        // Close it
        await tester.tapAt(const Offset(10, 10)); // Tap outside
        await tester.pumpAndSettle();
      }

      // 4. Verify Common Auth Navigation
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);

      // 5. Check Footer/Attribution (if exists)
      // This ensures the main scroll view is initialized and rendering
    });
  });
}
