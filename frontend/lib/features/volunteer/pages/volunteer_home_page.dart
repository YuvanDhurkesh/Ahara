import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/localization/language_provider.dart';
import '../../common/pages/landing_page.dart';
import 'volunteer_notifications_page.dart';
import 'volunteer_profile_page.dart';
import 'volunteer_ratings_page.dart';
import 'volunteer_orders_page.dart';
import '../../../data/services/backend_service.dart';

class VolunteerHomePage extends StatefulWidget {
  const VolunteerHomePage({super.key});

  @override
  State<VolunteerHomePage> createState() => _VolunteerHomePageState();
}

class _VolunteerHomePageState extends State<VolunteerHomePage> with SingleTickerProviderStateMixin {
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
  Timer? _pollingTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fetchVolunteerData();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && isAvailable) {
        _fetchVolunteerData(silent: true);
      }
    });
  }

  Future<void> _fetchVolunteerData({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

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
      final availability =
          auth.mongoProfile?['availability'] as Map<String, dynamic>?;
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
        isAvailable = availability?['isAvailable'] ?? true;
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
    final horizontalPadding = screenWidth < 380 ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: RefreshIndicator(
              onRefresh: () => _fetchVolunteerData(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  20,
                  horizontalPadding,
                  40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(userName.toString(), screenWidth),

                    const SizedBox(height: 32),

                    if (isAvailable) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionTitle(AppLocalizations.of(context)!.translate("your_statistics") ?? "Your Statistics"),
                          Text(
                            AppLocalizations.of(context)!.translate("last_updated_just_now") ?? "Last updated: Just now",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _dashboardCards(screenWidth),
                      
                      const SizedBox(height: 36),
                      _sectionTitle(AppLocalizations.of(context)!.translate("achievements") ?? "Achievements"),
                      const SizedBox(height: 16),
                      _badgeSection(),
                      
                      const SizedBox(height: 36),
                      _alertBanner(),
                      
                      const SizedBox(height: 32),
                      _sectionTitle(AppLocalizations.of(context)!.translate("quick_access") ?? "Quick Access"),
                      const SizedBox(height: 16),
                      _quickActions(screenWidth),

                      const SizedBox(height: 36),
                      _sectionTitle(AppLocalizations.of(context)!.translate("incoming_requests") ?? "Incoming Requests"),
                      const SizedBox(height: 16),
                      _rescueRequestsSection(),
                    ] else ...[
                      _inactiveState(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.ebGaramond(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1A1A1A),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildHeader(String userName, double width) {
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9E7E6B).withOpacity(0.1),
                blurRadius: 10,
              )
            ],
            image: const DecorationImage(
              image: NetworkImage("https://ui-avatars.com/api/?background=E67E22&color=fff&name=V"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAvailable ? (AppLocalizations.of(context)!.translate("online") ?? "Online") : (AppLocalizations.of(context)!.translate("away") ?? "Away"),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isAvailable ? Colors.green : Colors.grey.shade400,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                userName,
                style: GoogleFonts.ebGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch.adaptive(
            value: isAvailable,
            activeColor: AppColors.primary,
            onChanged: (value) async {
              setState(() => isAvailable = value);
              try {
                if (auth.currentUser != null) {
                  await BackendService.updateVolunteerAvailability(
                    auth.currentUser!.uid,
                    value,
                  );
                  await auth.refreshMongoUser();
                }
              } catch (e) {
                if (mounted) {
                  setState(() => isAvailable = !value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update: $e')),
                  );
                }
              }
            },
          ),
        ),
        const SizedBox(width: 4),
        _voiceModeIndicator(),
        const SizedBox(width: 8),
        _headerIconButton(Icons.notifications_none_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const VolunteerNotificationsPage()));
        }),
      ],
    );
  }

  Widget _voiceModeIndicator() {
    final voiceService = Provider.of<VoiceService>(context);
    final isActive = voiceService.isListening;
    
    return GestureDetector(
      onTap: _toggleVoiceMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF4B2B).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9E7E6B).withOpacity(0.05),
              blurRadius: 10,
            )
          ],
          border: Border.all(
            color: isActive ? const Color(0xFFFF4B2B).withOpacity(0.2) : Colors.grey.shade100,
          ),
        ),
        child: Row(
          children: [
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: RotationTransition(
                  turns: _pulseController,
                  child: const Icon(Icons.graphic_eq, size: 18, color: Color(0xFFFF4B2B)),
                ),
              ),
            Icon(
              isActive ? Icons.mic_rounded : Icons.mic_none_rounded,
              size: 22,
              color: isActive ? const Color(0xFFFF4B2B) : const Color(0xFF1A1A1A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9E7E6B).withOpacity(0.05),
              blurRadius: 10,
            )
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Icon(icon, size: 22, color: const Color(0xFF1A1A1A)),
      ),
    );
  }

  Widget _dashboardCards(double width) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9E7E6B).withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(AppLocalizations.of(context)!.translate("deliveries") ?? "Deliveries", _totalDeliveries.toString(), Icons.local_shipping_outlined, AppColors.primary),
          Container(height: 40, width: 1, color: Colors.grey.shade100),
          _statItem(AppLocalizations.of(context)!.translate("today") ?? "Today", _todayCount.toString(), Icons.calendar_today_outlined, const Color(0xFFE67E22)),
          Container(height: 40, width: 1, color: Colors.grey.shade100),
          _statItem(AppLocalizations.of(context)!.translate("rating") ?? "Rating", _avgRating.toStringAsFixed(1), Icons.star_border_rounded, const Color(0xFFD35400)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.ebGaramond(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _badgeSection() {
    final stats = context.watch<AppAuthProvider>().mongoProfile?['stats'] as Map<String, dynamic>?;
    final totalCompleted = (stats?['totalDeliveriesCompleted'] as num?)?.toInt() ?? 0;
    
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _badgeItem(Icons.verified_user_rounded, AppLocalizations.of(context)!.translate("verified") ?? "Verified", true),
          _badgeItem(Icons.auto_awesome_rounded, AppLocalizations.of(context)!.translate("top_star") ?? "Top Star", _avgRating >= 4.5),
          _badgeItem(Icons.local_fire_department_rounded, AppLocalizations.of(context)!.translate("20_club") ?? "20+ Club", totalCompleted >= 20),
          _badgeItem(Icons.handshake_rounded, AppLocalizations.of(context)!.translate("social_hero") ?? "Social Hero", totalCompleted >= 5),
        ],
      ),
    );
  }

  Widget _badgeItem(IconData icon, String label, bool active) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.grey.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        ),
        boxShadow: active ? [
          BoxShadow(
            color: const Color(0xFF9E7E6B).withOpacity(0.06),
            blurRadius: 10,
          )
        ] : null,
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: active ? AppColors.primary : Colors.grey.shade300,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF1A1A1A) : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertBanner() {
    if (_newRequests == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, const Color(0xFFD35400)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate("new_requests_nearby") ?? "New Requests Nearby",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "$_newRequests ${AppLocalizations.of(context)!.translate("tasks_waiting") ?? "tasks are waiting for you"}",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  Widget _rescueRequestsSection() {
    if (_rescueRequests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFF7ED)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9E7E6B).withOpacity(0.03),
              blurRadius: 20,
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.radar_rounded, size: 32, color: Color(0xFFE67E22)),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.translate("no_requests_nearby") ?? "No requests nearby",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context)!.translate("alerts_when_something_pops_up") ?? "You'll see alerts when something pops up",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _rescueRequests.map((req) => _rescueRequestCard(req)).toList(),
    );
  }

  Widget _rescueRequestCard(Map<String, dynamic> req) {
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    final volunteerId = auth.mongoUser?['_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9E7E6B).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.fastfood_rounded, color: Color(0xFFE67E22), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req['title'] ?? (AppLocalizations.of(context)!.translate("rescue_request") ?? "Rescue Request"),
                  style: GoogleFonts.ebGaramond(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: const Color(0xFF1A1A1A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  req['message'] ?? (AppLocalizations.of(context)!.translate("urgent_pickup_needed") ?? "Urgent pickup needed"),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _acceptRescueRequest(req['data']?['orderId'], volunteerId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
            child: Text(
              AppLocalizations.of(context)!.translate("accept") ?? "Accept",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(double width) {
    return Row(
      children: [
        _quickActionItem(Icons.receipt_long_rounded, AppLocalizations.of(context)!.translate("orders") ?? "Orders", const VolunteerOrdersPage()),
        const SizedBox(width: 16),
        _quickActionItem(Icons.auto_awesome_rounded, AppLocalizations.of(context)!.translate("badges") ?? "Badges", const VolunteerRatingsPage()),
        const SizedBox(width: 16),
        _quickActionItem(Icons.settings_suggest_rounded, AppLocalizations.of(context)!.translate("settings") ?? "Settings", const VolunteerProfilePage()),
      ],
    );
  }

  Widget _quickActionItem(IconData icon, String title, Widget page) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9E7E6B).withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inactiveState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9E7E6B).withOpacity(0.05),
            blurRadius: 40,
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.nightlight_round_rounded, size: 48, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context)!.translate("shift_is_off") ?? "Shift is Off",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Go Online to receive rescue requests and view your live statistics dashboard",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => isAvailable = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                "Go Online",
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
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
