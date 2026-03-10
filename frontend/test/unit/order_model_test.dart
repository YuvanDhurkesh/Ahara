import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/order_model.dart';

void main() {
  group('Order Model Tests', () {
    test('fromJson should parse all fields correctly', () {
      final json = {
        'id': 'order-1',
        'listingId': 'listing-1',
        'buyerId': 'buyer-1',
        'volunteerId': 'volunteer-1',
        'status': 'pending',
        'totalAmount': 150.50,
        'listingName': 'Fresh Bread',
        'buyerName': 'John Doe',
        'pickupInstructions': 'Ring bell twice',
        'createdAt': '2026-03-10T12:00:00.000Z',
      };

      final order = Order.fromJson(json);

      expect(order.id, equals('order-1'));
      expect(order.listingId, equals('listing-1'));
      expect(order.buyerId, equals('buyer-1'));
      expect(order.volunteerId, equals('volunteer-1'));
      expect(order.status, equals(OrderStatus.pending));
      expect(order.totalAmount, equals(150.50));
      expect(order.listingName, equals('Fresh Bread'));
      expect(order.buyerName, equals('John Doe'));
      expect(order.pickupInstructions, equals('Ring bell twice'));
    });

    test('fromJson should handle null volunteerId', () {
      final json = {
        'id': 'order-2',
        'listingId': 'listing-2',
        'buyerId': 'buyer-2',
        'volunteerId': null,
        'status': 'confirmed',
        'totalAmount': 0,
        'listingName': 'Unknown',
        'buyerName': 'Unknown',
        'pickupInstructions': '',
        'createdAt': '2026-03-10T12:00:00.000Z',
      };

      final order = Order.fromJson(json);

      expect(order.volunteerId, isNull);
    });

    test('fromJson should default listingName and buyerName when missing', () {
      final json = {
        'id': 'order-3',
        'listingId': 'listing-3',
        'buyerId': 'buyer-3',
        'status': 'delivered',
        'totalAmount': 50,
        'createdAt': '2026-03-10T12:00:00.000Z',
      };

      final order = Order.fromJson(json);

      expect(order.listingName, equals('Unknown'));
      expect(order.buyerName, equals('Unknown'));
      expect(order.pickupInstructions, equals(''));
    });

    test('toJson should serialize all fields correctly', () {
      final order = Order(
        id: 'order-1',
        listingId: 'listing-1',
        buyerId: 'buyer-1',
        volunteerId: 'volunteer-1',
        status: OrderStatus.delivered,
        totalAmount: 200.0,
        listingName: 'Fresh Apples',
        buyerName: 'Jane',
        pickupInstructions: 'Back door',
        createdAt: DateTime.parse('2026-03-10T12:00:00.000Z'),
      );

      final json = order.toJson();

      expect(json['id'], equals('order-1'));
      expect(json['status'], equals('delivered'));
      expect(json['totalAmount'], equals(200.0));
      expect(json['volunteerId'], equals('volunteer-1'));
    });

    test('fromJson should parse all OrderStatus values', () {
      for (final status in OrderStatus.values) {
        final json = {
          'id': 'order-test',
          'listingId': 'listing-test',
          'buyerId': 'buyer-test',
          'status': status.name,
          'totalAmount': 0,
          'createdAt': '2026-03-10T12:00:00.000Z',
        };

        final order = Order.fromJson(json);
        expect(order.status, equals(status));
      }
    });

    test('fromJson should handle integer totalAmount', () {
      final json = {
        'id': 'order-int',
        'listingId': 'listing-1',
        'buyerId': 'buyer-1',
        'status': 'pending',
        'totalAmount': 100,
        'createdAt': '2026-03-10T12:00:00.000Z',
      };

      final order = Order.fromJson(json);
      expect(order.totalAmount, equals(100.0));
      expect(order.totalAmount, isA<double>());
    });
  });
}
