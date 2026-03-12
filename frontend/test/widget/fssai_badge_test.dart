import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahara/shared/widgets/fssai_verified_badge.dart';
import 'package:ahara/data/models/listing_model.dart';

void main() {
  group('FssaiVerifiedBadge Widget Tests', () {
    testWidgets('renders badge when FSSAI is verified', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FssaiVerifiedBadge()),
        ),
      );

      // The badge text should be shown
      expect(find.text('🛡️ FSSAI Verified'), findsOneWidget);
      // The verified icon should be present
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('compact mode renders shorter badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FssaiVerifiedBadge(compact: true)),
        ),
      );

      // Compact mode shows "FSSAI" not full text
      expect(find.text('FSSAI'), findsOneWidget);
      expect(find.text('🛡️ FSSAI Verified'), findsNothing);
    });

    testWidgets('badge is not rendered when isFssaiVerified is false',
        (tester) async {
      // Simulate a listing WITHOUT FSSAI verification
      const isVerified = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                if (isVerified) const FssaiVerifiedBadge(),
                const Text('No Badge'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('🛡️ FSSAI Verified'), findsNothing);
      expect(find.text('No Badge'), findsOneWidget);
    });

    testWidgets('badge IS rendered when isFssaiVerified is true',
        (tester) async {
      const isVerified = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                if (isVerified) const FssaiVerifiedBadge(),
                const Text('Listing Content'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('🛡️ FSSAI Verified'), findsOneWidget);
      expect(find.text('Listing Content'), findsOneWidget);
    });
  });

  group('Listing Model FSSAI Parsing Tests', () {
    test('parses isFssaiVerified=true from populated sellerProfileId', () {
      final json = {
        '_id': 'listing123',
        'foodName': 'Test Food',
        'foodType': 'prepared_meal',
        'totalQuantity': 10,
        'remainingQuantity': 5,
        'quantityText': '5 portions',
        'pricing': {'isFree': true, 'discountedPrice': 0},
        'pickupWindow': {
          'from': '2026-03-12T10:00:00Z',
          'to': '2026-03-12T14:00:00Z',
        },
        'hygieneStatus': 'excellent',
        'pickupAddressText': 'Test Address',
        'pickupGeo': {
          'coordinates': [80.27, 13.08]
        },
        'images': ['https://example.com/food.jpg'],
        'description': 'Test listing',
        'status': 'active',
        'sellerProfileId': {
          'orgName': 'Verified Restaurant',
          'fssai': {
            'number': '12345678901234',
            'certificateUrl': 'https://cloudinary.com/cert.jpg',
            'verified': true,
          },
        },
      };

      final listing = Listing.fromJson(json);
      expect(listing.isFssaiVerified, true);
      expect(listing.sellerName, 'Verified Restaurant');
    });

    test('parses isFssaiVerified=false when fssai is not verified', () {
      final json = {
        '_id': 'listing456',
        'foodName': 'Unverified Food',
        'foodType': 'fresh_produce',
        'totalQuantity': 5,
        'remainingQuantity': 5,
        'quantityText': '5 kg',
        'pricing': {'isFree': true, 'discountedPrice': 0},
        'pickupWindow': {
          'from': '2026-03-12T10:00:00Z',
          'to': '2026-03-12T14:00:00Z',
        },
        'hygieneStatus': 'good',
        'pickupAddressText': 'Test Address',
        'pickupGeo': {
          'coordinates': [80.27, 13.08]
        },
        'images': [],
        'description': 'Another listing',
        'status': 'active',
        'sellerProfileId': {
          'orgName': 'Normal Restaurant',
          'fssai': {
            'verified': false,
          },
        },
      };

      final listing = Listing.fromJson(json);
      expect(listing.isFssaiVerified, false);
      expect(listing.sellerName, 'Normal Restaurant');
    });

    test('defaults to false when sellerProfileId is not populated', () {
      final json = {
        '_id': 'listing789',
        'foodName': 'Simple Food',
        'foodType': 'bakery_item',
        'totalQuantity': 3,
        'remainingQuantity': 3,
        'quantityText': '3 pieces',
        'pricing': {'isFree': false, 'discountedPrice': 50},
        'pickupWindow': {
          'from': '2026-03-12T10:00:00Z',
          'to': '2026-03-12T14:00:00Z',
        },
        'hygieneStatus': 'excellent',
        'pickupAddressText': 'Test Address',
        'pickupGeo': {
          'coordinates': [80.27, 13.08]
        },
        'images': [],
        'description': 'No profile listing',
        'status': 'active',
      };

      final listing = Listing.fromJson(json);
      expect(listing.isFssaiVerified, false);
      expect(listing.sellerName, isNull);
    });
  });
}
