import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../data/providers/app_auth_provider.dart';

class VolunteerRatingsPage extends StatelessWidget {
  const VolunteerRatingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final stats = auth.mongoProfile?['stats'] as Map<String, dynamic>?;

    final avgRating = (stats?['avgRating'] as num?)?.toDouble() ?? 0;
    final ratingCount = (stats?['ratingCount'] as num?)?.toInt() ?? 0;
    final totalCompleted =
        (stats?['totalDeliveriesCompleted'] as num?)?.toInt() ?? 0;
    final totalFailed = (stats?['totalDeliveriesFailed'] as num?)?.toInt() ?? 0;
    final lateDeliveries = (stats?['lateDeliveries'] as num?)?.toInt() ?? 0;
    final noShows = (stats?['noShows'] as num?)?.toInt() ?? 0;

    final onTimeRate = totalCompleted == 0
        ? 0.0
        : ((totalCompleted - lateDeliveries) / totalCompleted)
              .clamp(0.0, 1.0)
              .toDouble();
    final successRateBase = totalCompleted + totalFailed + noShows;
    final successRate = successRateBase == 0
        ? 0.0
        : (totalCompleted / successRateBase).clamp(0.0, 1.0).toDouble();

    final isVerified =
        (auth.mongoProfile?['badge']?['tickVerified'] as bool?) ?? false;
    final topVolunteer = avgRating >= 4.5 && totalCompleted >= 10;
    final fiftyDeliveries = totalCompleted >= 50;
    final perfectStreak =
        totalCompleted > 0 && totalFailed == 0 && noShows == 0;

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
          children: [
            _OverallRatingCard(
              avgRating: avgRating,
              deliveries: totalCompleted,
              ratingCount: ratingCount,
            ),
            const SizedBox(height: 20),
            _BadgesSection(
              isVerified: isVerified,
              topVolunteer: topVolunteer,
              fiftyDeliveries: fiftyDeliveries,
              perfectStreak: perfectStreak,
            ),
            const SizedBox(height: 20),
            _PerformanceStats(onTimeRate: onTimeRate, successRate: successRate),
            const SizedBox(height: 20),
            _RecentReviews(hasReviews: false),
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
  final double avgRating;
  final int deliveries;
  final int ratingCount;

  const _OverallRatingCard({
    required this.avgRating,
    required this.deliveries,
    required this.ratingCount,
  });

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
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 40),
          const SizedBox(height: 8),
          Text(
            avgRating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Based on $deliveries deliveries ($ratingCount ratings)',
            style: const TextStyle(color: AppColors.textLight),
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
  final bool isVerified;
  final bool topVolunteer;
  final bool fiftyDeliveries;
  final bool perfectStreak;

  const _BadgesSection({
    required this.isVerified,
    required this.topVolunteer,
    required this.fiftyDeliveries,
    required this.perfectStreak,
  });

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
          children: [
            _BadgeCard(
              icon: Icons.verified,
              label: 'Verified\nVolunteer',
              isActive: isVerified,
            ),
            const SizedBox(width: 12),
            _BadgeCard(
              icon: Icons.star,
              label: 'Top\nVolunteer',
              isActive: topVolunteer,
            ),
            const SizedBox(width: 12),
            _BadgeCard(
              icon: Icons.local_shipping,
              label: '50\nDeliveries',
              isActive: fiftyDeliveries,
            ),
            const SizedBox(width: 12),
            _BadgeCard(
              icon: Icons.flash_on,
              label: 'Perfect\nStreak',
              isActive: perfectStreak,
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
  final double onTimeRate;
  final double successRate;

  const _PerformanceStats({
    required this.onTimeRate,
    required this.successRate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(
          title: 'On-Time Rate',
          value: '${(onTimeRate * 100).toStringAsFixed(0)}%',
          color: Colors.green,
        ),
        const SizedBox(width: 12),
        _StatBox(
          title: 'Success Rate',
          value: '${(successRate * 100).toStringAsFixed(0)}%',
          color: Colors.blue,
        ),
        const SizedBox(width: 12),
        const _StatBox(title: 'Avg Time', value: 'N/A', color: Colors.orange),
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
  final bool hasReviews;

  const _RecentReviews({required this.hasReviews});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Reviews',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (!hasReviews)
          const Text(
            'No reviews yet.',
            style: TextStyle(color: AppColors.textLight),
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
