import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/shared/widgets/animated_toast.dart';

/// Helper to build AnimatedToast inside a MaterialApp scaffold.
Widget _buildToast({required String message, ToastType type = ToastType.info}) {
  return MaterialApp(
    home: Scaffold(
      body: AnimatedToast(message: message, type: type, onDismiss: () {}),
    ),
  );
}

void main() {
  group('AnimatedToast Widget Tests', () {
    testWidgets('should display message text', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildToast(
          message: 'Order placed successfully!',
          type: ToastType.success,
        ),
      );
      await tester.pump();
      expect(find.text('Order placed successfully!'), findsOneWidget);

      // Allow pending timers (Future.delayed + animation) to complete.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('should show check_circle icon for success toast', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildToast(message: 'Success!', type: ToastType.success),
      );
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('should show error icon for error toast', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildToast(message: 'Something went wrong', type: ToastType.error),
      );
      await tester.pump();
      expect(find.byIcon(Icons.error), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('should show info icon for info toast', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildToast(message: 'Info message', type: ToastType.info),
      );
      await tester.pump();
      expect(find.byIcon(Icons.info), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('should have a close button', (WidgetTester tester) async {
      await tester.pumpWidget(_buildToast(message: 'Closeable toast'));
      await tester.pump();
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });

  group('ToastType Enum Tests', () {
    test('should have exactly 3 values', () {
      expect(ToastType.values.length, equals(3));
    });

    test('should contain success, error, info', () {
      expect(ToastType.values, contains(ToastType.success));
      expect(ToastType.values, contains(ToastType.error));
      expect(ToastType.values, contains(ToastType.info));
    });
  });
}
