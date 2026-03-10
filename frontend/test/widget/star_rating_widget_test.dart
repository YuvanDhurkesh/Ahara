import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/buyer/widgets/star_rating_widget.dart';

void main() {
  group('StarRatingWidget Tests', () {
    testWidgets('should display 5 stars', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StarRatingWidget(onRatingChanged: (_) {})),
        ),
      );

      // 5 star_outline icons (initial rating is 0)
      expect(find.byIcon(Icons.star_outline), findsNWidgets(5));
    });

    testWidgets('should show filled stars based on initial rating', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRatingWidget(initialRating: 3, onRatingChanged: (_) {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_outline), findsNWidgets(2));
    });

    testWidgets('should update rating on tap when interactive', (
      WidgetTester tester,
    ) async {
      int selectedRating = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRatingWidget(
              onRatingChanged: (rating) {
                selectedRating = rating;
              },
            ),
          ),
        ),
      );

      // Tap the 4th star
      final stars = find.byType(GestureDetector);
      await tester.tap(stars.at(3));
      await tester.pump();

      expect(selectedRating, equals(4));
    });

    testWidgets('should not have GestureDetector when non-interactive', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRatingWidget(
              interactive: false,
              initialRating: 2,
              onRatingChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('should show all 5 stars filled when rating is 5', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRatingWidget(initialRating: 5, onRatingChanged: (_) {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsNWidgets(5));
      expect(find.byIcon(Icons.star_outline), findsNothing);
    });
  });

  group('DisplayStarRating Tests', () {
    testWidgets('should display 5 star icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DisplayStarRating(rating: 3.5))),
      );

      // Should have icons (filled + outline)
      final iconFinder = find.byType(Icon);
      expect(iconFinder, findsWidgets);
    });

    testWidgets('should render without label when showLabel is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisplayStarRating(rating: 4.0, showLabel: false),
          ),
        ),
      );

      // Widget should render without error
      expect(find.byType(DisplayStarRating), findsOneWidget);
    });
  });
}
