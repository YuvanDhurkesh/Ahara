import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    final verification = auth.mongoProfile?['verification'] as Map<String, dynamic>?;
    final isVerifiedDoc = (verification?['idProof']?['verified'] as bool?) ?? false;
    final isVerifiedAadhaar = (verification?['aadhaar']?['verified'] as bool?) ?? false;
    final isLevelVerified = (verification?['level'] as num? ?? 0) > 0;
    
    final isVerified = ((auth.mongoProfile?['badge']?['tickVerified'] as bool?) ?? false) || 
                       isVerifiedDoc || 
                       isVerifiedAadhaar || 
                       isLevelVerified;
    
    final topVolunteer = avgRating >= 4.5 && totalCompleted >= 10;
    final fiftyDeliveries = totalCompleted >= 50;
    final perfectStreak =
        totalCompleted > 0 && totalFailed == 0 && noShows == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1A1A1A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ratings & Badges',
          style: GoogleFonts.ebGaramond(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OverallRatingCard(
              avgRating: avgRating,
              deliveries: totalCompleted,
              ratingCount: ratingCount,
            ),
            const SizedBox(height: 32),
            _BadgesSection(
              isVerified: isVerified,
              topVolunteer: topVolunteer,
              fiftyDeliveries: fiftyDeliveries,
              perfectStreak: perfectStreak,
            ),
            const SizedBox(height: 32),
            _sectionLabel("Performance"),
            const SizedBox(height: 16),
            _PerformanceStats(onTimeRate: onTimeRate, successRate: successRate),
            const SizedBox(height: 32),
            _sectionLabel("Recent Feedback"),
            _RecentReviews(hasReviews: false),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.5,
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
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9E7E6B).withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              avgRating.toStringAsFixed(1),
              style: GoogleFonts.ebGaramond(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -1,
              ),
            ),
            Text(
              'Average Rating',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Based on $deliveries deliveries',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey.shade300,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
        Text(
          'Your Achievements',
          style: GoogleFonts.ebGaramond(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _BadgeCard(
              icon: Icons.verified_rounded,
              label: 'Verified',
              isActive: isVerified,
              activeColor: const Color(0xFFFEEDE1), // Rich warm orange-tinted ivory
            ),
            _BadgeCard(
              icon: Icons.auto_awesome_rounded,
              label: 'Top Volunteer',
              isActive: topVolunteer,
            ),
            _BadgeCard(
              icon: Icons.local_shipping_rounded,
              label: '50+ Deliveries',
              isActive: fiftyDeliveries,
            ),
            _BadgeCard(
              icon: Icons.bolt_rounded,
              label: 'Perfect Streak',
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
  final Color? activeColor;

  const _BadgeCard({
    required this.icon,
    required this.label,
    required this.isActive,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive 
          ? (activeColor ?? const Color(0xFFFEF3EB)) 
          : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive 
            ? (activeColor?.withOpacity(0.8) ?? AppColors.primary.withOpacity(0.4)) 
            : const Color(0xFF9E7E6B).withOpacity(0.12),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: (activeColor ?? const Color(0xFF9E7E6B)).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? (activeColor != null ? Colors.orange.shade800 : AppColors.primary) : Colors.grey.shade300,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? const Color(0xFF1A1A1A) : Colors.grey.shade400,
              height: 1.2,
            ),
          ),
        ],
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
          title: 'On-Time',
          value: '${(onTimeRate * 100).toStringAsFixed(0)}%',
          color: Colors.green,
          icon: Icons.timer_rounded,
        ),
        const SizedBox(width: 16),
        _StatBox(
          title: 'Success',
          value: '${(successRate * 100).toStringAsFixed(0)}%',
          color: Colors.blue,
          icon: Icons.check_circle_rounded,
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9E7E6B).withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.ebGaramond(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade400,
              ),
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
        Text(
          'Recent Reviews',
          style: GoogleFonts.ebGaramond(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 16),
        if (!hasReviews)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9E7E6B).withOpacity(0.04),
                  blurRadius: 20,
                )
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF7ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 32, color: Color(0xFFE67E22)),
                ),
                const SizedBox(height: 16),
                Text(
                  "No reviews yet",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Complete more deliveries to see feedback",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade300,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9E7E6B).withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Text(
                date,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (index) => const Icon(Icons.star_rounded,
                  size: 16, color: Color(0xFFF1C40F)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            review,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
