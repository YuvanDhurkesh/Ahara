import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/volunteer/widgets/rating_star_widget.dart';

void main() {
  group('RatingStarWidget Tests', () {
    testWidgets('should display rating value with star', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RatingStarWidget(rating: 4.5))),
      );

      expect(find.text('4.5 ★'), findsOneWidget);
    });

    testWidgets('should display integer rating', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RatingStarWidget(rating: 5.0))),
      );

      expect(find.text('5.0 ★'), findsOneWidget);
    });

    testWidgets('should display zero rating', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RatingStarWidget(rating: 0.0))),
      );

      expect(find.text('0.0 ★'), findsOneWidget);
    });

    testWidgets('should use bold text style', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RatingStarWidget(rating: 3.0))),
      );

      final textWidget = tester.widget<Text>(find.text('3.0 ★'));
      expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
      expect(textWidget.style?.fontSize, equals(32));
    });
  });
}
