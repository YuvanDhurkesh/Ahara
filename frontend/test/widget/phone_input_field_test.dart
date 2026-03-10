import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/widgets/phone_input_field.dart';

void main() {
  group('PhoneInputField Widget Tests', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('should display the label text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneInputField(
              controller: controller,
              label: 'Phone Number',
            ),
          ),
        ),
      );

      expect(find.text('Phone Number'), findsOneWidget);
    });

    testWidgets('should display hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneInputField(
              controller: controller,
              label: 'Phone',
              hintText: 'Enter your number',
            ),
          ),
        ),
      );

      expect(find.text('Enter your number'), findsOneWidget);
    });

    testWidgets('should render a TextFormField', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneInputField(controller: controller, label: 'Phone'),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should accept numeric input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneInputField(controller: controller, label: 'Phone'),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '9876543210');
      expect(controller.text, equals('9876543210'));
    });

    testWidgets('should display default country code +91', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneInputField(controller: controller, label: 'Phone'),
          ),
        ),
      );

      expect(find.text('+91'), findsOneWidget);
    });

    testWidgets('should contain a DropdownButton for country code', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneInputField(controller: controller, label: 'Phone'),
          ),
        ),
      );

      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });
  });
}
