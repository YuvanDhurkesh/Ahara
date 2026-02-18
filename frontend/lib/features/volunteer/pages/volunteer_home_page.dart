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

                  // HEADER
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
                      _voiceModeToggle(),
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
  // VOICE MODE
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
      ),
      onPressed: _toggleVoiceMode,
    );
  }

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
            "Voice mode activated",
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
    } else if (lower.contains("order")) {
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
  // AVAILABILITY
  //----------------------------------------------------------

  Widget _availabilityToggle() {
    return Row(
      children: [
        Text(
          AppLocalizations.of(context)!
              .translate("availability"),
        ),
        const SizedBox(width: 8),
        Switch(
          value: isAvailable,
          activeColor: AppColors.primary,
          onChanged: (value) =>
              setState(() => isAvailable = value),
        ),
      ],
    );
  }

  //----------------------------------------------------------
  // INACTIVE UI
  //----------------------------------------------------------

  Widget _inactiveState() {
    return Container(
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
  // DASHBOARD CARDS
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
        _statCard("deliveries", "47",
            Colors.blue),
        _statCard("today", "3",
            Colors.green),
        _statCard("ratings", "4.8",
            Colors.orange),
      ],
    );
  }

  Widget _statCard(
      String key, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border:
            Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!
                .translate(key),
            style: const TextStyle(
                fontSize: 12,
                color: Colors.grey),
          ),
        ],
      ),
    );
  }

  //----------------------------------------------------------
  // BADGES
  //----------------------------------------------------------

  Widget _badgeSection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _badge(Icons.verified,
            'verified_volunteer'),
        _badge(Icons.star,
            'top_volunteer'),
        _badge(Icons.local_shipping,
            'fifty_deliveries'),
        _badge(Icons.flash_on,
            'perfect_streak'),
      ],
    );
  }

  Widget _badge(IconData icon, String key) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            AppColors.primary.withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16,
              color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context)!
                .translate(key),
            style: const TextStyle(
                fontSize: 12),
          ),
        ],
      ),
    );
  }

  //----------------------------------------------------------
  // QUICK ACTIONS
  //----------------------------------------------------------

  Widget _quickActions() {
    return Row(
      children: [
        _action(Icons.list_alt,
            const VolunteerOrdersPage()),
        const SizedBox(width: 12),
        _action(Icons.star,
            const VolunteerRatingsPage()),
        const SizedBox(width: 12),
        _action(Icons.person,
            const VolunteerProfilePage()),
      ],
    );
  }

  Widget _action(
      IconData icon, Widget page) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => page),
        ),
        child: Container(
          padding:
              const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(icon,
              size: 32,
              color: AppColors.primary),
        ),
      ),
    );
  }

  //----------------------------------------------------------
  // ALERT BANNER
  //----------------------------------------------------------

  Widget _alertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!
                  .translate('rescue_alert_banner'),
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //----------------------------------------------------------
  // RESCUE REQUESTS
  //----------------------------------------------------------

  Widget _rescueRequestsSection() {
    final auth =
        Provider.of<AppAuthProvider>(context,
            listen: false);
    final volunteerId =
        auth.mongoUser?['_id'];

    if (volunteerId == null)
      return const SizedBox.shrink();

    return FutureBuilder<
        List<Map<String, dynamic>>>(
      future: BackendService
          .getVolunteerRescueRequests(
              volunteerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const CircularProgressIndicator();

        final requests =
            snapshot.data ?? [];

        if (requests.isEmpty) {
          return const Text(
              "No active rescue requests nearby.");
        }

        return Column(
          children: requests
              .map((req) => ListTile(
                    title:
                        Text(req['title'] ??
                            "Rescue Request"),
                    trailing: ElevatedButton(
                      onPressed: () =>
                          BackendService
                              .acceptRescueRequest(
                                  req['data']
                                      ?['orderId'],
                                  volunteerId),
                      child:
                          const Text("Accept"),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
