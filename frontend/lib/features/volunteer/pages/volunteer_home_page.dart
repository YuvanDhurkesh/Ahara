import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';

class VolunteerHomePage extends StatefulWidget {
  const VolunteerHomePage({super.key});

  @override
  State<VolunteerHomePage> createState() => _VolunteerHomePageState();
}

class _VolunteerHomePageState extends State<VolunteerHomePage> {
  bool isAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hi, Demo Volunteer',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  // Availability Toggle
                  _availabilityToggle(),
                ],
              ),

              const SizedBox(height: 20),

              // 🚫 If NOT available
              if (!isAvailable) _inactiveState(),

              // ✅ If available
              if (isAvailable) ...[
                _dashboardCards(),
                const SizedBox(height: 20),
                _badgeSection(),
                const SizedBox(height: 24),
                _alertBanner(),
                const SizedBox(height: 24),
                _quickActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Widgets ----------------

  Widget _availabilityToggle() {
    return Row(
      children: [
        const Text(
          'Availability',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        Switch(
          value: isAvailable,
          activeColor: AppColors.primary,
          onChanged: (value) {
            setState(() {
              isAvailable = value;
            });
          },
        ),
      ],
    );
  }

  Widget _inactiveState() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: const [
          Icon(Icons.pause_circle_outline, color: Colors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'You are currently inactive.\nTurn on availability to receive deliveries and view performance.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardCards() {
    return Row(
      children: const [
        _StatCard(title: 'Total Deliveries', value: '47', color: Colors.blue),
        SizedBox(width: 12),
        _StatCard(title: 'Today', value: '3', color: Colors.green),
        SizedBox(width: 12),
        _StatCard(title: 'Rating', value: '4.8', color: Colors.orange),
      ],
    );
  }

  Widget _badgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Badges',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _BadgeChip(icon: Icons.verified, label: 'Verified Volunteer'),
            _BadgeChip(icon: Icons.star, label: 'Top Volunteer'),
            _BadgeChip(icon: Icons.local_shipping, label: '50 Deliveries'),
            _BadgeChip(icon: Icons.flash_on, label: 'Perfect Streak'),
          ],
        ),
      ],
    );
  }

  Widget _alertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD066)),
      ),
      child: Row(
        children: const [
          Icon(Icons.notifications_active, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'You have 2 new delivery requests waiting!',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            _QuickAction(icon: Icons.list_alt, label: 'View Orders'),
            SizedBox(width: 12),
            _QuickAction(icon: Icons.verified_user, label: 'Verification'),
            SizedBox(width: 12),
            _QuickAction(icon: Icons.star, label: 'Ratings'),
          ],
        ),
      ],
    );
  }
}

// ---------------- Reusable UI ----------------

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BadgeChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(label),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
