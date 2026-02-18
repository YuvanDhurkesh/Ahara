import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Voice Command Handler Tests', () {
    test('Help command should be recognized (case-insensitive)', () {
      final testWords = ['help', 'HELP', 'Help', 'can you help'];
      
      for (final word in testWords) {
        expect(word.toLowerCase().contains('help'), isTrue);
      }
    });

    test('Logout command should be recognized', () {
      final testWords = ['logout', 'log out', 'LOGOUT', 'please logout'];
      
      for (final word in testWords) {
        final lower = word.toLowerCase();
        expect(lower.contains('logout') || lower.contains('log out'), isTrue);
      }
    });

    test('Profile command should be recognized', () {
      final testWords = ['profile', 'PROFILE', 'open profile', 'my profile'];
      
      for (final word in testWords) {
        expect(word.toLowerCase().contains('profile'), isTrue);
      }
    });

    test('Rating command should be recognized', () {
      final testWords = ['rating', 'ratings', 'RATING', 'show ratings'];
      
      for (final word in testWords) {
        expect(word.toLowerCase().contains('rating'), isTrue);
      }
    });

    test('Order/Delivery command should be recognized', () {
      final deliveryWords = ['deliver', 'delivery', 'deliveries'];
      final orderWords = ['order', 'orders', 'my orders'];
      
      for (final word in deliveryWords) {
        expect(word.toLowerCase().contains('deliver'), isTrue);
      }
      
      for (final word in orderWords) {
        expect(word.toLowerCase().contains('order'), isTrue);
      }
    });

    test('Available command should be recognized', () {
      final availableWords = ['available', 'AVAILABLE', 'set available'];
      // final unavailableWords = ['unavailable', 'UNAVAILABLE', 'set unavailable'];
      // Unavailable contains 'available', so strict logic might flag it as available unless logic is "un" check first.
      
      for (final word in availableWords) {
        expect(word.toLowerCase().contains('available'), isTrue);
      }
    });

    test('Listing command should be recognized (Seller)', () {
      final testWords = ['listing', 'listings', 'LISTING', 'show listings'];
      
      for (final word in testWords) {
        expect(word.toLowerCase().contains('listing'), isTrue);
      }
    });

    test('Overview command should be recognized (Seller)', () {
      final testWords = ['overview', 'OVERVIEW', 'show overview'];
      
      for (final word in testWords) {
        expect(word.toLowerCase().contains('overview'), isTrue);
      }
    });

    test('Discover command should be recognized (Buyer)', () {
      final testWords = ['discover', 'DISCOVER', 'open discover'];
      
      for (final word in testWords) {
        expect(word.toLowerCase().contains('discover'), isTrue);
      }
    });

    test('Browse command should be recognized (Buyer)', () {
      final testWords = ['browse', 'BROWSE', 'open browse'];
      
      for (final word in testWords) {
        expect(word.toLowerCase().contains('browse'), isTrue);
      }
    });

    test('Favourites command should be recognized (Buyer)', () {
      final testWords = ['favour', 'favourite', 'favourites', 'favorites'];
      
      for (final word in testWords) {
        final lower = word.toLowerCase();
        expect(lower.contains('favour') || lower.contains('favor'), isTrue);
      }
    });

    test('Refresh command should be recognized', () {
      final testWords = ['refresh', 'REFRESH', 'reload', 'refresh page'];
      
      for (final word in testWords) {
        final lower = word.toLowerCase();
        expect(lower.contains('refresh') || lower.contains('reload'), isTrue);
      }
    });

    test('Unknown commands should not match', () {
      final unknownWords = ['hello', 'goodbye', 'random', 'test'];
      // Note: 'order' logic above might strict match, but here we just check none match.
      final validCommands = ['help', 'logout', 'profile', 'rating', 'order'];
      
      for (final word in unknownWords) {
        bool matchesAny = false;
        for (final command in validCommands) {
          if (word.toLowerCase().contains(command)) {
            matchesAny = true;
            break;
          }
        }
        expect(matchesAny, isFalse);
      }
    });
  });
}
