import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/services/backend_service.dart';

void main() {
  // NOTE: formatImageUrl tests that depend on baseUrl are skipped because
  // dotenv is not initialized in unit tests. We test isValidImageUrl and
  // generateFoodImageUrl which are pure functions with no env dependency.

  group('BackendService - formatImageUrl (pure path tests)', () {
    test('should return http URL as-is', () {
      final result = BackendService.formatImageUrl(
        'http://example.com/img.jpg',
      );
      expect(result, 'http://example.com/img.jpg');
    });

    test('should return https URL as-is', () {
      final result = BackendService.formatImageUrl(
        'https://example.com/img.jpg',
      );
      expect(result, 'https://example.com/img.jpg');
    });
  });

  group('BackendService - isValidImageUrl', () {
    test('should return false for null', () {
      expect(BackendService.isValidImageUrl(null), false);
    });

    test('should return false for empty string', () {
      expect(BackendService.isValidImageUrl(''), false);
    });

    test('should return false for dicebear.com URL', () {
      expect(
        BackendService.isValidImageUrl('https://api.dicebear.com/avatar.svg'),
        false,
      );
    });

    test('should return false for placeholder.com URL', () {
      expect(
        BackendService.isValidImageUrl('https://via.placeholder.com/300'),
        false,
      );
    });

    test('should return true for http URL', () {
      expect(
        BackendService.isValidImageUrl('http://example.com/food.jpg'),
        true,
      );
    });

    test('should return true for https URL', () {
      expect(
        BackendService.isValidImageUrl('https://images.unsplash.com/photo.jpg'),
        true,
      );
    });

    test('should return true for absolute path starting with /', () {
      expect(BackendService.isValidImageUrl('/uploads/image.jpg'), true);
    });

    test('should return false for plain text', () {
      expect(BackendService.isValidImageUrl('not a url'), false);
    });
  });

  group('BackendService - generateFoodImageUrl', () {
    test('should return Unsplash URL for known food name', () {
      final result = BackendService.generateFoodImageUrl('chicken biryani');
      expect(result, contains('images.unsplash.com'));
    });

    test('should return Unsplash URL for known category', () {
      final result = BackendService.generateFoodImageUrl('something', 'pizza');
      expect(result, contains('images.unsplash.com'));
    });

    test('should return LoremFlickr URL for unknown name and category', () {
      final result = BackendService.generateFoodImageUrl('xylophone');
      expect(result, contains('loremflickr.com'));
    });

    test('should return deterministic result for same input', () {
      final url1 = BackendService.generateFoodImageUrl('pasta');
      final url2 = BackendService.generateFoodImageUrl('pasta');
      expect(url1, url2);
    });
  });
}
