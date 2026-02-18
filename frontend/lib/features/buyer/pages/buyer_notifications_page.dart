/// File: buyer_notifications_page.dart
/// Purpose: Aggregated feed of time-sensitive system and transactional alerts.
/// 
/// Responsibilities:
/// - Displays categorized notifications (Deals, Messages, Alerts)
/// - Provides visual feedback through thematic markers and icons
/// - Renders a chronological history of user interactions
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/styles/app_colors.dart';

/// Central inbox for all buyer-related push and in-app notifications.
/// 
/// Features:
/// - Contextual iconography based on alert type
/// - Time-relative stay stamps (e.g., 2 mins ago)
/// - High-contrast indicators for high-priority deals
class BuyerNotificationsPage extends StatelessWidget {
  const BuyerNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        "title": "New Deal Alert!",
        "message":
            "Sunshine Delights has a 50% discount on sourdough bread for the next hour.",
        "time": "2 mins ago",
        "type": "Deal",
        "icon": Icons.local_offer_rounded,
        "color": Colors.orange,
      },
      {
        "title": "Message from Volunteer",
        "message": "Your delivery for Bakery & Cafe is on the way with Harish.",
        "time": "15 mins ago",
        "type": "Message",
        "icon": Icons.message_rounded,
        "color": AppColors.primary,
      },
      {
        "title": "Account Update",
        "message": "Your profile information was successfully updated.",
        "time": "2 hours ago",
        "type": "Alert",
        "icon": Icons.notifications_active_rounded,
        "color": Colors.blue,
      },
      {
        "title": "Meal Availability",
        "message": "A new batch of meals is available at Golden Harvest.",
        "time": "5 hours ago",
        "type": "Alert",
        "icon": Icons.fastfood_rounded,
        "color": Colors.green,
      },
    ];

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
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final note = notifications[index];
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (note['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    note['icon'] as IconData,
                    color: note['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            note['type'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: note['color'] as Color,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            note['time'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note['message'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textLight.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
