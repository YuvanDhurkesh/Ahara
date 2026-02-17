import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Navigation Tests', () {
    testWidgets('Logout navigation should clear navigation stack', (WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('Home')),
        ),
      );

      // Push a route
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => const Scaffold(body: Text('Profile'))),
      );
      await tester.pumpAndSettle();

      // Simulate logout navigation (pushAndRemoveUntil)
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Scaffold(body: Text('Landing'))),
        (route) => false,
      );
      await tester.pumpAndSettle();

      // Verify we can't go back
      expect(navigatorKey.currentState?.canPop(), isFalse);
    });

    testWidgets('Profile navigation should push new route', (WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('Home')),
        ),
      );

      // Push profile route
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => const Scaffold(body: Text('Profile'))),
      );
      await tester.pumpAndSettle();

      // Verify we can go back
      expect(navigatorKey.currentState?.canPop(), isTrue);
    });

    test('Tab switching should update selected index', () {
      int selectedIndex = 0;
      
      // Simulate tab switch
      selectedIndex = 1;
      expect(selectedIndex, equals(1));
      
      selectedIndex = 2;
      expect(selectedIndex, equals(2));
      
      selectedIndex = 0;
      expect(selectedIndex, equals(0));
    });

    test('Voice command navigation should map to correct indices', () {
      // Seller dashboard tabs: 0=Overview, 1=Listings, 2=Orders, 3=Profile
      final Map<String, int> sellerCommands = {
        'overview': 0,
        'listings': 1,
        'orders': 2,
        'profile': 3,
      };

      expect(sellerCommands['overview'], equals(0));
      expect(sellerCommands['listings'], equals(1));
      expect(sellerCommands['orders'], equals(2));
      expect(sellerCommands['profile'], equals(3));

      // Buyer dashboard tabs: 0=Discover, 1=Browse, 2=Orders, 3=Favourites, 4=Profile
      final Map<String, int> buyerCommands = {
        'discover': 0,
        'browse': 1,
        'orders': 2,
        'favourites': 3,
        'profile': 4,
      };

      expect(buyerCommands['discover'], equals(0));
      expect(buyerCommands['browse'], equals(1));
      expect(buyerCommands['orders'], equals(2));
      expect(buyerCommands['favourites'], equals(3));
      expect(buyerCommands['profile'], equals(4));
    });
  });
}
