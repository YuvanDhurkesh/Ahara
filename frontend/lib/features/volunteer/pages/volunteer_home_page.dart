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
  State<VolunteerHomePage> createState() => _VolunteerHomePageState();
}

class _VolunteerHomePageState extends State<VolunteerHomePage> {
  bool isAvailable = true;
  bool _isLoading = true;
  String? _error;

  int _newRequests = 0;
  int _activeCount = 0;
  int _completedCount = 0;
  int _todayCount = 0;
  int _totalDeliveries = 0;
  double _avgRating = 0;

  List<Map<String, dynamic>> _rescueRequests = [];
  List<Map<String, dynamic>> _volunteerOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchVolunteerData();
  }

  Future<void> _fetchVolunteerData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AppAuthProvider>(context, listen: false);
      if (auth.mongoUser == null && auth.currentUser != null) {
        await auth.refreshMongoUser();
      }

      final volunteerId = auth.mongoUser?['_id'];
      if (volunteerId == null) {
        throw Exception("Unable to load volunteer profile");
      }

      final requests = await BackendService.getVolunteerRescueRequests(
        volunteerId,
      );
      final orders = await BackendService.getVolunteerOrders(volunteerId);

      final activeStatuses = {
        "volunteer_assigned",
        "volunteer_accepted",
        "picked_up",
        "in_transit",
      };

      int activeCount = 0;
      int completedCount = 0;
      int todayCount = 0;

      for (final order in orders) {
        final status = (order['status'] ?? '').toString();

        if (activeStatuses.contains(status)) {
          activeCount += 1;
        }

        if (status == 'delivered') {
          completedCount += 1;
        }

        final dateSource =
            order['timeline']?['deliveredAt'] ?? order['createdAt'];
        if (_isToday(dateSource)) {
          todayCount += 1;
        }
      }

      final stats = auth.mongoProfile?['stats'] as Map<String, dynamic>?;
      final avgRating = (stats?['avgRating'] as num?)?.toDouble() ?? 0;
      final totalDeliveries =
          (stats?['totalDeliveriesCompleted'] as num?)?.toInt() ?? 0;

      if (!mounted) return;
      setState(() {
        _rescueRequests = requests;
        _volunteerOrders = orders;
        _newRequests = requests.length;
        _activeCount = activeCount;
        _completedCount = completedCount;
        _todayCount = todayCount;
        _avgRating = avgRating;
        _totalDeliveries = totalDeliveries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final userName = auth.mongoUser?['name'] ?? "Volunteer";
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 380 ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(userName.toString(), screenWidth),

                  const SizedBox(height: 20),

                  if (!isAvailable) _inactiveState(),

                  if (isAvailable) ...[
                    _dashboardCards(screenWidth),
                    const SizedBox(height: 20),
                    _badgeSection(),
                    const SizedBox(height: 24),
                    _alertBanner(),
                    const SizedBox(height: 24),
                    _rescueRequestsSection(),
                    const SizedBox(height: 24),
                    _quickActions(screenWidth),
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

  Widget _buildHeader(String userName, double width) {
    final isNarrow = width < 520;

    final title = Text(
      '${AppLocalizations.of(context)!.translate("welcome_back_user")}$userName',
      style: TextStyle(
        fontSize: isNarrow ? 20 : 24,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 10),
          Row(
            children: [
              _voiceModeToggle(),
              const Spacer(),
              _availabilityToggle(),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        _voiceModeToggle(),
        _availabilityToggle(),
      ],
    );
  }

  Widget _voiceModeToggle() {
    final voiceService = Provider.of<VoiceService>(context);

    return IconButton(
      icon: Icon(
        voiceService.isListening ? Icons.mic : Icons.mic_none,
        color: voiceService.isListening ? Colors.red : AppColors.primary,
      ),
      onPressed: _toggleVoiceMode,
    );
  }

  void _toggleVoiceMode() async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (voiceService.isListening) {
      await voiceService.stopListening();
    } else {
      await voiceService.speak(
        AppLocalizations.of(context)!.translate("voice_mode_on") ??
            "Voice mode activated",
        languageCode: langProvider.locale.languageCode,
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
        MaterialPageRoute(builder: (_) => const VolunteerProfilePage()),
      );
    } else if (lower.contains("rating")) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VolunteerRatingsPage()),
      );
    } else if (lower.contains("order")) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VolunteerOrdersPage()),
      );
    } else if (lower.contains("available")) {
      setState(() => isAvailable = true);
    } else if (lower.contains("unavailable")) {
      setState(() => isAvailable = false);
    }
  }

  Future<void> _performLogout() async {
    await Provider.of<AppAuthProvider>(context, listen: false).logout();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingPage()),
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
        Text(AppLocalizations.of(context)!.translate("availability")),
        const SizedBox(width: 8),
        Switch(
          value: isAvailable,
          activeColor: AppColors.primary,
          onChanged: (value) => setState(() => isAvailable = value),
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

  //----------------------------------------------------------
  // DASHBOARD CARDS
  //----------------------------------------------------------

  Widget _dashboardCards(double width) {
    int crossAxisCount = 3;
    if (width < 520) {
      crossAxisCount = 1;
    } else if (width < 820) {
      crossAxisCount = 2;
    }

    double childAspectRatio;
    if (crossAxisCount == 1) {
      childAspectRatio = 3.4;
    } else if (crossAxisCount == 2) {
      childAspectRatio = 2.5;
    } else {
      childAspectRatio = 2.0;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: childAspectRatio,
      children: [
        _statCard(
          "deliveries",
          _isLoading ? "..." : _totalDeliveries.toString(),
          Colors.blue,
          width,
        ),
        _statCard(
          "today",
          _isLoading ? "..." : _todayCount.toString(),
          Colors.green,
          width,
        ),
        _statCard(
          "ratings",
          _isLoading ? "..." : _avgRating.toStringAsFixed(1),
          Colors.orange,
          width,
        ),
      ],
    );
  }

  Widget _statCard(String key, String value, Color color, double width) {
    final compact = width < 380;

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
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
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.translate(key),
            style: TextStyle(fontSize: compact ? 11 : 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  //----------------------------------------------------------
  // BADGES
  //----------------------------------------------------------

  Widget _badgeSection() {
    final stats =
        context.watch<AppAuthProvider>().mongoProfile?['stats']
            as Map<String, dynamic>?;
    final badgeData =
        context.watch<AppAuthProvider>().mongoProfile?['badge']
            as Map<String, dynamic>?;

    final totalCompleted =
        (stats?['totalDeliveriesCompleted'] as num?)?.toInt() ?? 0;
    final failed = (stats?['totalDeliveriesFailed'] as num?)?.toInt() ?? 0;
    final noShows = (stats?['noShows'] as num?)?.toInt() ?? 0;
    final avgRating = (stats?['avgRating'] as num?)?.toDouble() ?? 0;

    final isVerified = (badgeData?['tickVerified'] as bool?) ?? false;
    final topVolunteer = avgRating >= 4.5 && totalCompleted >= 10;
    final fiftyDeliveries = totalCompleted >= 50;
    final perfectStreak = totalCompleted > 0 && failed == 0 && noShows == 0;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _badge(Icons.verified, 'verified_volunteer', isActive: isVerified),
        _badge(Icons.star, 'top_volunteer', isActive: topVolunteer),
        _badge(
          Icons.local_shipping,
          'fifty_deliveries',
          isActive: fiftyDeliveries,
        ),
        _badge(Icons.flash_on, 'perfect_streak', isActive: perfectStreak),
      ],
    );
  }

  Widget _badge(IconData icon, String key, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.12) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? AppColors.primary : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context)!.translate(key),
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.primary : Colors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  //----------------------------------------------------------
  // QUICK ACTIONS
  //----------------------------------------------------------

  Widget _quickActions(double width) {
    final cardWidth = width < 520 ? (width - 48) / 2 : (width - 56) / 3;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _action(Icons.list_alt, const VolunteerOrdersPage(), width: cardWidth),
        _action(Icons.star, const VolunteerRatingsPage(), width: cardWidth),
        _action(Icons.person, const VolunteerProfilePage(), width: cardWidth),
      ],
    );
  }

  Widget _action(IconData icon, Widget page, {double? width}) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 32, color: AppColors.primary),
        ),
      ),
    );
  }

  //----------------------------------------------------------
  // ALERT BANNER
  //----------------------------------------------------------

  Widget _alertBanner() {
    final bannerText = _newRequests > 0
        ? 'You have $_newRequests new delivery request${_newRequests == 1 ? '' : 's'} waiting!'
        : 'No new delivery requests right now.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              bannerText,
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
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    final volunteerId = auth.mongoUser?['_id'];

    if (volunteerId == null) return const SizedBox.shrink();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Text("Error: $_error", style: const TextStyle(color: Colors.red));
    }

    if (_rescueRequests.isEmpty) {
      return const Text("No active rescue requests nearby.");
    }

    return Column(
      children: _rescueRequests
          .map(
            (req) => ListTile(
              title: Text(req['title'] ?? "Rescue Request"),
              subtitle: Text(req['message'] ?? ""),
              trailing: ElevatedButton(
                onPressed: () =>
                    _acceptRescueRequest(req['data']?['orderId'], volunteerId),
                child: const Text("Accept"),
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _acceptRescueRequest(String? orderId, String volunteerId) async {
    if (orderId == null) return;

    try {
      await BackendService.acceptRescueRequest(orderId, volunteerId);
      await _fetchVolunteerData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to accept request: $e')));
    }
  }

  bool _isToday(dynamic value) {
    if (value == null) return false;
    try {
      final date = DateTime.parse(value.toString());
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    } catch (_) {
      return false;
    }
  }
}
