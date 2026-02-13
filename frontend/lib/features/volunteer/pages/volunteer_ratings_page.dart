import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../data/services/gamification_service.dart';
import '../../../data/providers/app_auth_provider.dart';

class VolunteerRatingsPage extends StatefulWidget {
  const VolunteerRatingsPage({super.key});

  @override
  State<VolunteerRatingsPage> createState() => _VolunteerRatingsPageState();
}

class _VolunteerRatingsPageState extends State<VolunteerRatingsPage> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = context.read<AppAuthProvider>().currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      // Assuming gamification service returns { points, level, badges, trustScore }
      // If service is not fully ready, we might get an error, so we handle it.
      final data = await GamificationService().getGamificationProfile(user.uid);
      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
         // Fallback to empty data on error for now
        setState(() => _isLoading = false);
        // debugPrint("Error fetching gamification profile: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Default values if data is missing
    final int points = _profileData != null ? (_profileData!['points'] ?? 0) : 0;
    final int level = _profileData != null ? (_profileData!['level'] ?? 1) : 1;
    final List<dynamic> badgesData = _profileData != null ? (_profileData!['badges'] ?? []) : [];
    final List<String> badges = badgesData.map((e) => e.toString()).toList();
    final int trustScore = _profileData != null ? (_profileData!['trustScore'] ?? 0) : 0;
    
    // Trust Score (0-100) to Rating (0-5)
    // Example: 100 -> 5.0, 80 -> 4.0
    final String rating = (trustScore / 20.0).toStringAsFixed(1);


    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Ratings & Badges - Level $level',
          style: const TextStyle(
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
            _OverallRatingCard(rating: rating, points: points),
            const SizedBox(height: 20),
            _BadgesSection(userBadges: badges),
            const SizedBox(height: 20),
            _PerformanceStats(trustScore: trustScore),
            const SizedBox(height: 20),
            const _RecentReviews(),
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
  final String rating;
  final int points;

  const _OverallRatingCard({required this.rating, required this.points});

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 40),
          const SizedBox(height: 8),
          Center(
            child: Text(
              rating,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Trust Score Rating',
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
           const SizedBox(height: 12),
           Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$points Points Earned',
                 style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
  final List<String> userBadges;

  const _BadgesSection({required this.userBadges});

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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Example mapping of Badge Names to Icons
            _BadgeCard(
              icon: Icons.verified,
              label: 'Newcomer',
              isActive: userBadges.contains('Newcomer'),
            ),
             _BadgeCard(
              icon: Icons.volunteer_activism, // Changed icon
              label: 'Generous Giver',
               isActive: userBadges.contains('Generous Giver'),
            ),
             _BadgeCard(
              icon: Icons.recycling, // Changed icon
              label: 'Zero Waste Hero',
               isActive: userBadges.contains('Zero Waste Hero'),
            ),
             // Assuming we have these badges
            // _BadgeCard(
            //   icon: Icons.local_shipping,
            //   label: '50\nDeliveries',
            //   isActive: false,
            // ),
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
        margin: const EdgeInsets.symmetric(horizontal: 4),
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
  final int trustScore;
  const _PerformanceStats({required this.trustScore});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
         _StatBox(title: 'Trust Score', value: '$trustScore', color: Colors.green),
        const SizedBox(width: 12),
        // Placeholder stats
        const _StatBox(title: 'Success Rate', value: '100%', color: Colors.blue),
        const SizedBox(width: 12),
        const _StatBox(title: 'Level', value: '1', color: Colors.orange),
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
        Text("No reviews yet.", style: TextStyle(color: AppColors.textLight)),
         // Placeholder for real reviews when backend supports it
        // _ReviewTile(
        //   name: 'Sarah Johnson',
        //   date: 'Feb 3',
        //   review: 'Very professional and on time!',
        // ),
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
