import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/listing_model.dart';

void main() {
  group('Listing Model - fromJson', () {
    test('should parse all required fields from backend JSON', () {
      final json = {
        '_id': 'listing-1',
        'foodName': 'Fresh Bread',
        'foodType': 'bakery_item',
        'totalQuantity': 10,
        'remainingQuantity': 5,
        'quantityText': '5 kg',
        'pricing': {'isFree': true, 'discountedPrice': null},
        'pickupWindow': {
          'from': '2026-03-10T08:00:00.000Z',
          'to': '2026-03-10T20:00:00.000Z',
        },
        'hygieneStatus': 'good',
        'pickupAddressText': '123 Main St',
        'pincode': '600001',
        'pickupGeo': {
          'type': 'Point',
          'coordinates': [80.27, 13.08],
        },
        'images': ['/uploads/bread.jpg'],
        'description': 'Freshly baked',
        'status': 'active',
        'businessType': 'restaurant',
      };

      final listing = Listing.fromJson(json);

      expect(listing.id, 'listing-1');
      expect(listing.foodName, 'Fresh Bread');
      expect(listing.foodType, FoodType.bakery_item);
      expect(listing.totalQuantity, 10.0);
      expect(listing.remainingQuantity, 5.0);
      expect(listing.quantityUnit, 'kg');
      expect(listing.redistributionMode, RedistributionMode.free);
      expect(listing.price, isNull);
      expect(listing.hygieneStatus, HygieneStatus.good);
      expect(listing.locationAddress, '123 Main St');
      expect(listing.pincode, '600001');
      expect(listing.latitude, 13.08);
      expect(listing.longitude, 80.27);
      expect(listing.imageUrl, '/uploads/bread.jpg');
      expect(listing.description, 'Freshly baked');
      expect(listing.status, ListingStatus.active);
      expect(listing.businessType, BusinessType.restaurant);
    });

    test('should handle discounted pricing', () {
      final json = {
        '_id': 'listing-2',
        'foodName': 'Pasta',
        'foodType': 'prepared_meal',
        'totalQuantity': 5,
        'remainingQuantity': 3,
        'quantityText': '3 portions',
        'pricing': {'isFree': false, 'discountedPrice': 99.50},
        'pickupWindow': {
          'from': '2026-03-10T08:00:00.000Z',
          'to': '2026-03-10T20:00:00.000Z',
        },
        'status': 'active',
      };

      final listing = Listing.fromJson(json);

      expect(listing.redistributionMode, RedistributionMode.discounted);
      expect(listing.price, 99.50);
    });

    test('should default foodName to Unknown when null', () {
      final json = <String, dynamic>{
        '_id': 'listing-3',
        'foodName': null,
        'status': 'active',
      };

      final listing = Listing.fromJson(json);
      expect(listing.foodName, 'Unknown');
    });

    test('should use id field when _id is missing', () {
      final json = {
        'id': 'listing-fallback',
        'foodName': 'Test',
        'status': 'active',
      };

      final listing = Listing.fromJson(json);
      expect(listing.id, 'listing-fallback');
    });

    test('should default to empty string when both _id and id are missing', () {
      final json = <String, dynamic>{'foodName': 'Test', 'status': 'active'};

      final listing = Listing.fromJson(json);
      expect(listing.id, '');
    });

    test('should map backend "completed" status to ListingStatus.claimed', () {
      final json = {
        '_id': 'listing-4',
        'foodName': 'Cake',
        'status': 'completed',
      };

      final listing = Listing.fromJson(json);
      expect(listing.status, ListingStatus.claimed);
    });

    test('should default status to active for unknown values', () {
      final json = {
        '_id': 'listing-5',
        'foodName': 'Cake',
        'status': 'something_invalid',
      };

      final listing = Listing.fromJson(json);
      expect(listing.status, ListingStatus.active);
    });

    test('should default foodType to prepared_meal for unknown values', () {
      final json = {
        '_id': 'listing-6',
        'foodName': 'Mystery',
        'foodType': 'alien_food',
        'status': 'active',
      };

      final listing = Listing.fromJson(json);
      expect(listing.foodType, FoodType.prepared_meal);
    });

    test('should default hygieneStatus to excellent for null', () {
      final json = {
        '_id': 'listing-7',
        'foodName': 'Test',
        'hygieneStatus': null,
        'status': 'active',
      };

      final listing = Listing.fromJson(json);
      expect(listing.hygieneStatus, HygieneStatus.excellent);
    });

    test('should return null businessType for unknown values', () {
      final json = {
        '_id': 'listing-8',
        'foodName': 'Test',
        'businessType': 'spaceship',
        'status': 'active',
      };

      final listing = Listing.fromJson(json);
      expect(listing.businessType, isNull);
    });

    test('should handle missing pickupGeo with default 0.0 coordinates', () {
      final json = {'_id': 'listing-9', 'foodName': 'Test', 'status': 'active'};

      final listing = Listing.fromJson(json);
      expect(listing.latitude, 0.0);
      expect(listing.longitude, 0.0);
    });

    test('should handle empty images array', () {
      final json = {
        '_id': 'listing-10',
        'foodName': 'Test',
        'images': [],
        'status': 'active',
      };

      final listing = Listing.fromJson(json);
      expect(listing.imageUrl, '');
    });

    test('should extract unit from quantityText', () {
      final json = {
        '_id': 'listing-11',
        'foodName': 'Test',
        'quantityText': '10 liters',
        'status': 'active',
      };

      final listing = Listing.fromJson(json);
      expect(listing.quantityUnit, 'liters');
    });

    test('should default unit to portions for empty quantityText', () {
      final json = {
        '_id': 'listing-12',
        'foodName': 'Test',
        'quantityText': '',
        'status': 'active',
      };

      final listing = Listing.fromJson(json);
      expect(listing.quantityUnit, 'portions');
    });
  });

  group('Listing Model - toJson', () {
    test('should serialize all fields to JSON', () {
      final listing = Listing(
        id: 'listing-1',
        foodName: 'Biryani',
        foodType: FoodType.prepared_meal,
        totalQuantity: 10.0,
        remainingQuantity: 8.0,
        quantityUnit: 'portions',
        redistributionMode: RedistributionMode.free,
        preparedAt: DateTime.parse('2026-03-10T08:00:00.000Z'),
        expiryTime: DateTime.parse('2026-03-10T14:00:00.000Z'),
        hygieneStatus: HygieneStatus.excellent,
        locationAddress: '456 Test St',
        latitude: 13.08,
        longitude: 80.27,
        imageUrl: '/uploads/biryani.jpg',
        description: 'Spicy biryani',
        status: ListingStatus.active,
      );

      final json = listing.toJson();

      expect(json['id'], 'listing-1');
      expect(json['foodName'], 'Biryani');
      expect(json['foodType'], 'prepared_meal');
      expect(json['redistributionMode'], 'free');
      expect(json['hygieneStatus'], 'excellent');
      expect(json['status'], 'active');
      expect(json['latitude'], 13.08);
      expect(json['longitude'], 80.27);
    });

    test('should serialize optional businessType', () {
      final listing = Listing(
        id: 'listing-2',
        foodName: 'Cake',
        foodType: FoodType.bakery_item,
        totalQuantity: 5.0,
        remainingQuantity: 5.0,
        quantityUnit: 'pieces',
        redistributionMode: RedistributionMode.discounted,
        price: 50.0,
        preparedAt: DateTime.parse('2026-03-10T08:00:00.000Z'),
        expiryTime: DateTime.parse('2026-03-11T08:00:00.000Z'),
        hygieneStatus: HygieneStatus.good,
        locationAddress: '789 Cake Lane',
        latitude: 0.0,
        longitude: 0.0,
        imageUrl: '',
        description: 'Chocolate cake',
        status: ListingStatus.active,
        businessType: BusinessType.cafe,
      );

      final json = listing.toJson();

      expect(json['businessType'], 'cafe');
      expect(json['price'], 50.0);
    });

    test('should have null businessType when not set', () {
      final listing = Listing(
        id: 'listing-3',
        foodName: 'Test',
        foodType: FoodType.fresh_produce,
        totalQuantity: 1.0,
        remainingQuantity: 1.0,
        quantityUnit: 'kg',
        redistributionMode: RedistributionMode.free,
        preparedAt: DateTime.now(),
        expiryTime: DateTime.now(),
        hygieneStatus: HygieneStatus.acceptable,
        locationAddress: 'Test',
        latitude: 0.0,
        longitude: 0.0,
        imageUrl: '',
        description: '',
        status: ListingStatus.active,
      );

      final json = listing.toJson();
      expect(json['businessType'], isNull);
    });
  });

  group('Listing Model - calculateExpiryTime', () {
    final base = DateTime(2026, 3, 10, 12, 0, 0);

    test('prepared_meal should expire in 6 hours', () {
      final expiry = Listing.calculateExpiryTime(FoodType.prepared_meal, base);
      expect(expiry, base.add(const Duration(hours: 6)));
    });

    test('fresh_produce should expire in 2 days', () {
      final expiry = Listing.calculateExpiryTime(FoodType.fresh_produce, base);
      expect(expiry, base.add(const Duration(days: 2)));
    });

    test('packaged_food should expire in 30 days', () {
      final expiry = Listing.calculateExpiryTime(FoodType.packaged_food, base);
      expect(expiry, base.add(const Duration(days: 30)));
    });

    test('bakery_item should expire in 1 day', () {
      final expiry = Listing.calculateExpiryTime(FoodType.bakery_item, base);
      expect(expiry, base.add(const Duration(days: 1)));
    });

    test('dairy_product should expire in 2 days', () {
      final expiry = Listing.calculateExpiryTime(FoodType.dairy_product, base);
      expect(expiry, base.add(const Duration(days: 2)));
    });
  });

  group('Listing Enums', () {
    test('FoodType should have 5 values', () {
      expect(FoodType.values.length, 5);
    });

    test('RedistributionMode should have 2 values', () {
      expect(RedistributionMode.values.length, 2);
    });

    test('HygieneStatus should have 3 values', () {
      expect(HygieneStatus.values.length, 3);
    });

    test('ListingStatus should have 3 values', () {
      expect(ListingStatus.values.length, 3);
    });

    test('BusinessType should have 6 values', () {
      expect(BusinessType.values.length, 6);
    });
  });
}
