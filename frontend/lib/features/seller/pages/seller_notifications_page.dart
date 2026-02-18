/// File: seller_notifications_page.dart
/// Purpose: Historical and real-time event log for seller-specific activities.
/// 
/// Responsibilities:
/// - Displays categorized notifications (Orders, Inventory, System)
/// - Grouping logic for temporal visualization of events
/// - Interface for granular interaction with individual alerts
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';

/// Central communication hub for alerts, updates, and order notifications.
/// 
/// Components:
/// - Notification grouping by category
/// - Detail-oriented list items with semantic iconography
class SellerNotificationsPage extends StatelessWidget {
  const SellerNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildNotificationGroup("Orders", [
            _NotificationItem(
              title: "New Order Received",
              subtitle: "Order #1234 - 2x Organic Apples",
              time: "2 mins ago",
              icon: Icons.shopping_basket_outlined,
              color: Colors.blue,
            ),
            _NotificationItem(
              title: "Order Pickup Confirmed",
              subtitle: "Volunteer Rahul is on the way for #1230",
              time: "1 hour ago",
              icon: Icons.delivery_dining_outlined,
              color: Colors.green,
            ),
          ]),
          const SizedBox(height: 32),
          _buildNotificationGroup("Inventory", [
            _NotificationItem(
              title: "Stock Alert",
              subtitle: "Sourdough Bread is running low (2 left)",
              time: "3 hours ago",
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
          ]),
          const SizedBox(height: 32),
          _buildNotificationGroup("System", [
            _NotificationItem(
              title: "Profile Verified",
              subtitle: "Your store profile is now live and visible.",
              time: "Yesterday",
              icon: Icons.verified_user_outlined,
              color: AppColors.primary,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildNotificationGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppColors.textLight.withOpacity(0.5),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textDark.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textLight.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textLight.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
