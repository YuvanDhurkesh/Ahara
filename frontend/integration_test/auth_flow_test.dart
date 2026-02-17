import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Authentication Flow Test - Login Failure & UI Checks', (WidgetTester tester) async {
    // 1. App Launch
    await app.main();
    await tester.pumpAndSettle();

    // 2. Verify Landing Page
    expect(find.text('Ahara'), findsOneWidget); // Checks title in AppBar or on screen
    expect(find.text('Login'), findsOneWidget); 
    
    // 3. Navigate to Login Page
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // 4. Verify Login Page UI
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);

    // 5. Attempt Empty Login (Validation Check)
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump(); // Pump to show validation errors

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);

    // 6. Enter Invalid Credentials
    await tester.enterText(find.ancestor(of: find.text('name@example.com'), matching: find.byType(TextFormField)), 'invalid@test');
    await tester.enterText(find.ancestor(of: find.text('Enter your password'), matching: find.byType(TextFormField)), 'wrongpass');
    
    // Note: Actual login requires Firebase auth mocking or real credentials. 
    // For integration tests on CI/CD without secrets, we stop at UI interaction 
    // or use a mock auth provider if set up.
    // Here we just verify the input fields work.
  });
}
