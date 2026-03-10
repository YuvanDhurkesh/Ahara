import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Minimal fake DocumentSnapshot for testing UserModel.fromFirestore
// We can't use real Firestore in unit tests, so we test toMap roundtrip
// and the factory constructor logic indirectly.

void main() {
  group('UserModel - toMap', () {
    test('should serialize all required fields', () {
      final user = UserModel(
        uid: 'user-123',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '+919876543210',
        location: 'Chennai',
        role: 'buyer',
      );

      final map = user.toMap();

      expect(map['uid'], 'user-123');
      expect(map['name'], 'John Doe');
      expect(map['email'], 'john@example.com');
      expect(map['phone'], '+919876543210');
      expect(map['location'], 'Chennai');
      expect(map['role'], 'buyer');
      expect(map['isVerified'], false);
    });

    test('should serialize optional fields when present', () {
      final user = UserModel(
        uid: 'user-456',
        name: 'Seller User',
        email: 'seller@example.com',
        phone: '+919876543211',
        location: 'Bangalore',
        role: 'seller',
        businessName: 'Fresh Kitchen',
        fssaiNumber: 'FSSAI123456',
        officeAddress: '100 MG Road',
        contactNumber: '+919876543212',
        operatingHours: '9AM-9PM',
        isVerified: true,
      );

      final map = user.toMap();

      expect(map['businessName'], 'Fresh Kitchen');
      expect(map['fssaiNumber'], 'FSSAI123456');
      expect(map['officeAddress'], '100 MG Road');
      expect(map['contactNumber'], '+919876543212');
      expect(map['operatingHours'], '9AM-9PM');
      expect(map['isVerified'], true);
    });

    test('should have null optional fields when not provided', () {
      final user = UserModel(
        uid: 'user-789',
        name: 'Simple User',
        email: 'simple@test.com',
        phone: '+910000000000',
        location: 'Delhi',
        role: 'volunteer',
      );

      final map = user.toMap();

      expect(map['businessName'], isNull);
      expect(map['fssaiNumber'], isNull);
      expect(map['officeAddress'], isNull);
      expect(map['contactNumber'], isNull);
      expect(map['operatingHours'], isNull);
      expect(map['aadharFrontUrl'], isNull);
      expect(map['aadharBackUrl'], isNull);
    });

    test('should serialize createdAt as Firestore Timestamp when present', () {
      final now = DateTime(2026, 3, 10, 12, 0, 0);
      final user = UserModel(
        uid: 'user-ts',
        name: 'Test',
        email: 'ts@test.com',
        phone: '+910000000001',
        location: 'Test',
        role: 'buyer',
        createdAt: now,
      );

      final map = user.toMap();
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('should have null createdAt when not provided', () {
      final user = UserModel(
        uid: 'user-no-ts',
        name: 'Test',
        email: 'nots@test.com',
        phone: '+910000000002',
        location: 'Test',
        role: 'buyer',
      );

      final map = user.toMap();
      expect(map['createdAt'], isNull);
    });

    test('should serialize Aadhaar URL fields', () {
      final user = UserModel(
        uid: 'user-aadhaar',
        name: 'Volunteer',
        email: 'vol@test.com',
        phone: '+910000000003',
        location: 'Mumbai',
        role: 'volunteer',
        aadharFrontUrl: 'https://storage/aadhaar-front.jpg',
        aadharBackUrl: 'https://storage/aadhaar-back.jpg',
      );

      final map = user.toMap();
      expect(map['aadharFrontUrl'], 'https://storage/aadhaar-front.jpg');
      expect(map['aadharBackUrl'], 'https://storage/aadhaar-back.jpg');
    });
  });

  group('UserModel - defaults', () {
    test('isVerified defaults to false', () {
      final user = UserModel(
        uid: 'u',
        name: 'n',
        email: 'e',
        phone: 'p',
        location: 'l',
        role: 'r',
      );
      expect(user.isVerified, false);
    });

    test('createdAt defaults to null', () {
      final user = UserModel(
        uid: 'u',
        name: 'n',
        email: 'e',
        phone: 'p',
        location: 'l',
        role: 'r',
      );
      expect(user.createdAt, isNull);
    });
  });
}
