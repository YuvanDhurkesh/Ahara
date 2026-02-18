/// File: volunteer_home_page.dart
/// Purpose: Operational command center for active volunteers.
/// 
/// Responsibilities:
/// - Displays real-time rescue requests and availability toggles
/// - Integrates voice-activated commands for hands-free logistics
/// - Visualizes volunteer impact through gamified badges and statistics
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/localization/language_provider.dart';
import '../../common/pages/landing_page.dart';
import 'volunteer_profile_page.dart';
import 'volunteer_ratings_page.dart';
import 'volunteer_orders_page.dart';
import '../../../data/services/backend_service.dart';
import 'package:google_fonts/google_fonts.dart';

/// Primary activity hub for monitoring and accepting food rescue missions.
/// 
/// Features:
/// - Real-time availability synchronization with the backend
/// - Voice-modal integration via [VoiceService]
/// - Dynamic request polling and notification banners
class VolunteerHomePage extends StatefulWidget {
  const VolunteerHomePage({super.key});

  @override
  State<VolunteerHomePage> createState() =>
      _VolunteerHomePageState();
}

class _VolunteerHomePageState
    extends State<VolunteerHomePage> {
  bool isAvailable = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final userName =
        auth.mongoUser?['name'] ?? "Volunteer";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 1000),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  //--------------------------------------------------
                  // Header
                  //--------------------------------------------------
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${AppLocalizations.of(context)!.translate("welcome_back_user")}$userName',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Voice Mode Toggle
                      _voiceModeToggle(),

                      // Availability Toggle
                      _availabilityToggle(),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (!isAvailable)
                    _inactiveState(),

                  if (isAvailable) ...[
                    _dashboardCards(),
                    const SizedBox(height: 20),
                    _badgeSection(),
                    const SizedBox(height: 24),
                    _alertBanner(),
                    const SizedBox(height: 24),
                    _rescueRequestsSection(),
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

  //----------------------------------------------------------
  // Voice Toggle
  //----------------------------------------------------------

  Widget _voiceModeToggle() {
    final voiceService =
        Provider.of<VoiceService>(context);

    return IconButton(
      icon: Icon(
        voiceService.isListening
            ? Icons.mic
            : Icons.mic_none,
        color: voiceService.isListening
            ? Colors.red
            : AppColors.primary,
        size: 28,
      ),
      onPressed: () => _toggleVoiceMode(),
      tooltip: "Voice Assistance",
    );
  }

  /// Toggles the voice interface and synchronizes with [LanguageProvider] for TTS/STT locale.
  void _toggleVoiceMode() async {
    final voiceService =
        Provider.of<VoiceService>(context,
            listen: false);
    final langProvider =
        Provider.of<LanguageProvider>(context,
            listen: false);

    if (voiceService.isListening) {
      await voiceService.stopListening();
    } else {
      await voiceService.speak(
        AppLocalizations.of(context)!
                .translate("voice_mode_on") ??
            "Voice mode activated. How can I help?",
        languageCode:
            langProvider.locale.languageCode,
      );

      voiceService.startListening((words) {
        _handleVoiceCommand(words);
      });
    }
  }

  void _handleVoiceCommand(String words) {
    final lower = words.toLowerCase();
    final voiceService =
        Provider.of<VoiceService>(context,
            listen: false);

    if (lower.contains("logout")) {
      _performLogout();
    } else if (lower.contains("profile")) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                const VolunteerProfilePage()),
      );
    } else if (lower.contains("rating")) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                const VolunteerRatingsPage()),
      );
    } else if (lower.contains("deliver") ||
        lower.contains("order")) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                const VolunteerOrdersPage()),
      );
    } else if (lower.contains("available")) {
      setState(() => isAvailable = true);
    } else if (lower.contains("unavailable")) {
      setState(() => isAvailable = false);
    } else if (lower.contains("refresh")) {
      setState(() {});
    }
  }

  Future<void> _performLogout() async {
    await Provider.of<AppAuthProvider>(context,
            listen: false)
        .logout();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) =>
                const LandingPage()),
        (route) => false,
      );
    }
  }

  //----------------------------------------------------------
  // Availability
  //----------------------------------------------------------

  Widget _availabilityToggle() {
    return Row(
      children: [
        Text(
          AppLocalizations.of(context)!
              .translate("availability"),
          style: const TextStyle(
              fontWeight: FontWeight.w500),
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

  //----------------------------------------------------------
  // Inactive UI
  //----------------------------------------------------------

  Widget _inactiveState() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.pause_circle_outline,
              color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!
                  .translate('inactive_msg'),
              style:
                  const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  //----------------------------------------------------------
  // Dashboard Cards
  //----------------------------------------------------------

  Widget _dashboardCards() {
    return GridView.count(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _StatCard(
            title: AppLocalizations.of(context)!
                .translate("deliveries"),
            value: '47',
            color: Colors.blue),
        _StatCard(
            title: AppLocalizations.of(context)!
                .translate("today"),
            value: '3',
            color: Colors.green),
        _StatCard(
            title: AppLocalizations.of(context)!
                .translate("ratings"),
            value: '4.8',
            color: Colors.orange),
      ],
    );
  }

  //----------------------------------------------------------
  // Badge Section
  //----------------------------------------------------------

  Widget _badgeSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!
              .translate("your_badges"),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _BadgeChip(
                icon: Icons.verified,
                label: AppLocalizations.of(
                        context)!
                    .translate(
                        'verified_volunteer')),
            _BadgeChip(
                icon: Icons.star,
                label: AppLocalizations.of(
                        context)!
                    .translate(
                        'top_volunteer')),
            _BadgeChip(
                icon: Icons.local_shipping,
                label: AppLocalizations.of(
                        context)!
                    .translate(
                        'fifty_deliveries')),
            _BadgeChip(
                icon: Icons.flash_on,
                label: AppLocalizations.of(
                        context)!
                    .translate(
                        'perfect_streak')),
          ],
        ),
      ],
    );
  }

  //----------------------------------------------------------
  // Alert Banner
  //----------------------------------------------------------

  Widget _alertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFFFD066)),
      ),
      child: Row(
        children: [
          const Icon(
              Icons.notifications_active,
              color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!
                  .translate(
                      'new_requests_banner'),
              style: const TextStyle(
                  fontWeight:
                      FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  //----------------------------------------------------------
  // Quick Actions
  //----------------------------------------------------------

  //----------------------------------------------------------
  // Rescue Requests Section
  //----------------------------------------------------------

  /// Conditional listing of nearby rescue requests fetched from [BackendService].
  Widget _rescueRequestsSection() {
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    final volunteerId = auth.mongoUser?['_id'];

    if (volunteerId == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rescue Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => setState(() {}),
              child: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: BackendService.getVolunteerRescueRequests(volunteerId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
            }

            final requests = snapshot.data ?? [];
            if (requests.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text('No active rescue requests nearby.', textAlign: TextAlign.center),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = requests[index];
                final orderId = req['data']?['orderId'];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFFFEBEE),
                        child: Icon(Icons.emergency, color: Colors.red),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(req['title'] ?? 'Rescue Request', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(req['message'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _acceptRescueRequest(orderId, volunteerId),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Accept', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _acceptRescueRequest(String orderId, String volunteerId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await BackendService.acceptRescueRequest(orderId, volunteerId);

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rescue request accepted! Go to My Orders to track.')),
        );
        setState(() {}); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _quickActions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!
              .translate(
                  "quick_actions"),
          style: const TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAction(
                icon: Icons.list_alt,
                label: AppLocalizations.of(
                        context)!
                    .translate(
                        "view_orders")),
            const SizedBox(width: 12),
            _QuickAction(
                icon:
                    Icons.verified_user,
                label: AppLocalizations.of(
                        context)!
                    .translate(
                        "verification")),
            const SizedBox(width: 12),
            _QuickAction(
                icon: Icons.star,
                label: AppLocalizations.of(
                        context)!
                    .translate(
                        "ratings")),
          ],
        ),
      ],
    );
  }

  //----------------------------------------------------------
  // Helper Widgets
  //----------------------------------------------------------

  Widget _StatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _BadgeChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _QuickAction({
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          // Handle action tap
          if (label.contains('order') || label.contains('Order')) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VolunteerOrdersPage()),
            );
          } else if (label.contains('rating') || label.contains('Rating')) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VolunteerRatingsPage()),
            );
          } else if (label.contains('profile') || label.contains('Profile')) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VolunteerProfilePage()),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
