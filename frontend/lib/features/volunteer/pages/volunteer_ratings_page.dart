/// File: volunteer_ratings_page.dart
/// Purpose: Impact visualization and quality control dashboard for field agents.
/// 
/// Responsibilities:
/// - Displays aggregated performance metrics (On-time rate, Success rate)
/// - Visualizes gamified badges earned through community service
/// - Aggregates and renders qualitative feedback from donors and recipients
import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';

/// Comprehensive performance and trust score evaluation interface.
/// 
/// Features:
/// - Achievement visualization (Badges & Milestones)
/// - Statistical performance decomposition
/// - Historical review feed with qualitative sentiment
class VolunteerRatingsPage extends StatelessWidget {
  const VolunteerRatingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Ratings & Badges',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _OverallRatingCard(),
            SizedBox(height: 20),
            _BadgesSection(),
            SizedBox(height: 20),
            _PerformanceStats(),
            SizedBox(height: 20),
            _RecentReviews(),
          ],
        ),
      ),
    );
  }
}

//
// ───────────────────────── OVERALL RATING ─────────────────────────
//

class _OverallRatingCard extends StatelessWidget {
  const _OverallRatingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: Column(
        children: const [
          Icon(Icons.star, color: Colors.amber, size: 40),
          SizedBox(height: 8),
          Text(
            '4.8',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Based on 47 deliveries',
            style: TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

//
// ───────────────────────── BADGES ─────────────────────────
//

class _BadgesSection extends StatelessWidget {
  const _BadgesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Badges',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            _BadgeCard(
              icon: Icons.verified,
              label: 'Verified\nVolunteer',
              isActive: true,
            ),
            SizedBox(width: 12),
            _BadgeCard(
              icon: Icons.star,
              label: 'Top\nVolunteer',
              isActive: true,
            ),
            SizedBox(width: 12),
            _BadgeCard(
              icon: Icons.local_shipping,
              label: '50\nDeliveries',
              isActive: false,
            ),
            SizedBox(width: 12),
            _BadgeCard(
              icon: Icons.flash_on,
              label: 'Perfect\nStreak',
              isActive: false,
            ),
          ],
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _BadgeCard({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF7EF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? Colors.green : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.green : Colors.grey),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.green : Colors.grey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// ───────────────────────── PERFORMANCE STATS ─────────────────────────
//

class _PerformanceStats extends StatelessWidget {
  const _PerformanceStats();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _StatBox(title: 'On-Time Rate', value: '95%', color: Colors.green),
        SizedBox(width: 12),
        _StatBox(title: 'Success Rate', value: '98%', color: Colors.blue),
        SizedBox(width: 12),
        _StatBox(title: 'Avg Time', value: '22 min', color: Colors.orange),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

//
// ───────────────────────── RECENT REVIEWS ─────────────────────────
//

class _RecentReviews extends StatelessWidget {
  const _RecentReviews();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Recent Reviews',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12),
        _ReviewTile(
          name: 'Sarah Johnson',
          date: 'Feb 3',
          review: 'Very professional and on time!',
        ),
        _ReviewTile(
          name: 'Mike Chen',
          date: 'Feb 2',
          review: 'Great delivery service, food arrived fresh.',
        ),
        _ReviewTile(
          name: 'Emma Davis',
          date: 'Feb 1',
          review: 'Good service, slightly delayed.',
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final String name;
  final String date;
  final String review;

  const _ReviewTile({
    required this.name,
    required this.date,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (index) => const Icon(Icons.star, size: 14, color: Colors.amber),
            ),
          ),
          const SizedBox(height: 6),
          Text(review, style: const TextStyle(color: AppColors.textLight)),
        ],
      ),
    );
  }
}
