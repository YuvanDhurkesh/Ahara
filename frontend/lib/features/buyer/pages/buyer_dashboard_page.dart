import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';
import 'buyer_home_page.dart';
import 'buyer_browse_page.dart';
import 'buyer_favourites_page.dart';
import 'buyer_orders_page.dart';
import 'buyer_profile_page.dart';

class BuyerDashboardPage extends StatefulWidget {
  final int initialIndex;
  const BuyerDashboardPage({super.key, this.initialIndex = 0});

  @override
  State<BuyerDashboardPage> createState() => _BuyerDashboardPageState();
}

class _BuyerDashboardPageState extends State<BuyerDashboardPage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final Set<String> _favouriteIds = {};

  void _toggleFavourite(String id) {
    setState(() {
      if (_favouriteIds.contains(id)) {
        _favouriteIds.remove(id);
      } else {
        _favouriteIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      BuyerHomePage(
        favouriteIds: _favouriteIds,
        onToggleFavourite: _toggleFavourite,
      ), // Discover
      BuyerBrowsePage(
        favouriteIds: _favouriteIds,
        onToggleFavourite: _toggleFavourite,
      ), // Browse
      const BuyerOrdersPage(), // Orders
      BuyerFavouritesPage(
        favouriteIds: _favouriteIds,
        onToggleFavourite: _toggleFavourite,
      ), // Favourites
      const BuyerProfilePage(), // Profile
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Align(
              heightFactor: 1.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  backgroundColor: Colors.white,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.textLight.withOpacity(0.4),
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.explore_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.explore),
                      ),
                      label: "Discover",
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.location_on_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.location_on),
                      ),
                      label: "Browse",
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.shopping_bag_outlined),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.shopping_bag),
                      ),
                      label: "Orders",
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.favorite_outline),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.favorite),
                      ),
                      label: "Favourites",
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.person_outline),
                      ),
                      activeIcon: Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.person),
                      ),
                      label: "Profile",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
