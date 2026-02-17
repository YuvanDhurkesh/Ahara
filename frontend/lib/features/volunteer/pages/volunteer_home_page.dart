import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/localization/language_provider.dart';
import '../../common/pages/landing_page.dart';
import '../../../data/providers/app_auth_provider.dart';
import 'volunteer_profile_page.dart';
import 'volunteer_ratings_page.dart';
import 'volunteer_orders_page.dart';

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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.translate("welcome_back_user")}${Provider.of<AppAuthProvider>(context).mongoUser?['name'] ?? "Volunteer"}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      // Voice Mode Toggle
                      _voiceModeToggle(),
                      
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
        ),
      ),
    );
  }

  // ---------------- Widgets ----------------

  Widget _voiceModeToggle() {
    final voiceService = Provider.of<VoiceService>(context);
    return IconButton(
      icon: Icon(
        voiceService.isListening ? Icons.mic : Icons.mic_none,
        color: voiceService.isListening ? Colors.red : AppColors.primary,
        size: 28,
      ),
      onPressed: () => _toggleVoiceMode(),
      tooltip: "Voice Assistance",
    );
  }

  void _toggleVoiceMode() async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (voiceService.isListening) {
      await voiceService.stopListening();
    } else {
      await voiceService.speak(
        AppLocalizations.of(context)!.translate("voice_mode_on") ?? "Voice mode activated. How can I help?",
        languageCode: langProvider.locale.languageCode,
      );
      
      voiceService.startListening((words) {
        _handleVoiceCommand(words);
      });
    }
  }

  void _handleVoiceCommand(String words) {
    debugPrint("Recognized words: $words");
    final lowerWords = words.toLowerCase();
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    
    if (lowerWords.contains("help")) {
      voiceService.speak("You can say: Logout, Profile, Ratings, Deliveries, Orders, Available, Unavailable, or Refresh.");
    } else if (lowerWords.contains("logout")) {
      voiceService.speak("Logging out...");
      _performLogout();
    } else if (lowerWords.contains("profile")) {
      voiceService.speak("Opening profile");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VolunteerProfilePage()),
      );
    } else if (lowerWords.contains("rating")) {
      voiceService.speak("Opening ratings");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VolunteerRatingsPage()),
      );
    } else if (lowerWords.contains("deliver") || lowerWords.contains("order")) {
      voiceService.speak("Opening deliveries");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VolunteerOrdersPage()),
      );
    } else if (lowerWords.contains("available")) {
      if (lowerWords.contains("un")) {
        setState(() => isAvailable = false);
        voiceService.speak("You are now unavailable");
      } else {
        setState(() => isAvailable = true);
        voiceService.speak("You are now available");
      }
    } else if (lowerWords.contains("refresh")) {
      voiceService.speak("Refreshing dashboard.");
      setState(() {});
    }
  }

  Future<void> _performLogout() async {
    await Provider.of<AppAuthProvider>(context, listen: false).logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (route) => false,
      );
    }
  }

  Widget _availabilityToggle() {
    return Row(
      children: [
        Text(
          AppLocalizations.of(context)!.translate("availability"),
          style: const TextStyle(fontWeight: FontWeight.w500),
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
        children: [
          const Icon(Icons.pause_circle_outline, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.translate('inactive_msg'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 600;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWide ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWide ? 2.5 : 1.5,
          children: [
            _StatCard(title: AppLocalizations.of(context)!.translate("deliveries"), value: '47', color: Colors.blue),
            _StatCard(title: AppLocalizations.of(context)!.translate("today"), value: '3', color: Colors.green),
            _StatCard(title: AppLocalizations.of(context)!.translate("ratings"), value: '4.8', color: Colors.orange),
          ],
        );
      },
    );
  }

  Widget _badgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate("your_badges"),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _BadgeChip(icon: Icons.verified, label: AppLocalizations.of(context)!.translate('verified_volunteer')),
            _BadgeChip(icon: Icons.star, label: AppLocalizations.of(context)!.translate('top_volunteer')),
            _BadgeChip(icon: Icons.local_shipping, label: AppLocalizations.of(context)!.translate('fifty_deliveries')),
            _BadgeChip(icon: Icons.flash_on, label: AppLocalizations.of(context)!.translate('perfect_streak')),
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
        children: [
          const Icon(Icons.notifications_active, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.translate('new_requests_banner'),
              style: const TextStyle(fontWeight: FontWeight.w500),
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
        Text(
          AppLocalizations.of(context)!.translate("quick_actions"),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAction(icon: Icons.list_alt, label: AppLocalizations.of(context)!.translate("view_orders")),
            const SizedBox(width: 12),
            _QuickAction(icon: Icons.verified_user, label: AppLocalizations.of(context)!.translate("verification")),
            const SizedBox(width: 12),
            _QuickAction(icon: Icons.star, label: AppLocalizations.of(context)!.translate("ratings")),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
