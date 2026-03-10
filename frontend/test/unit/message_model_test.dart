import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/models/message_model.dart';

void main() {
  group('MessageModel Tests', () {
    test('fromJson should parse all fields correctly', () {
      final json = {
        '_id': 'msg-1',
        'orderId': 'order-1',
        'senderId': 'user-1',
        'senderRole': 'buyer',
        'text': 'Hello, is the item ready?',
        'createdAt': '2026-03-10T12:00:00.000Z',
      };

      final message = MessageModel.fromJson(json);

      expect(message.id, equals('msg-1'));
      expect(message.orderId, equals('order-1'));
      expect(message.senderId, equals('user-1'));
      expect(message.senderRole, equals('buyer'));
      expect(message.text, equals('Hello, is the item ready?'));
      expect(message.createdAt.year, equals(2026));
    });

    test('fromJson should handle missing _id with empty string', () {
      final json = {
        'orderId': 'order-1',
        'senderId': 'user-1',
        'senderRole': 'seller',
        'text': 'Yes!',
        'createdAt': '2026-03-10T12:00:00.000Z',
      };

      final message = MessageModel.fromJson(json);

      expect(message.id, equals(''));
    });

    test('fromJson should handle null fields with defaults', () {
      final json = <String, dynamic>{};

      final message = MessageModel.fromJson(json);

      expect(message.id, equals(''));
      expect(message.orderId, equals(''));
      expect(message.senderId, equals(''));
      expect(message.senderRole, equals(''));
      expect(message.text, equals(''));
    });

    test('fromJson should handle null createdAt with DateTime.now()', () {
      final json = {
        '_id': 'msg-2',
        'orderId': 'order-1',
        'senderId': 'user-1',
        'senderRole': 'buyer',
        'text': 'Test',
        'createdAt': null,
      };

      final before = DateTime.now();
      final message = MessageModel.fromJson(json);
      final after = DateTime.now();

      expect(
        message.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        message.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('toJson should serialize all fields correctly', () {
      final message = MessageModel(
        id: 'msg-1',
        orderId: 'order-1',
        senderId: 'user-1',
        senderRole: 'buyer',
        text: 'Ready for pickup',
        createdAt: DateTime.parse('2026-03-10T12:00:00.000Z'),
      );

      final json = message.toJson();

      expect(json['_id'], equals('msg-1'));
      expect(json['orderId'], equals('order-1'));
      expect(json['senderId'], equals('user-1'));
      expect(json['senderRole'], equals('buyer'));
      expect(json['text'], equals('Ready for pickup'));
      expect(json['createdAt'], contains('2026-03-10'));
    });

    test('toJson should exclude _id when empty', () {
      final message = MessageModel(
        id: '',
        orderId: 'order-1',
        senderId: 'user-1',
        senderRole: 'volunteer',
        text: 'On my way!',
        createdAt: DateTime.now(),
      );

      final json = message.toJson();

      expect(json.containsKey('_id'), isFalse);
    });

    test('roundtrip fromJson -> toJson preserves data', () {
      final original = {
        '_id': 'msg-roundtrip',
        'orderId': 'order-rt',
        'senderId': 'user-rt',
        'senderRole': 'seller',
        'text': 'Roundtrip test',
        'createdAt': '2026-03-10T12:00:00.000Z',
      };

      final message = MessageModel.fromJson(original);
      final serialized = message.toJson();

      expect(serialized['_id'], equals('msg-roundtrip'));
      expect(serialized['orderId'], equals('order-rt'));
      expect(serialized['text'], equals('Roundtrip test'));
    });
  });
}
