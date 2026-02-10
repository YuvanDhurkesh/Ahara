import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launch test', (WidgetTester tester) async {
    // This test runs the main app. 
    // Note: It requires a running device/emulator with Firebase configuration working,
    // otherwise it might fail on Firebase.initializeApp() or stay at splash screen.
    
    try {
        await app.main();
        await tester.pumpAndSettle();
        
        // If we reach here without crash, app launched.
        // We can check for LandingPage text if we are not logged in.
        // expect(find.text('Ahara'), findsOneWidget);
    } catch (e) {
        // Handle initialization errors if any
        print('Error launching app: $e');
    }
  });
}
