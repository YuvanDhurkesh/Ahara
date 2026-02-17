import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../core/localization/app_localizations.dart';

import 'volunteer_home_page.dart';
import 'volunteer_orders_page.dart';
import 'volunteer_notifications_page.dart';
import 'volunteer_ratings_page.dart';
import 'volunteer_profile_page.dart';
import 'volunteer_verification_page.dart';

class VolunteerDashboardPage extends StatefulWidget {
  final int initialIndex;
  const VolunteerDashboardPage({super.key, this.initialIndex = 0});

  @override
  State<VolunteerDashboardPage> createState() => _VolunteerDashboardPageState();
}

class _VolunteerDashboardPageState extends State<VolunteerDashboardPage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      VolunteerHomePage(), // Home
      VolunteerOrdersPage(), // My Deliveries
      VolunteerVerificationPage(), // Verification page
      VolunteerRatingsPage(), // Ratings & Badges
      VolunteerProfilePage(), // Profile (Logout here)
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_selectedIndex],

      // 👇 SAME buyer-style bottom navigation wrapper
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
                  onTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
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
                  items: [
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.home_outlined),
                      ),
                      activeIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.home),
                      ),
                      label: AppLocalizations.of(context)!.translate("home"),
                    ),
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.local_shipping_outlined),
                      ),
                      activeIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.local_shipping),
                      ),
                      label: AppLocalizations.of(context)!.translate("deliveries"),
                    ),
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.domain_verification),
                      ),
                      activeIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.domain_verification),
                      ),
                      label: AppLocalizations.of(context)!.translate("verification"),
                    ),
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.star_border),
                      ),
                      activeIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.star),
                      ),
                      label: AppLocalizations.of(context)!.translate("ratings"),
                    ),
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.person_outline),
                      ),
                      activeIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.person),
                      ),
                      label: AppLocalizations.of(context)!.translate("profile"),
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
