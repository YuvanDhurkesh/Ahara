import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/volunteer/widgets/badge_widget.dart';

void main() {
  group('BadgeWidget Tests', () {
    testWidgets('should display the label text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BadgeWidget(label: 'Top Volunteer')),
        ),
      );

      expect(find.text('Top Volunteer'), findsOneWidget);
    });

    testWidgets('should render as a Chip widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BadgeWidget(label: 'Hero')),
        ),
      );

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('should display different labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BadgeWidget(label: 'New Joiner')),
        ),
      );

      expect(find.text('New Joiner'), findsOneWidget);
      expect(find.text('Top Volunteer'), findsNothing);
    });
  });
}
