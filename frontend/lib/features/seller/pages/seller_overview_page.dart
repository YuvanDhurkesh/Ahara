import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../shared/styles/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/simplified_dashboard_wrapper.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';
import '../../common/pages/landing_page.dart';
import 'simplified_seller_home.dart';
import 'seller_notifications_page.dart';

class SellerOverviewPage extends StatefulWidget {
  const SellerOverviewPage({super.key});

  @override
  State<SellerOverviewPage> createState() => _SellerOverviewPageState();
}

class _SellerOverviewPageState extends State<SellerOverviewPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      
      // Ensure mongoUser is refreshed if not available
      if (authProvider.mongoUser == null) {
        await authProvider.refreshMongoUser();
      }

      var sellerId = authProvider.mongoUser?['_id'];

      if (sellerId == null) {
        throw Exception("Unable to load user profile. Please log in again.");
      }

      final stats = await BackendService.getSellerStats(sellerId);

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimplifiedDashboardWrapper(
      simplifiedDashboard: const SimplifiedSellerHome(),
      standardDashboard: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: _fetchStats,
          color: AppColors.primary,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),

                      // STATS GRID
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        )
                      else if (_error != null)
                        _buildErrorState()
                      else
                        _buildStatsGrid(),

                      const SizedBox(height: 32),

                      Text(
                        AppLocalizations.of(context)!.translate("recent_activity"),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRecentActivityList(),
                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final userName = authProvider.mongoUser?['name'] ?? "Seller";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${AppLocalizations.of(context)!.translate("welcome_back_user")}$userName",
                style: GoogleFonts.inter(
                  color: AppColors.textLight.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.translate("seller_dashboard"),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  fontSize: 20,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SellerNotificationsPage(),
                  ),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textDark,
                  size: 20,
                ),
              ),
              tooltip: "Notifications",
            ),
            IconButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LandingPage(),
                  ),
                  (route) => false,
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.logout,
                  color: AppColors.textDark,
                  size: 20,
                ),
              ),
              tooltip: "Logout",
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 12),
          Text(
            "Failed to load statistics",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _error ?? "Unknown error",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchStats,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
        final double childAspectRatio = constraints.maxWidth > 700 ? 1.6 : 1.4;

        final activeListings = _stats?['activeListings']?.toString() ?? "0";
        final pendingOrders = _stats?['pendingOrders']?.toString() ?? "0";
        final avgRating = _stats?['avgRating']?.toStringAsFixed(1) ?? "0.0";
        final earnings = _stats?['monthlyEarnings'] ?? 0;
        final earningsText = earnings >= 1000 
            ? "₹${(earnings / 1000).toStringAsFixed(1)}k" 
            : "₹$earnings";

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              context,
              AppLocalizations.of(context)!.translate("active_listings"),
              activeListings,
              Icons.inventory_2_rounded,
              const [Color(0xFF6B8E23), Color(0xFF8DB600)],
            ),
            _buildStatCard(
              context,
              AppLocalizations.of(context)!.translate("pending_orders"),
              pendingOrders,
              Icons.pending_actions_rounded,
              const [Color(0xFFCD853F), Color(0xFFD2B48C)],
            ),
            _buildStatCard(
              context,
              AppLocalizations.of(context)!.translate("avg_rating"),
              avgRating,
              Icons.star_rounded,
              const [Color(0xFF2E8B57), Color(0xFF3CB371)],
            ),
            _buildStatCard(
              context,
              AppLocalizations.of(context)!.translate("monthly_earnings"),
              earningsText,
              Icons.account_balance_wallet_rounded,
              const [Color(0xFF4682B4), Color(0xFF5F9EA0)],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivityList() {
    // Note: These will remain static as per the design for now, 
    // or we could implement an activity feed later.
    final List<Map<String, dynamic>> activities = [
      {
        'title': AppLocalizations.of(context)!.translate("new_order_received"),
        'subtitle': 'Mixed Veg Curry • 2 portions',
        'time': '10 ${AppLocalizations.of(context)!.translate("mins_ago")}',
        'icon': Icons.shopping_basket_rounded,
        'color': Colors.orange,
      },
      {
        'title': AppLocalizations.of(context)!.translate("listing_expiring_soon"),
        'subtitle': 'Organic Carrots • 1.5 kg remaining',
        'time': '2 ${AppLocalizations.of(context)!.translate("hours_ago")}',
        'icon': Icons.timer_outlined,
        'color': Colors.redAccent,
      },
      {
        'title': AppLocalizations.of(context)!.translate("payment_confirmed"),
        'subtitle': '₹450 credited to wallet',
        'time': '5 ${AppLocalizations.of(context)!.translate("hours_ago")}',
        'icon': Icons.check_circle_outline_rounded,
        'color': Colors.green,
      },
      {
        'title': AppLocalizations.of(context)!.translate("new_feedback"),
        'subtitle': '⭐⭐⭐⭐⭐ "Fresh and delicious!"',
        'time': AppLocalizations.of(context)!.translate("yesterday"),
        'icon': Icons.star_rounded,
        'color': Colors.teal,
      },
    ];

    return Column(
      children: activities.map((activity) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: AppColors.textLight.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      activity['color'].withOpacity(0.12),
                      activity['color'].withOpacity(0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  activity['icon'],
                  color: activity['color'],
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title'],
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activity['subtitle'],
                      style: TextStyle(
                        color: AppColors.textLight.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    activity['time'],
                    style: TextStyle(
                      color: AppColors.textLight.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.textLight.withOpacity(0.2),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    List<Color> gradientColors,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              icon,
              size: 60,
              color: gradientColors[0].withOpacity(0.03),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
