import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/volunteer/widgets/availability_toggle.dart';

void main() {
  group('AvailabilityToggle Tests', () {
    testWidgets('should display title text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AvailabilityToggle())),
      );

      expect(find.text('Available for deliveries'), findsOneWidget);
    });

    testWidgets('should render as SwitchListTile', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AvailabilityToggle())),
      );

      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('toggle should be enabled by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AvailabilityToggle())),
      );

      final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(toggle.value, isTrue);
    });
  });
}
