import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/common/pages/landing_page.dart'; // Ensure path is correct

void main() {
  testWidgets('FeatureCard renders title and icon', (WidgetTester tester) async {
    const testTitle = 'Global Impact';
    const testIcon = Icons.public;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FeatureCard(
            title: testTitle,
            icon: testIcon,
          ),
        ),
      ),
    );

    // Verify title is displayed
    expect(find.text(testTitle), findsOneWidget);

    // Verify icon is displayed
    expect(find.byIcon(testIcon), findsOneWidget);
  });
}
